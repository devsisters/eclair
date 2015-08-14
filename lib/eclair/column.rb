module Eclair
  class Column
    include CommonHelper
    array_accessor :expand
    attr_accessor :scroll
    attr_accessor :items

    def initialize index
      @index = index
      @items = []
      @scroll = 0
    end

    def << item
      @items << item
    end

    def x
      @index
    end

    def drawable? y
      (@scroll...Grid.maxy+@scroll).include? y
    end

    def rescroll y
      if y < @scroll
        @scroll = y
      elsif y >= Grid.maxy
        @scroll = y - Grid.maxy + 1
      end
      expand.each do |i|
        i.render
      end
    end

    def expand
      expanded = []
      if config.group_by
        @items.each do |item|
          expanded << item
          item.each do |instance|
            expanded << instance
          end
        end
        expanded
      else
        @items
      end
    end
  end
end
