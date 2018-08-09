# frozen_string_literal: true
require 'eclair/provider'
require 'eclair/providers/k8s/k8s_item'
require 'eclair/providers/k8s/k8s_group_item'
require 'oj'

module Eclair
  module K8sProvider
    extend Provider
    extend self

    def group_class
      K8sGroupItem
    end

    def item_class
      K8sItem
    end

    def prepare keyword
      pods = Oj.load(`kubectl get pods #{config.get_pods_option} -o json`)["items"].select{|i| i["metadata"]["name"].include? keyword or i["metadata"]["namespace"].include? keyword}
      @items = pods.map{|i| K8sItem.new(i)}
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
