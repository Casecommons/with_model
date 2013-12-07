require 'active_record'

module WithModel
  class Base < ActiveRecord::Base
    self.abstract_class = true

    def self.with_model?
      true
    end
  end
end
