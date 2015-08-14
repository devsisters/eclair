module Eclair
  module Grid
    include CommonHelper
    extend self

    HEADER_ROWS = 4
    SORT_FUNCTIONS = {
      "Name" => lambda {|i| [i.name.downcase, -i.launch_time.to_i]}, 
    }

    def maxy
      stdscr.maxy - HEADER_ROWS
    end
    
    def render_header
      if mode == :search
        if cursor
          header = ["Searching #{@search_str}", "Found #{cursor.name}", ""]
        else
          header = ["Searching #{@search_str}", "None Found", ""]
        end
      else
        header = cursor.header
      end

      header.each_with_index do |line,i|
        setpos(i,0)
        clrtoeol
        addstr(line)
      end
      render_help
    end

    def render_help
      setpos(3,0)
      clrtoeol

      helps = {
        "Enter" => "SSH",
        "Space" => "Select",
        "[a-z0-9]" =>  "Search",
        "?" => "Inspect",
        "!" => "Open Ruby REPL",
      }

      attron(Color.fetch(*config.help_color)) do
        addstr helps.map{ |key, action|   
          " #{key} => #{action}"
        }.join("    ").slice(0,stdscr.maxx).ljust(stdscr.maxx)
      end
    end

    def cell_width
      stdscr.maxx/column_count
    end

    def start
      assign
      move_cursor(x: 0, y: 0)
      render_all
    end

    def assign
      sort_function = lambda {|i| [i.name.downcase, -i.launch_time.to_i]}
      @group_map ||= {}
      if config.group_by
        Aws.instances.group_by(&config.group_by).each do |group, instances|
          if @group_map[group]
            group_cell  = @group_map[group]
          else
            col = columns[target_col]
            group_cell = Group.new(group, col)
            col << group_cell
            @group_map[group] = group_cell
          end
          instances.each do |i|
            unless group_cell.find{|j| j.instance_id == i.instance_id}
              obj = Instance.new(i.instance_id, col)
              group_cell << obj
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
      clear
      columns.each do |cols|
        cols.each do |c|
          c.render
        end
      end
      render_header
      refresh
    end

    def ssh
      targets = selected.select{|i| i.is_a?(Instance) && i.connectable?}
      return if targets.empty?
      close_screen

      cmd = ""
      if targets.count == 1
        target = targets.first
        cmd = target.ssh_cmd
      else
        cmds = []
        session_name = nil
        session_cmd = nil

        targets.each_with_index do |target, i|
          if i==0
            if ENV['TMUX']
              cmds << "tmux new-window -- '#{target.ssh_cmd}'"
            else
              session_name = "eclair#{Time.now.to_i}"
              session_cmd = "-t #{session_name}"
              cmds << "tmux new-session -d -s #{session_name} -- '#{target.ssh_cmd}'"
            end
          else
            cmds << "tmux split-window #{session_cmd} -- '#{target.ssh_cmd}'"
            cmds << "tmux select-layout #{session_cmd} tiled"
          end
        end
        cmds << "tmux set-window-option #{session_cmd} synchronize-panes on" 
        cmds << "tmux attach #{session_cmd}" unless ENV['TMUX']
        cmd = cmds.join(" && ")
      end
      system cmd
      exit
    end

    def column_count
      columns.count{|col| !col.empty?}
    end

    def columns
      @columns ||= config.columns.times.map{|idx| Column.new(idx)}.to_a
    end

    def rows
      columns.map(&:count).max
    end

    def target_col
      counts = columns.map(&:count)
      counts.index(counts.min)
    end

    def selected
      @selected ||= []
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
        KEY_UP => [0,-1],
        "k" => [0,-1],
        KEY_DOWN => [0,1],
        "j" => [0,1],
        KEY_LEFT => [-1,0],
        "h" => [-1,0],
        KEY_RIGHT => [1,0],
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
      @x ||= -1
      @y ||= -1
      if @x >=0 && @y >= 0
        columns[@x][@y]
      else
        nil
      end
    end

    def query
      return nil if @search_str == ""
      result = columns.map(&:expand).flatten.grep(Instance).map(&:name).max_by{|name| name.score @search_str}
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
          target = col.find {|item| item.is_a?(Instance) && item.name == goto}
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
      render_all
      cursor.check_scroll
    end

    def cursor_inspect
      close_screen
      LessViewer.show cursor.info
      render_all
    end

    def debug
      trap("INT") { raise Interrupt }
      close_screen
      binding.pry      
      render_all
      trap("INT") { exit }
    end

    def next_sort_function
      @sort_function_idx ||= -1
      @sort_function_idx = (@sort_function_idx + 1) % SORT_FUNCTIONS.count
      SORT_FUNCTIONS.values[@sort_function_idx]
    end

    def sorted_by
      SORT_FUNCTIONS.keys[@sort_function_idx]
    end

    def change_sort
      stored_cursor = cursor
      sort_function = next_sort_function
      columns.each do |column| 
        column.groups.each do |group|
          group.items.sort_by!(&sort_function)
        end
      end
      @x, @y = stored_cursor.x, stored_cursor.y
      render_all
    end

    def reload
      clear
      addstr("reloading")
      refresh
      Aws.reload_instances
      assign
      render_all
    end
  end
end
