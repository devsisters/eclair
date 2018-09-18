# frozen_string_literal: true
require 'eclair/provider'
require 'eclair/providers/gce/gce_item'
require 'eclair/providers/gce/gce_group_item'
require 'oj'

module Eclair
  module GCEProvider
    extend Provider
    extend self

    def group_class
      GCEGroupItem
    end

    def item_class
      GCEItem
    end

    def prepare keyword
      instances = Oj.load(`gcloud compute instances list --format=json`)
      @items = instances.map{|i| GCEItem.new(i)}
    end

    def items
      @items
    end

    private
    def config
      Eclair.config
    end
  end
end
