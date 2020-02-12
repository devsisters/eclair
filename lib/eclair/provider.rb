# frozen_string_literal: true
require "eclair/config"

module Eclair
  module Provider
    include ConfigHelper

    extend self
    attr_accessor :items

    def filter_items search_buffer
      @items.select{ |item| item&.search_key&.include?(search_buffer.downcase) || item.selected }
    end

    def require_prepare
      raise "Not prepared" unless @prepared
    end
  end
end
