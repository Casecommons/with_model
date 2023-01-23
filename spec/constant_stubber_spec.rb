# frozen_string_literal: true

require 'spec_helper'

module WithModel
  describe ConstantStubber do
    let(:stubber) { described_class.new('Foo') }

    it 'allows calling unstub_const multiple times' do
      expect do
        stubber.stub_const(1)
        stubber.unstub_const
        stubber.unstub_const
      end.not_to raise_error
    end

    it 'allows calling unstub_const without stub_const' do
      expect { stubber.unstub_const }.not_to raise_error
    end
  end
end
