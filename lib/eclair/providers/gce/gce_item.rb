# frozen_string_literal: true
require 'eclair/item'
require 'eclair/providers/gce/gce_provider'
require 'time'

module Eclair
  class GCEItem < Item
    attr_reader :instance

    def initialize instance
      super()
      @instance = instance
    end

    def id
      @instance["id"]
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

    def header
      <<-EOS
      #{name} (#{public_ip_address} #{private_ip_address})
      launched at #{launch_time.to_time}
      #{description}
      EOS
    end

    def label
      " - #{name} [#{launched_at}]"
    end

    def description
      @instance["description"]
    end

    def name
      @instance["name"]
    end

    def public_ip_address
      @instance.dig("networkInterfaces", 0, "accessConfigs", 0, "natIP")
    end

    def private_ip_address
      @instance.dig("networkInterfaces", 0, "networkIP")
    end

    def command
      hosts = [public_ip_address, private_ip_address].compact
      ports = config.ssh_ports
      ssh_options = config.ssh_options
      ssh_command = config.ssh_command
      username = "ubuntu"
      format = config.exec_format

      joined_cmd = hosts.map do |host|
        ports.map do |port|
          {
            "{ssh_command}" => ssh_command,
            "{ssh_options}" => ssh_options,
            "{port}"        => port,
            "{username}"    => username,
            "{host}"        => host,
          }.reduce(format) { |cmd,pair| cmd.sub(pair[0],pair[1].to_s) }
        end
      end.join(" || ")
      # puts joined_cmd
      "echo Attaching to #{name} \\[#{name}\\] && #{joined_cmd}"
    end

    def connectable?
      status == "RUNNING"
    end

    private

    def status
      @instance["status"]
    end

    def launch_time
      Time.parse(@instance["creationTimestamp"])
    end

    def launched_at
      diff = Time.now - launch_time
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
  end
end
