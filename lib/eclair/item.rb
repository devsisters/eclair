# frozen_string_literal: true
require "eclair/config"

module Eclair
  class Item
    include ConfigHelper
    attr_accessor :selected, :visible

    def initialize
      @selected = false
      @visible = true
    end

    def toggle_select
      @selected = !@selected
    end

    def select state
      @selected = state
    end

    def id
      raise "Not Implemented"
    end

    def command
      raise "Not Implemented"
    end

    def header
      raise "Not Implemented"
    end

    def title
      raise "Not Implemented"
    end

    def search_key
      raise "Not Implemented"
    end
  end
end
