# frozen_string_literal: true
require "eclair/group_item"

module Eclair
  class EC2GroupItem < GroupItem
    def header
      running = @items.count{|i| i.instance.state[:code] == 16}
      all = @items.count

      <<-EOS
      Group #{label}
      #{running} Instances Running / #{all} Instances Total
      EOS
    end
  end
end
