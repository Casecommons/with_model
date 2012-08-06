module WithModel
  class Base < ActiveRecord::Base
    self.abstract_class = true
    class << self
      def with_model?
        true
      end
    end
  end
end
