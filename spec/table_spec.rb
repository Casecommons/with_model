# frozen_string_literal: true

require "spec_helper"

RSpec.describe WithModel::Table do
  let(:connection_owner) do
    klass = Class.new(ActiveRecord::Base)
    stub_const("TableSpecConnection", klass)
    klass.abstract_class = true
    klass.establish_connection(adapter: "sqlite3", database: ":memory:")
    klass
  end
  let(:connection) { connection_owner.connection }
  let(:table) { described_class.new(:temporary_records, connection:) }

  after { connection_owner.connection_pool.disconnect! }

  describe "#destroy" do
    it "does not raise after its connection reconnects before teardown" do
      table.create

      connection.disconnect!
      connection.reconnect!

      expect(connection.data_source_exists?(:temporary_records)).to be false
      expect { table.destroy }.not_to raise_error
    end

    it "drops an existing table" do
      table.create

      table.destroy

      expect(connection.data_source_exists?(:temporary_records)).to be false
    end
  end
end
