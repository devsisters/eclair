# frozen_string_literal: true
require "eclair/group_item"

module Eclair
  class GCEGroupItem < GroupItem
    def header
      all = @items.count

      <<-EOS
      Group #{label}
      #{all} instances Total
      EOS
    end
  end
end
