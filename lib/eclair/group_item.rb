# frozen_string_literal: true
module Eclair
  class GroupItem < Item
    attr_reader :label

    def initialize label, items
      @label = label
      @items = items
    end

    def toggle_select
      if @items.all?(&:selected)
        @items.each{|i| i.selected = false}
      else
        @items.each{|i| i.selected = true}
      end
    end

    def length
      @items.length
    end

    def color
      [Curses::COLOR_WHITE, -1, Curses::A_BOLD]
    end
  end
end
