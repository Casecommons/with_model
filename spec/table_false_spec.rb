# frozen_string_literal: true

require "spec_helper"

# Wrapping the file in a module keeps these parents out of the global namespace
# while still defining them at file scope, where Standard's
# Lint/ConstantDefinitionInBlock does not fire. Blocks resolve constants from
# where they are written, so the examples below name them without qualifying.
# Their tables are supplied per-example by `with_table`, so no schema persists
# between spec files.
module TableFalseSpec
  # The ordinary shape single table inheritance expects.
  class HasTypeColumn < ActiveRecord::Base
  end

  class HasCustomInheritanceColumn < ActiveRecord::Base
    self.inheritance_column = "kind"
  end

  # Both a custom inheritance column and a `type` column, so a test can tell
  # which one with_model actually reads.
  class HasCustomInheritanceColumnAndTypeColumn < ActiveRecord::Base
    self.inheritance_column = "kind"
  end

  class HasDefaultScope < ActiveRecord::Base
    default_scope { where(archived: false) }
  end

  class HasNoTypeColumn < ActiveRecord::Base
  end

  class HasNilInheritanceColumn < ActiveRecord::Base
    self.inheritance_column = nil
  end

  class IsAbstract < ActiveRecord::Base
    self.abstract_class = true
  end

  # The shape a Rails app's ApplicationRecord takes: abstract, and inherited from
  # rather than ActiveRecord::Base directly.
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end

  # Its table is never created.
  class HasMissingTable < ApplicationRecord
  end

  # Its table is created partway through an example.
  class HasLateTable < ActiveRecord::Base
  end

  RSpec.describe "table(false)" do
    describe "with a concrete superclass" do
      with_table(HasTypeColumn.table_name) do |t|
        t.string :type
        t.string :name
      end

      before { HasTypeColumn.reset_column_information }

      with_model :Truck, superclass: HasTypeColumn do
        table(false)
        model do
          def honk = "beep"
        end
      end

      it "inherits the superclass table rather than creating its own" do
        expect(Truck.table_name).to eq HasTypeColumn.table_name
      end

      it "creates no table of its own" do
        expect(ActiveRecord::Base.connection.tables.grep(/with_model_truck/)).to be_empty
      end

      it "reports the superclass as the STI base class" do
        expect(Truck.base_class).to eq HasTypeColumn
      end

      it "still evaluates the model block" do
        expect(Truck.new.honk).to eq "beep"
      end

      it "writes its own name to the inheritance column" do
        Truck.create!(name: "big")
        expect(HasTypeColumn.first.type).to eq "Truck"
      end

      it "is found through the superclass as an instance of itself" do
        Truck.create!(name: "big")
        expect(HasTypeColumn.first).to be_a Truck
      end

      # Deliberately a second example asserting the same thing: a superclass
      # resolved once and cached on the Model instance would go stale here,
      # because the parent is the same class object but the child is rebuilt.
      it "works in a second example too" do
        Truck.create!(name: "also big")
        expect(HasTypeColumn.first).to be_a Truck
      end
    end

    describe "teardown" do
      with_table(HasTypeColumn.table_name) do |t|
        t.string :type
        t.string :name
      end

      before { HasTypeColumn.reset_column_information }

      def build(name, superclass:, &dsl)
        WithModel::Model.new(name, superclass: superclass).tap do |model|
          WithModel::Model::DSL.new(model).instance_eval(&dsl)
        end
      end

      it "deletes its own rows and leaves the superclass's rows alone" do
        model = build(:Truck, superclass: HasTypeColumn) { table(false) }
        model.create
        Truck.create!(name: "child row")
        HasTypeColumn.create!(name: "parent row")

        model.destroy

        expect(HasTypeColumn.where(type: "Truck").count).to eq 0
        expect(HasTypeColumn.where(type: nil).count).to eq 1
      end

      it "leaves the superclass queryable" do
        model = build(:Truck, superclass: HasTypeColumn) { table(false) }
        model.create
        Truck.create!(name: "child row")

        model.destroy

        expect { HasTypeColumn.first }.not_to raise_error
      end

      it "does not delete rows when create refused the superclass" do
        HasTypeColumn.create!(name: "parent row")
        model = build(:Truck, superclass: IsAbstract) { table(false) }

        expect { model.create }.to raise_error(WithModel::InvalidSuperclass)
        expect { model.destroy }.not_to raise_error

        expect(HasTypeColumn.count).to eq 1
      end
    end

    describe "with a superclass that has a default_scope" do
      with_table(HasDefaultScope.table_name) do |t|
        t.string :type
        t.boolean :archived, default: false
      end

      before { HasDefaultScope.reset_column_information }

      it "deletes rows the default scope would have hidden" do
        model = WithModel::Model.new(:ScopedChild, superclass: HasDefaultScope)
        WithModel::Model::DSL.new(model).table(false)
        model.create
        ScopedChild.create!(archived: false)
        ScopedChild.create!(archived: true)

        model.destroy

        expect(HasDefaultScope.unscoped.where(type: "ScopedChild").count).to eq 0
      end
    end

    describe "with a non-standard inheritance_column" do
      with_table(HasCustomInheritanceColumn.table_name) do |t|
        t.string :kind
        t.string :name
      end

      before { HasCustomInheritanceColumn.reset_column_information }

      with_model :KindedChild, superclass: HasCustomInheritanceColumn do
        table(false)
      end

      it "writes to the custom column" do
        KindedChild.create!(name: "x")
        expect(HasCustomInheritanceColumn.first.kind).to eq "KindedChild"
      end

      it "accepts a Symbol inheritance_column" do
        expect(HasCustomInheritanceColumn.inheritance_column).to eq "kind"
      end
    end

    # The anchor case: a validation or teardown that hard-codes "type" passes
    # every other example here and still scopes on the wrong column.
    describe "with both a type column and a custom inheritance_column" do
      with_table(HasCustomInheritanceColumnAndTypeColumn.table_name) do |t|
        t.string :kind
        t.string :type
        t.string :name
      end

      before { HasCustomInheritanceColumnAndTypeColumn.reset_column_information }

      with_model :KindedTypeChild, superclass: HasCustomInheritanceColumnAndTypeColumn do
        table(false)
      end

      it "writes the custom column and leaves type null" do
        KindedTypeChild.create!(name: "x")
        row = HasCustomInheritanceColumnAndTypeColumn.first
        expect(row.kind).to eq "KindedTypeChild"
        expect(row.type).to be_nil
      end
    end

    describe "with a with_model superclass" do
      with_model :Parent do
        table do |t|
          t.string :type
          t.string :name
        end
      end

      with_model :StringChild, superclass: "Parent" do
        table(false)
      end

      with_model :SymbolChild, superclass: :Parent do
        table(false)
      end

      with_model :CallableChild, superclass: -> { Parent } do
        table(false)
      end

      it "resolves a String superclass" do
        expect(StringChild.superclass).to eq Parent
        expect(StringChild.table_name).to eq Parent.table_name
      end

      # The same spelling with_model names its own models with.
      it "resolves a Symbol superclass" do
        expect(SymbolChild.superclass).to eq Parent
        expect(SymbolChild.table_name).to eq Parent.table_name
      end

      it "resolves a callable superclass" do
        expect(CallableChild.superclass).to eq Parent
      end

      it "round-trips through the parent" do
        StringChild.create!(name: "x")
        expect(Parent.first).to be_a StringChild
      end

      # Second example: the parent class object is rebuilt every example, so a
      # superclass memoized on the first resolution refers to a dead class here.
      it "resolves against the current parent in a later example" do
        expect(StringChild.superclass).to eq Parent
        expect(StringChild.superclass).to be Parent
      end
    end

    describe "namespaced constants" do
      with_table(HasTypeColumn.table_name) do |t|
        t.string :type
        t.string :name
      end

      before { HasTypeColumn.reset_column_information }

      # WithModel::ConstantStubber resolves a namespaced name with `const_get` and
      # stubs only the last segment, so the namespace has to exist already. This
      # file's own module supplies one.
      with_model "TableFalseSpec::Step", superclass: HasTypeColumn do
        table(false)
      end

      it "stores and round-trips the fully qualified name" do
        Step.create!(name: "x")
        expect(HasTypeColumn.first.type).to eq "TableFalseSpec::Step"
        expect(HasTypeColumn.first).to be_a Step
      end
    end

    # A missing table is a fact about the schema at that moment, not about the
    # model, so it is allowed: the table may arrive later in the example, or its
    # absence may be the very thing under test.
    describe "when the superclass's table does not exist" do
      with_model :Orphan, superclass: HasMissingTable do
        table(false)
      end

      it "still defines the model, which inherits the missing table's name" do
        # Not `new`: building an instance reads column information, which is
        # itself a use of the absent table.
        expect(Orphan).to be < HasMissingTable
        expect(Orphan.table_name).to eq HasMissingTable.table_name
      end

      it "lets Active Record raise its own error, naming the table" do
        expect { Orphan.create!(name: "x") }
          .to raise_error(ActiveRecord::StatementInvalid, /#{HasMissingTable.table_name}/)
      end

      it "tears down without failing an example that otherwise passed" do
        # Reaching the end of this example at all is the assertion: teardown has
        # no rows to delete and must not go looking for them.
        expect(Orphan.name).to eq "Orphan"
      end
    end

    describe "when the superclass's table is created during the example" do
      with_model :LateChild, superclass: HasLateTable do
        table(false)
      end

      after do
        ActiveRecord::Base.connection.drop_table HasLateTable.table_name, if_exists: true
      end

      it "inherits the table once it exists" do
        ActiveRecord::Base.connection.create_table HasLateTable.table_name, force: true do |t|
          t.string :type
          t.string :name
        end
        HasLateTable.reset_column_information

        LateChild.create!(name: "late")

        expect(HasLateTable.count).to eq 1
        expect(HasLateTable.first).to be_a LateChild
      end
    end

    describe "refusals" do
      def create_model(superclass:, &dsl)
        model = WithModel::Model.new(:Refused, superclass: superclass)
        WithModel::Model::DSL.new(model).instance_eval(&dsl || proc { table(false) })
        model.create
      end

      it "names the model, which the superclass's name does not identify" do
        expect { create_model(superclass: ActiveRecord::Base) }
          .to raise_error(WithModel::InvalidSuperclass, /with_model :Refused has no table of its own/)
      end

      it "refuses ActiveRecord::Base as the superclass" do
        expect { create_model(superclass: ActiveRecord::Base) }
          .to raise_error(WithModel::InvalidSuperclass, /ActiveRecord::Base has none to inherit/)
      end

      it "refuses an abstract superclass" do
        expect { create_model(superclass: IsAbstract) }
          .to raise_error(WithModel::InvalidSuperclass, /IsAbstract has none to inherit/)
      end

      it "refuses an abstract superclass that a Rails app would call ApplicationRecord" do
        expect { create_model(superclass: ApplicationRecord) }
          .to raise_error(WithModel::InvalidSuperclass, /ApplicationRecord has none to inherit/)
      end

      context "when the superclass table lacks the inheritance column" do
        with_table(HasNoTypeColumn.table_name) do |t|
          t.string :name
        end

        before { HasNoTypeColumn.reset_column_information }

        it "refuses and names the column it looked for" do
          expect { create_model(superclass: HasNoTypeColumn) }
            .to raise_error(WithModel::InvalidSuperclass, /"type" column/)
        end
      end

      context "when the superclass disables inheritance" do
        with_table(HasNilInheritanceColumn.table_name) do |t|
          t.string :name
        end

        it "refuses" do
          expect { create_model(superclass: HasNilInheritanceColumn) }
            .to raise_error(WithModel::InvalidSuperclass)
        end
      end

      it "refuses a table(false) call that also passes a block" do
        expect do
          create_model(superclass: HasTypeColumn) { table(false) { |t| t.string :nope } }
        end.to raise_error(ArgumentError, /table does not take a block when its first argument is falsy/)
      end

      describe "a superclass that cannot be found" do
        it "quotes the reason it could not be resolved" do
          expect { create_model(superclass: "NoSuchParent") }
            .to raise_error(WithModel::MissingSuperclass,
              /superclass "NoSuchParent" could not be resolved: uninitialized constant NoSuchParent/)
        end

        it "names the segment of a namespaced superclass that is missing" do
          expect { create_model(superclass: "NoSuchNamespace::Deep::Parent") }
            .to raise_error(WithModel::MissingSuperclass, /uninitialized constant NoSuchNamespace\./)
        end

        it "reports an unresolvable Symbol as the Symbol that was passed" do
          expect { create_model(superclass: :NoSuchParent) }
            .to raise_error(WithModel::MissingSuperclass,
              /superclass :NoSuchParent could not be resolved: uninitialized constant NoSuchParent/)
        end

        it "keeps the NameError as its cause" do
          # Ruby sets this for a raise inside a rescue, so the original backtrace
          # stays reachable.
          expect { create_model(superclass: "NoSuchParent") }
            .to raise_error(WithModel::MissingSuperclass) { |error|
              expect(error.cause).to be_a NameError
            }
        end
      end

      it "tells a missing superclass apart from an unusable one, but catches both" do
        expect(WithModel::MissingSuperclass).to be < WithModel::InvalidSuperclass
        expect(WithModel::InvalidSuperclass).to be < ArgumentError
      end

      it "says how to name a class that is not defined yet" do
        expect { create_model(superclass: 42) }
          .to raise_error(WithModel::InvalidSuperclass,
            /name it with a String or a Symbol, or pass a callable returning it/)
      end

      it "refuses a value that only has a to_s" do
        # Every object has one, so honoring it would look up the constant "42".
        expect { create_model(superclass: 42) }
          .to raise_error(WithModel::InvalidSuperclass, /but was 42/)
      end

      it "refuses a callable returning a non-ActiveRecord value" do
        expect { create_model(superclass: -> { 42 }) }
          .to raise_error(WithModel::InvalidSuperclass, /but was 42/)
      end
    end
  end

  RSpec.describe "omitting table" do
    def capture_deprecations
      collected = []
      WithModel.deprecator.behavior = ->(message, *) { collected << message }
      yield
      collected
    ensure
      WithModel.deprecator.behavior = :raise
    end

    # Definition-time warning, so the assertion drives a throwaway example group
    # rather than relying on this file's own load order.
    def define_group(&body)
      RSpec::Core::ExampleGroup.describe("throwaway", &body)
    end

    it "warns when no table is specified" do
      messages = capture_deprecations do
        define_group { with_model(:Warned) }
      end
      expect(messages.join).to match(/table/)
    end

    it "names the 3.0 horizon in the warning" do
      messages = capture_deprecations do
        define_group { with_model(:Warned) }
      end
      expect(messages.join).to include("3.0")
    end

    # Left to itself ActiveSupport::Deprecation blames the first frame it does not
    # recognize as Rails or the standard library, which is with_model's own source
    # - the same line for every omission in a suite.
    it "blames the with_model call rather than with_model's own source" do
      messages = capture_deprecations do
        define_group { with_model(:Warned) }
      end

      expect(messages.join).to include("#{__FILE__}:#{__LINE__ - 3}")
      expect(messages.join).not_to include("lib/with_model.rb")
    end

    it "does not warn for table(false)" do
      messages = capture_deprecations do
        define_group { with_model(:Quiet, superclass: HasTypeColumn) { table(false) } }
      end
      expect(messages).to be_empty
    end

    it "does not warn for an empty table block" do
      messages = capture_deprecations do
        define_group do
          with_model(:Quiet) do
            table do
            end
          end
        end
      end
      expect(messages).to be_empty
    end

    it "does not warn for a `table` call with no arguments" do
      messages = capture_deprecations do
        define_group { with_model(:Quiet) { table } }
      end
      expect(messages).to be_empty
    end
  end
end
