# frozen_string_literal: true
require "eclair/config"

module Eclair
  module Plugin
    extend self

    def items
      raise "Not Implemented"
    end

    def groups
      raise "Not Implemented"
    end

    def search
      raise "Not Implemented"
    end

    def config
      Eclair.config
    end
  end

  class Item
    include ConfigHelper
    attr_accessor :selected

    def initialize
      @selected = false
    end

    def toggle_select
      @selected = !@selected
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
  end
end
