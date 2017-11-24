require "eclair/providers/ec2"
require "eclair/group_item"
require "eclair/color"

module Eclair
  class Grid
    def initialize provider
      @provider = provider
      @item_class = @provider.item_class
      
      @grid = config.columns.times.map{[]}
      @scroll = config.columns.times.map{0}
      @header_rows = 4
      @cursor = [0,0]
      @cell_width = Curses.stdscr.maxx/config.columns
      @maxy = Curses.stdscr.maxy - @header_rows
      @mode = :nav

      @provider.prepare
      assign
      at(*@cursor).toggle_select
      draw_all
    end    

    def move key
      prev = @cursor.dup
      x,y = @cursor
      mx,my = {
        Curses::KEY_UP => [0,-1],
        Curses::KEY_DOWN => [0,1],
        Curses::KEY_LEFT => [-1,0],
        Curses::KEY_RIGHT => [1,0],
      }[key]

      newx = (x + mx) % @grid.length
      newy = (y + my - @scroll[x] + @scroll[newx])
      if my != 0
        newy %= @grid[newx].length
      end
      if newy >= @grid[newx].length
        newy = @grid[newx].length-1
      end

      @cursor = [newx, newy]

      prev_item = at(*prev)
      curr_item = at(*@cursor)
      rescroll(*@cursor)
      if @mode == :nav
        prev_item.toggle_select
        curr_item.toggle_select
      end
      draw(*prev)
      draw(*@cursor)
      update_header(curr_item.header)
    end

    def space
      if @mode == :nav
        @mode = :sel
        at(*@cursor).toggle_select
      end
      at(*@cursor).toggle_select
      if @mode == :sel && @provider.items.all?{|i| !i.selected}
        @mode = :nav
        at(*@cursor).toggle_select
      end
      draw(*@cursor)
    end

    def action
      targets = @provider.items.select{|i| i.selected}
      return if targets.length == 0
      
      Curses.close_screen

      if targets.length == 1
        cmd = targets.first.command
      else
        cmds = []
        target_cmd = ""

        targets.each_with_index do |target, i|
          if i == 0
            if ENV['TMUX'] # Eclair called inside of tmux
              # Create new session and save window id
              window_name = `tmux new-window -P -- '#{target.command}'`.strip
              target_cmd = "-t #{window_name}"
            else # Eclair called from outside of tmux
              # Create new session and save session
              session_name = "eclair#{Time.now.to_i}"
              target_cmd = "-t #{session_name}"
              `tmux new-session -d -s #{session_name} -- '#{target.command}'`
            end
          else # Split layout and
            cmds << "split-window #{target_cmd} -- '#{target.command}'"
            cmds << "select-layout #{target_cmd} tiled"
          end
        end
        cmds << "set-window-option #{target_cmd} synchronize-panes on"
        cmds << "attach #{target_cmd}" unless ENV['TMUX']
        cmd = "tmux #{cmds.join(" \\; ")}"
      end
      system(cmd)
      exit
    end

    def resize
      @scroll.fill(0)
      @cell_width = Curses.stdscr.maxx/config.columns
      @maxy = Curses.stdscr.maxy - @header_rows
      rescroll(*@cursor)
      draw_all
    end

    private

    def update_header str, pos = 0
      str.split("\n").map(&:strip).each_with_index do |line, i|
        Curses.setpos(i + pos,0)
        Curses.clrtoeol
        Curses.addstr(line)
      end
    end
    
    def rescroll x, y
      unless (@scroll[x]...@maxy+@scroll[x]).include? y
        if y < @scroll[x]
          @scroll[x] = y
        elsif y >= @maxy
          @scroll[x] = y - @maxy + 1
        end
        (@scroll[x]...@maxy+@scroll[x]).each do |ty|
          draw_item(x, ty)
        end
      end
    end
      
    def at x, y
      @grid[x][y]
    end

    def make_label target
      ind = (@mode == :sel && target.selected) ? "*" : " "
      label = "#{target.label} #{ind}"
      label.slice(0, @cell_width).ljust(@cell_width)
    end

    def draw_all
      @grid.each_with_index do |column, x|
        column.each_with_index do |_, y|
          draw_item(x,y)
        end
      end
      update_header(at(*@cursor).header)
    end
    
    def color x, y
      if @cursor == [x,y] 
        Color.fetch(Curses::COLOR_BLACK, Curses::COLOR_CYAN)
      else
        Color.fetch(*@grid[x][y].color)
      end
    end

    def draw_item x, y
      target = @grid[x][y]
      
      drawy = y - @scroll[x]
      if drawy < 0 || drawy + @header_rows >= Curses.stdscr.maxy
        return
      end
      cell_color = color(x,y)
      Curses.setpos(drawy + @header_rows, x * @cell_width)
      Curses.attron(cell_color) do
        Curses.addstr make_label(target)
      end
      Curses.refresh
    end

    def draw x, y
      target = @grid[x][y]
      draw_item(x, y)
      if target.is_a?(GroupItem)
        (y+1).upto(y+target.length).each do |ny|
          draw_item(x, ny)
        end
      end
    end

    def assign
      @groups = @provider.items.group_by(&config.group_by)
      @groups.each do |name, items|
        group_name = "#{name} (#{items.length})"
        target = @grid.min_by(&:length)
        target << @provider.group_class.new(group_name, items)
        items.each do |item|
          target << item
        end
      end
    end

    def config
      Eclair.config
    end
  end
end
