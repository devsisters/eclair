module Eclair
  module Console
    include CommonHelper
    extend self

    def parse_options
      options = {}
      OptionParser.new do |opts|
        opts.banner = "Usage: ecl [options]"
        opts.on("-c", "--config FILE", "Path to config file") do |path|
          options[:config] = path
        end
      end.parse!
      options
    end

    def init
      Eclair.init_config(parse_options)
      ENV['ESCDELAY'] = "0"
      init_screen
      stdscr.keypad = true
      start_color
      use_default_colors
      crmode
      noecho
      curs_set(0)
      Grid.start
      trap("INT") { exit }
      loop do
        case k = stdscr.getch
        when KEY_RESIZE
          Grid.resize
        when KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN
          Grid.move k
        when " "
          if Grid.mode == :search
            Grid.end_search
          end
          Grid.select
        when 10
          case Grid.mode
          when :search
            Grid.end_search
          else
            Grid.ssh
          end
        when 27
          if Grid.mode == :search
            Grid.cancel_search
          end
        when ?!
          Grid.debug
        when ??
          Grid.cursor_inspect
        when KEY_BACKSPACE, 127
          Grid.search(nil)
        when String
          Grid.search(k)
        else
          # Aws.reload_instances
          # Grid.render_all
        end
      end
    end
  end
end

