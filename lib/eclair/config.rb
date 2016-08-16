module Eclair
  class Config
    include Curses
    KEYS_DIR = "#{ENV['HOME']}/.ecl/keys"
    CACHE_DIR = "#{ENV['HOME']}/.ecl/.cache"

    def initialize opts
      @config_file = opts[:config] || ENV["ECLRC"] || "#{ENV['HOME']}/.ecl/config.rb"
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
      @ssh_command          = "ssh"
      @ssh_keys             = {}
      @ssh_ports            = [22].freeze
      @ssh_options          = "-o ConnectTimeout=1 -o StrictHostKeyChecking=no".freeze
      @instance_color       = [COLOR_WHITE, -1].freeze
      @group_color          = [COLOR_WHITE, -1, A_BOLD].freeze
      @current_color        = [COLOR_BLACK, COLOR_CYAN].freeze
      @selected_color       = [COLOR_YELLOW, -1, A_BOLD].freeze
      @disabled_color       = [COLOR_BLACK, -1, A_BOLD].freeze
      @search_color         = [COLOR_BLACK, COLOR_YELLOW].freeze
      @help_color           = [COLOR_BLACK, COLOR_WHITE].freeze
      @dir_keys             = {}

      instance_variables.each do |var|
        Config.class_eval do
          attr_accessor var.to_s.tr("@","").to_sym
        end
      end

      # Migrate old ~/.eclrc to ~/.ecl/config.rb
      old_conf  = "#{ENV['HOME']}/.eclrc"
      new_dir = "#{ENV['HOME']}/.ecl"
      new_conf  = "#{ENV['HOME']}/.ecl/config.rb"

      if !File.exists?(new_conf) && File.exists?(old_conf)
        FileUtils.mkdir_p new_dir
        FileUtils.mv old_conf, new_conf
        puts "#{old_conf} migrated to #{new_conf}"
        puts "Please re-run eclair"
        exit
      end

      unless File.exists? @config_file
        template_path = File.join(File.dirname(__FILE__), "..", "..", "templates", "eclrc.template")
        FileUtils.mkdir_p(File.dirname(@config_file))
        FileUtils.cp(template_path, @config_file)
        puts "#{@config_file} successfully created. Edit it and run again!"
        exit
      end

      key_path = "#{new_dir}/keys"
      FileUtils.mkdir_p key_path unless Dir.exists? key_path
      FileUtils.mkdir_p CACHE_DIR unless Dir.exists? CACHE_DIR
    end

    def after_load
      dir_keys = {}

      Dir["#{KEYS_DIR}/*"].each do |key|
        if File.file? key
          dir_keys[File.basename(key, ".*")] = key
        end
      end
      @ssh_keys.merge!(dir_keys)
    end
  end

  extend self

  def init_config opts
    @config = Config.new(opts)
    load @config.config_file
    @config.after_load
  end

  
  def config
    if @config.aws_region
      ::Aws.config.update(region: @config.aws_region)
    end

    @config
  end

  def configure
    yield config
  end
end
