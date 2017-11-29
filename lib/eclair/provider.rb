# frozen_string_literal: true
module Eclair
  module Provider
    extend self
    def require_prepare
      raise "Not prepared" unless @prepared
    end
  end
end
