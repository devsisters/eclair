module Eclair
  module Grid
    include CommonHelper
    extend self

    SORT_FUNCTIONS = {
      "Name" => lambda {|i| [i.name.downcase, -i.launch_time.to_i]}, 
    }

    HEADER_ROWS = 4

    def header_rows
      4
    end

    def maxy
      Curses.stdscr.maxy - header_rows
    end

    def update_header str, pos = 0
      str.split("\n").map(&:strip).each_with_index do |line, i|
        Curses.setpos(i + pos,0)
        Curses.clrtoeol
        Curses.addstr(line)
      end
    end
    
    def render_header
      if mode == :search
        if cursor
          update_header("Searching #{@search_str}\nFound #{cursor.name}")
        else
          update_header("Searching #{@search_str}\nNone Found")
        end
      else
        update_header(cursor.header)
      end
      render_help
    end

    def render_help
      Curses.setpos(3,0)
      Curses.clrtoeol

      helps = {
        "Enter" => "SSH",
        "Space" => "Select",
        "[a-z0-9]" =>  "Search",
        "?" => "Inspect",
        "!" => "Open Ruby REPL",
      }

      Curses.attron(Color.fetch(*config.help_color)) do
        Curses.addstr helps.map{ |key, action|   
          " #{key} => #{action}"
        }.join("    ").slice(0,Curses.stdscr.maxx).ljust(Curses.stdscr.maxx)
      end
    end

    def cell_width
      Curses.stdscr.maxx/column_count
    end

    def start
      assign
      move_cursor(x: 0, y: 0)
      render_all
    end

    def reload
      old_id = cursor.id
      assign
      x, y = find_cursor_by_id(old_id)
      if x && y
        move_cursor(x: x, y: y)
      else
        move_cursor(x: 0, y: 0)
      end
      render_all
    end

    def assign
      sort_function = lambda {|i| [i.name.downcase, -i.launch_time.to_i]}
      @columns = config.columns.times.map{|idx| Column.new(idx)}.to_a
      @selected = []
      @x = -1
      @y = -1
      group_map = {}
      if config.group_by
        Aws.instances.group_by(&config.group_by).each do |group, instances|
          group_cell = nil
          if group_map[group]
            group_cell  = group_map[group]
          else
            col = columns[target_col]
            group_cell = Group.new(group, col)
            col << group_cell
            group_map[group] = group_cell
          end
          instances.each do |i|
            unless group_cell.find{|j| j.respond_to?(:instance_id) && j.instance_id == i.instance_id}
              obj = Instance.new(i.instance_id, col)
              group_cell << obj
            end
          end
          group_cell.items.each do |x|
            if x.object == nil
              Curses.close_screen
              binding.pry
            end
          end

          group_cell.items.sort_by!(&sort_function)
        end
      else
        col_limit = (Aws.instances.count - 1) / config.columns + 1
        iter = Aws.instances.map{|i| Instance.new(i.instance_id)}.sort_by(&sort_function).each
        columns.each do |col|
          col_limit.times do 
            begin
              i = iter.next
              i.column = col
              col << i
            rescue StopIteration
              break
            end
          end
        end
      end
    end

    def render_all
      Curses.clear
      columns.each do |cols|
        cols.each do |c|
          c.render
        end
      end
      render_header
      Curses.refresh
    end

    def ssh
      targets = selected.select{|i| i.is_a?(Instance) && i.connectable?}
      return if targets.empty?
      Curses.close_screen

      cmd = ""
      if targets.count == 1
        target = targets.first
        cmd = target.ssh_cmd
      else
        cmds = []
        target_cmd = ""

        targets.each_with_index do |target, i|
          if i == 0 
            if ENV['TMUX'] # Eclair called inside of tmux
              # Create new session and save window id
              window_name = `tmux new-window -P -- '#{target.ssh_cmd}'`.strip
              target_cmd = "-t #{window_name}"
            else # Eclair called from outside of tmux
              # Create new session and save session
              session_name = "eclair#{Time.now.to_i}"
              target_cmd = "-t #{session_name}"
              `tmux new-session -d -s #{session_name} -- '#{target.ssh_cmd}'`
            end
          else # Split layout and 
            cmds << "split-window #{target_cmd} -- '#{target.ssh_cmd}'"
            cmds << "select-layout #{target_cmd} tiled"
          end
        end
        cmds << "set-window-option #{target_cmd} synchronize-panes on" 
        cmds << "attach #{target_cmd}" unless ENV['TMUX']
        cmd = "tmux #{cmds.join(" \\; ")}"
      end
      system cmd
      exit
    end

    def column_count
      columns.count{|col| !col.empty?}
    end

    def columns
      @columns
    end

    def rows
      columns.map(&:count).max
    end

    def target_col
      counts = columns.map(&:count)
      counts.index(counts.min)
    end

    def selected
      @selected
    end

    def mode
      @mode ||= :navi
    end

    def select
      end_search if mode == :search
      if mode == :navi
          @mode = :select
        cursor.toggle_select
      end
      cursor.toggle_select
      if selected.empty?
        @mode = :navi
        cursor.toggle_select
      end
    end

    def move key
      end_search if mode == :search
      mx,my = {
        Curses::KEY_UP => [0,-1],
        "k" => [0,-1],
        Curses::KEY_DOWN => [0,1],
        "j" => [0,1],
        Curses::KEY_LEFT => [-1,0],
        "h" => [-1,0],
        Curses::KEY_RIGHT => [1,0],
        "l" => [1,0],
      }[key]

      newx = (@x + mx) % column_count
      newy = (@y + my - columns[@x].scroll + columns[newx].scroll)
      if my != 0
        newy %= columns[newx].count 
      end
      if newy >= columns[newx].count
        newy = columns[newx].count-1
      end

      move_cursor(x: newx, y: newy)
    end

    def cursor
      if @x >=0 && @y >= 0
        columns[@x][@y]
      else
        nil
      end
    end

    def find_cursor_by_id id
      columns.each_with_index do |col, x|
        col.each_with_index do |v, y|
          if id == v.id
            return [x,y]
          end
        end
      end
      nil
    end


    def query
      return nil if @search_str == ""

      result = columns
        .map(&:expand)
        .flatten
        .grep(Instance)
        .select{|i| i.connectable?}
        .map(&:name)
        .max_by{|name| name.score @search_str}
      return nil if result.score(@search_str) == 0.0
      result
    end

    def start_search
      @rollback_cursor = [@x, @y]
      @rollback_mode = @mode
      @search_str = ""
    end

    def end_search
      if cursor
        move_cursor(mode: @rollback_mode)
        @mode = @rollback_mode
      else
        cancel_search
      end
    end

    def cancel_search
      x,y = @rollback_cursor
      move_cursor(x: x, y: y, mode: @rollback_mode)
    end

    def move_cursor **options, &block
      if cursor
        cursor.toggle_select if mode == :navi
        cursor.decurrent
      end

      new_mode = options.delete(:mode)
      if new_mode && mode != new_mode
        case new_mode
        when :search
          start_search
        end
        @mode = new_mode
      end

      if block
        @x, @y = block.call
      else
        @x = options.delete(:x) || @x
        @y = options.delete(:y) || @y
      end

      if cursor
        cursor.toggle_select if mode == :navi
        cursor.current
      end
    end

    def search key
      @search_str ||= ""
  
      move_cursor(mode: :search) do 
        if key
          @search_str = @search_str+key
        else
          @search_str.chop!
        end

        goto = query

        result = nil
        columns.each do |col|
          target = col.find {|item| item.is_a?(Instance) && item.connectable? && item.name == goto}
          if target
            result = [target.x, target.y]
            break
          end
        end

        result || [-1,-1]
      end
      
      render_header 
    end

    def resize
      columns.each{|col| col.scroll = 0}
      Curses.render_all
      cursor.check_scroll
    end

    def cursor_inspect
      Curses.close_screen
      LessViewer.show cursor.info
      render_all
    end

    def debug
      trap("INT") { raise Interrupt }
      Curses.close_screen
      binding.pry      
      render_all
      trap("INT") { exit }
    end

  end
end
