# frozen_string_literal: true
require "aws-sdk-ec2"
require "eclair/provider"
require "eclair/providers/ec2/ec2_item"
require "eclair/providers/ec2/ec2_group_item"

module Eclair
  module EC2Provider
    extend Provider
    extend self

    def group_class
      EC2GroupItem
    end

    def item_class
      EC2Item
    end

    def prepare keyword
      Thread.abort_on_exception = true

      @instances ||= fetch_instances keyword

      image_ids = @instances.map(&:image_id).uniq
      @image_thread = Thread.new do
        @images = fetch_images(image_ids)
        @id_to_image = @images.map{|i| [i.image_id, i]}.to_h
      end

      @sg_thread = Thread.new do
        @security_groups = fetch_security_groups
        @id_to_sg = @security_groups.map{|i| [i.group_id, i]}.to_h
      end

      @vpc_thread = Thread.new do
        @vpcs = fetch_vpcs
        @id_to_vpc = @vpcs.map{|i| [i.vpc_id, i]}.to_h
      end

      @items = @instances.map{|i| EC2Item.new(i)}

      @prepared = true
    end

    def items
      @items
    end

    def image_loaded?
      !@sg_thread.alive?
    end

    def images
      @image_thread.join if @image_thread.alive?
      @images
    end

    def find_image_by_id id
      @image_thread.join if @image_thread.alive?
      @id_to_image[id]
    end

    def security_group_loaded?
      !@sg_thread.alive?
    end

    def security_groups
      @sg_thread.join if @sg_thread.alive?
      @security_groups
    end

    def find_security_group_by_id id
      @sg_thread.join if @sg_thread.alive?
      @id_to_sg[id]
    end

    def vpc_loaded?
      !@vpc_thread.alive?
    end

    def vpcs
      @vpc_thread.join if @vpc_thread.alive?
      @vpcs
    end

    def find_vpc_by_id id
      @vpc_thread.join if @vpc_thread.alive?
      @id_to_vpc[id]
    end

    private

    def ec2_client
      @ec2_client ||= Aws::EC2::Client.new
    end

    def fetch_instances keyword
      filter = if keyword.empty? then {} else { filters: [{name: "tag:Name", values: ["*#{keyword}*"]}] } end

      ec2_client.describe_instances(filter).map{ |resp|
        resp.data.reservations.map do |rsv|
          rsv.instances
        end
      }.flatten
    end

    def fetch_security_groups
      ec2_client.describe_security_groups.map{ |resp|
        resp.security_groups
      }.flatten
    end

    def fetch_images image_ids
      ec2_client.describe_images(image_ids: image_ids).images.flatten
    end

    def fetch_vpcs
      ec2_client.describe_vpcs.map{|resp| resp.vpcs}.flatten
    end
  end
end
