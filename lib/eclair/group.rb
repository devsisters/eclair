 module Eclair
  class Group < Cell
    array_accessor :items

    def initialize group_name, column = nil
      super
      @group_name = group_name
      @items = []
      @column = column
    end

    def << instance
      @items << instance
    end

    def x
      column.x
    end

    def y
      column.index(self)
    end

    def color
      super(*config.group_color)
    end

    def format
      " #{@group_name} (#{count(&:connectable?)}) #{select_indicator}"
    end

    def header
      ["Group #{@group_name}",
      "#{count} Instances Total",
      "#{count(&:running?)} Instances Running"]
    end

    def items
      @items
    end

    def name
      @group_name
    end

    def object
      @group_name
    end

    def info
      @items.map(&:info)
    end
  end
end

