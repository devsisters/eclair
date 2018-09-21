# frozen_string_literal: true
module Eclair
  class GroupItem < Item
    attr_reader :label
    attr_accessor :visible

    def initialize label, items
      @label = label
      @items = items
      @visible = true
    end

    def toggle_select
      if @items.all?(&:selected)
        @items.each{|i| i.select(false) }
      else
        @items.each{|i| i.select(true) }
      end
    end

    def select state
      @items.each{|i| i.select(state) }
    end

    def length
      @items.length
    end

    def color
      [Curses::COLOR_WHITE, -1, Curses::A_BOLD]
    end
  end
end
