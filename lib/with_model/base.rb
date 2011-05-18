begin
  require 'mixico'
rescue LoadError
end

module WithModel
  class Base < ActiveRecord::Base
    self.abstract_class = true
    class << self
      def with_model?
        true
      end

      if defined?(Mixico)
        def include(*args)
          @modules_to_unmix ||= []
          args.each do |mod|
            unless @modules_to_unmix.include?(mod)
              @modules_to_unmix << mod
            end
          end
          super
        end

        def _with_model_deconstructor
          @modules_to_unmix.each do |mod|
            disable_mixin mod
          end if defined?(@modules_to_unmix)
        end
      end
    end
  end
end
