require "eclair/group_item"

module Eclair
  class K8sGroupItem < GroupItem
    def header
      all = @items.count

      <<-EOS
      Group #{label}
      #{all} pods Total
      EOS
    end
  end
end

