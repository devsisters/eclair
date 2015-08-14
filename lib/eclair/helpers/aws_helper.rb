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
      fetch_all unless @instances
      @instances
    end

    def instance_map
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

    def reload_instances
      return if @reload_thread && @reload_thread.alive?

      if @reload_thread
        @instances = @r_instances
        @instance_map = @r_instances_map
        @images += @new_images
        @dns_records = @r_dns_records
        @security_groups = @r_security_groups
        Grid.assign
        @reload_thread = nil
      end

      return if @last_reloaded && Time.now - @last_reloaded < 5

      @reload_thread = Thread.new do 
        r_instances, r_instances_map = fetch_instances
        @new_instances = r_instances.map(&:instance_id) - @instances.map(&:instance_id)
        if new_instances.empty?
          @new_images = []
        else
          image_ids = @new_instances.map(&:image_id)
          [
            Thread.new do
              @new_images = fetch_images(image_ids)
            end,

            Thread.new do
              @r_security_groups = fetch_security_groups
            end
          ].each(&:join)
        end
        @last_reloaded = Time.now
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
      instance_map = {}

      instances = ec2.describe_instances.map{ |resp| 
        resp.data.reservations.map(&:instances)
      }.flatten

      instances.each do |i|
        instance_map[i.instance_id] = i
      end

      [instances, instance_map]
    end

    
    def fetch_all
      @instances, @instance_map = fetch_instances

      image_ids = @instances.map(&:image_id)

      if @threads
        @threads.each{ |t| t.kill }
      end

      Thread.abort_on_exception = true
      
      @threads = []

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
    
    def find_username image_id
      config.ssh_username.call(image_id, @images[image_id].name)
    end
  end
end
