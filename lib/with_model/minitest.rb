# frozen_string_literal: true

require "minitest"
require "with_model"

WithModel.runner = :minitest
Minitest::Test.extend WithModel
