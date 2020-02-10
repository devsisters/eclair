# frozen_string_literal: true
require 'shellwords'
require "aws-sdk-ec2"

require "eclair/item"
require "eclair/providers/ec2/ec2_provider"

module Eclair
  class EC2Item < Item
    attr_reader :instance

    def initialize instance
      super()
      @instance = instance
    end

    def id
      @instance.id
    end

    def color
      if @selected
        [Curses::COLOR_YELLOW, -1, Curses::A_BOLD]
      elsif !connectable?
        [Curses::COLOR_BLACK, -1, Curses::A_BOLD]
      else
        [Curses::COLOR_WHITE, -1]
      end
    end

    def command
      hosts = [@instance.public_ip_address, @instance.private_ip_address].compact
      ports = config.ssh_ports
      ssh_options = config.ssh_options
      ssh_command = config.ssh_command
      username = config.ssh_username.call(image)
      key_cmd = config.ssh_keys[@instance.key_name] ? "-i #{config.ssh_keys[@instance.key_name]}" : ""
      format = config.exec_format

      joined_cmd = hosts.map do |host|
        ports.map do |port|
          {
            "{ssh_command}" => ssh_command,
            "{ssh_options}" => ssh_options,
            "{port}"        => port,
            "{ssh_key}"     => key_cmd,
            "{username}"    => username,
            "{host}"        => host,
          }.reduce(format) { |cmd,pair| cmd.sub(pair[0],pair[1].to_s) }
        end
      end.join(" || ")
      # puts joined_cmd
      "echo Attaching to #{Shellwords.escape(name)} \\[#{@instance.instance_id}\\] && #{joined_cmd}"
    end

    def header
      <<-EOS
      #{name} (#{instance_id}) [#{state[:name]}]
      launched at #{launch_time.to_time}
      EOS
    end

    def image
      @image ||= provider.find_image_by_id(@instance.image_id)
    end

    def vpc
      @vpc ||= provider.find_vpc_by_id(@instance.vpc_id)
    end

    def header
      <<-EOS
      #{name} (#{@instance.instance_id}) [#{@instance.state[:name]}] #{@instance.private_ip_address}
      launched at #{@instance.launch_time.to_time}
      EOS
    end

    def label
      " - #{name} [#{launched_at}]"
    end

    def info
      {
        instance: @instance,
        image: provider.image_loaded? ? image : "ami info not loaded yet",
        security_groups: provider.security_group_loaded? ? security_groups : "sg info not loaded yet",
      }
    end

    def connectable?
      ![32, 48, 80].include?(@instance.state[:code])
    end

    def name
      return @name if @name
      begin
        tag = @instance.tags.find{|t| t.key == "Name"}
        @name = tag ? tag.value : "noname"
      rescue
        @name = "terminated"
      end
    end

    def security_groups
      @security_groups ||= @instance.security_groups.map{|sg| provider.find_security_group_by_id(sg.group_id)}
    end

    def search_key
      name.downcase
    end

    private

    def launched_at
      diff = Time.now - @instance.launch_time
      {
        "year" => 31557600,
        "month" => 2592000,
        "day" => 86400,
        "hour" => 3600,
        "minute" => 60,
        "second" => 1
      }.each do |unit,v|
        if diff >= v
          value = (diff/v).to_i
          return "#{value} #{unit}#{value > 1 ? "s" : ""}"
        end
      end
      "now"
    end

    def provider
      EC2Provider
    end
  end
end
