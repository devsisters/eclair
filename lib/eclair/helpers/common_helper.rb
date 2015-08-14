module Eclair
  module CommonHelper
    include Curses

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def array_accessor name
        methods = [:[], :each, :count, :index, :each_with_index, :all?, :find, :empty?]
        methods.each do |method_name|
          define_method method_name do |*args, &blk|
            self.send(name).send(method_name, *args, &blk)
          end
        end 
      end
    end

    def config
      Eclair.config
    end
  end
end
