require "eclair/providers/ec2"
require "eclair/group_item"
require "eclair/color"

module Eclair
  class Grid
    def initialize provider
      @provider = provider
      @grid = config.columns.times.map{[]}
      @scroll = config.columns.times.map{0}
      @header_rows = 4
      @cursor = [0,0]
      @cell_width = Curses.stdscr.maxx/config.columns
      @maxy = Curses.stdscr.maxy - @header_rows

      provider.prepare
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
      prev_item.toggle_select
      curr_item.toggle_select
      draw(*prev)
      draw(*@cursor)
    end

    def action
      Curses.close_screen

      target = at(*@cursor)
      system(target.command)
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
      ind = " * "
      no_ind = " " * ind.length
      case target
      when GroupItem
        target.label.slice(0, @cell_width).ljust(@cell_width)
      when Item
        target.label.slice(0, @cell_width - ind.length).ljust(@cell_width - ind.length) + (target.selected ? ind : no_ind)
      end
    end

    def draw_all
      @grid.each_with_index do |column, x|
        column.each_with_index do |_, y|
          draw_item(x,y)
        end
      end
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
      @groups = provider.items.group_by(&config.group_by)
      @groups.each do |name, items|
        group_name = "#{name} (#{items.length})"
        target = @grid.min_by(&:length)
        target << GroupItem.new(group_name, items)
        items.each do |item|
          target << item
        end
      end
    end

    def provider
      Eclair::EC2Provider
    end

    def config
      Eclair.config
    end
  end
end
