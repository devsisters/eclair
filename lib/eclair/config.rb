module Eclair
  class Config
    RCFILE = ENV["ECLRC"] || "#{ENV['HOME']}/.eclrc"
    include Curses

    def initialize
      @aws_region = nil
      @columns = 4
      @group_by = lambda do |instance|
        if instance.security_groups.first
          instance.security_groups.first.group_name
        else
          "no_group"
        end
      end
      @ssh_username = lambda do |image|
        case image.name
        when /ubuntu/
          "ubuntu"
        else
          "ec2-user"
        end
      end
      @ssh_keys             = {}
      @ssh_hostname         = :public_ip_address
      @ssh_ports            = [22].freeze
      @ssh_options          = "-o ConnectTimeout=1 -o StrictHostKeyChecking=no".freeze
      @instance_color       = [COLOR_WHITE, -1].freeze
      @group_color          = [COLOR_WHITE, -1, A_BOLD].freeze
      @current_color        = [COLOR_BLACK, COLOR_CYAN].freeze
      @selected_color       = [COLOR_YELLOW, -1, A_BOLD].freeze
      @disabled_color       = [COLOR_BLACK, -1, A_BOLD].freeze
      @search_color         = [COLOR_BLACK, COLOR_YELLOW].freeze
      @help_color           = [COLOR_BLACK, COLOR_WHITE].freeze

      instance_variables.each do |var|
        Config.class_eval do
          attr_accessor var.to_s.tr("@","").to_sym
        end
      end

      unless File.exists? RCFILE
        template_path = File.join(File.dirname(__FILE__), "..", "..", "templates", "eclrc.template")
        FileUtils.cp(template_path, RCFILE)
        puts "#{RCFILE} successfully created. Edit it and run again!"
        exit
      end
    end
  end

  extend self
  
  def config
    unless @config
      @config = Config.new
      load Config::RCFILE
    end

    if @config.aws_region
      ::Aws.config.update(region: @config.aws_region)
    end

    @config
  end

  def configure
    yield config
  end
end
