# frozen_string_literal: true
require 'curses'

module Eclair
  module Color
    extend self

    def storage
      @storage ||= {}
    end

    def fetch fg, bg, options = 0
      @idx ||= 1
      unless storage[[fg,bg]]
        Curses.init_pair(@idx, fg, bg)
        storage[[fg,bg]] = @idx
        @idx += 1
      end
      Curses.color_pair(storage[[fg,bg]]) | options
    end
  end
end
