# frozen_string_literal: true

require "rspec/core"
require "with_model"

WithModel.runner = :rspec

RSpec.configure do |config|
  config.extend WithModel
end
