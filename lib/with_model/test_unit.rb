# frozen_string_literal: true

require "test/unit"
require "with_model"

WithModel.runner = :test_unit
Test::Unit::TestCase.extend WithModel
