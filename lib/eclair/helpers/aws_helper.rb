module Eclair
  module Aws
    extend self
    def ec2
      @ec2 ||= ::Aws::EC2::Client.new
    end

    def route53
      @route53 ||= ::Aws::Route53::Client.new
    end

    def instances
      @instances ||= fetch_instances
    end

    def vpcs
      @vpcs ||= fetch_vpcs
    end

    def instance_map
      return @instance_map if @instance_map
      generate_instance_map
    end

    def generate_instance_map
      @instance_map = {}
      instances.each do |i|
        @instance_map[i.instance_id] = i
      end
      @instance_map
    end

    def images **options
      if options.delete :force
        @images_thread.join
      end
      @images || []
    end

    def images?
      !@images_thread.alive?
    end

    def dns_records **options
      if options.delete :force
        @route53_thread.join
      end
      @dns_records || []
    end

    def dns_records?
      !@route53_thread.alive?
    end

    def security_groups **options
      if options.delete :force
        @security_groups_thread.join
      end
      @security_groups || []
    end

    def security_groups?
      !@security_groups_thread.alive?
    end

    def load_instances_from_cache
      # @instances = Cache.get(:instances)
      generate_instance_map
      @instances
    end

    def fetch_all
      load_instances_from_cache

      if @threads
        @threads.each{ |t| t.kill }
      end

      Thread.abort_on_exception = true
      
      @threads = []
      
      # if @instances
      #   pid = fork do
      #     fetch_instances
      #   end
      #   Process.detach pid if pid
      # else

      @new_instances = fetch_instances
      update_instances
      # end

      image_ids = @instances.map(&:image_id)

      @threads << @images_thread = Thread.new do
        @images = fetch_images(image_ids)
      end

      @threads << @route53_thread = Thread.new do
        @dns_records = fetch_dns_records
      end

      @threads << @security_groups_thread = Thread.new do
        @security_groups = fetch_security_groups
      end
    end

    private

    def fetch_images image_ids
      ec2.describe_images(image_ids: image_ids).images.flatten
    end

    def fetch_dns_records
      hosted_zone_ids = route53.list_hosted_zones.hosted_zones.map(&:id)
      hosted_zone_ids.map { |hosted_zone_id|
        route53.list_resource_record_sets(hosted_zone_id: hosted_zone_id).map { |resp|
          resp.resource_record_sets
        }
      }.flatten
    end

    def fetch_security_groups
      ec2.describe_security_groups.map{ |resp|
        resp.security_groups
      }.flatten
    end

    def fetch_instances
      instances = ec2.describe_instances.map{ |resp| 
        resp.data.reservations.map(&:instances)
      }.flatten

      # Cache.update :instances, instances
      instances
    end

    def fetch_vpcs
      ec2.describe_vpcs.map{|resp| resp.vpcs}.flatten
    end
    
    def update_instances
      @instances = @new_instances
    end
    
    def find_username image_id
      config.ssh_username.call(image_id, @images[image_id].name)
    end
  end
end
