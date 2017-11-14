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
      Aws.fetch_all
      ENV['ESCDELAY'] = "0"
      Curses.init_screen
      Curses.stdscr.timeout = 100
      Curses.stdscr.keypad = true
      Curses.start_color
      Curses.use_default_colors
      Curses.crmode
      Curses.noecho
      Curses.curs_set(0)
      Grid.start
      trap("INT") { exit }
      loaded = false
      cnt = 0
      loop do
        case k = Curses.stdscr.getch
        when Curses::KEY_RESIZE
          Grid.resize
        when Curses::KEY_LEFT, Curses::KEY_RIGHT, Curses::KEY_UP, Curses::KEY_DOWN
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
        when Curses::KEY_BACKSPACE, 127
          Grid.search(nil)
        when String
          Grid.search(k)
        end
        cnt += 1

      end
    end
  end
end
