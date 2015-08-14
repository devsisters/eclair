module Eclair
  class Cell
    include CommonHelper
    
    attr_accessor :column
    attr_accessor :selected

    def initialize *args
      @current = false
      @selected = false
    end

    def color(*color)
      if @current
        color = config.current_color
      elsif @selected
        color = config.selected_color
      end

      if Grid.mode == :search && @current
        color = config.search_color
      end

      Color.fetch(*color)
    end

    def render options = 0
      drawy = y - column.scroll
      return if drawy < 0 || drawy >= Grid.maxy
      w = Grid.cell_width
      setpos(drawy + Grid::HEADER_ROWS, x * w)
      str = format.slice(0, w).ljust(w)
      attron(color) do
        addstr(str)
      end
      Grid.render_header
    end

    def deselect
      @selected = false
      Grid.selected.delete self
      redraw
    end

    def select
      @selected = true
      Grid.selected << self
      redraw
    end
 
    def toggle_select
      if respond_to? :each
        if all?(&:selected)
          each(&:deselect)
        else
          each(&:select)
        end
      else
        if @selected
          deselect
        else
          select
        end
      end
    end

    def current
      @current = true
      check_scroll
      redraw
    end

    def check_scroll
      unless column.drawable? y
        column.rescroll y
      end
    end

    def decurrent
      @current = false
      redraw
    end

    def redraw
      render
      refresh
    end

    def select_indicator
      if @selected
        if Grid.mode == :select
          "*"
        end
      end
    end

    def method_missing name, *args, &blk
      object.send(name)
    end
  end  
end
