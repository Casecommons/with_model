# frozen_string_literal: true

require 'spec_helper'

module WithModel
  describe ConstantStubber do
    it 'allows calling unstub_const multiple times' do
      stubber = described_class.new('Foo')
      stubber.stub_const(1)
      stubber.unstub_const
      stubber.unstub_const
    end

    it 'allows calling unstub_const without stub_const' do
      stubber = described_class.new('Foo')
      stubber.unstub_const
    end
  end
end
