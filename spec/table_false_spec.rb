# frozen_string_literal: true

require "spec_helper"

RSpec.describe "table(false)" do
  # Defines a named Active Record class for one example, equivalent to:
  #
  #   class HasLateTable < ActiveRecord::Base
  #   end
  #
  # RSpec removes the constant afterward; the matching `after` hook below also
  # clears Active Record's descendant trackers so the class object cannot leak.
  def stub_active_record_class(name, superclass: ActiveRecord::Base)
    klass = Class.new(superclass)
    stub_const(name.to_s, klass)
    (@stubbed_active_record_classes ||= []) << klass
    klass
  end

  after do
    classes = @stubbed_active_record_classes
    next unless classes

    WithModel::DescendantsTracker.clear(classes)
  end

  describe "with a concrete superclass" do
    with_model :HasTypeColumn do
      table do |t|
        t.string :type
        t.string :name
      end
    end

    with_model :Truck, superclass: :HasTypeColumn do
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

    # Deliberately a second example asserting the same thing: both models are
    # rebuilt for every example, so a superclass resolved once and cached on the
    # Model instance would still point to the first example's dead parent.
    it "works in a second example too" do
      Truck.create!(name: "also big")
      expect(HasTypeColumn.first).to be_a Truck
    end
  end

  describe "teardown" do
    with_model :HasTypeColumn do
      table do |t|
        t.string :type
        t.string :name
      end
    end

    context "when child and superclass rows exist" do
      after do
        expect(HasTypeColumn.where(type: "Truck").count).to eq 0
        expect(HasTypeColumn.where(type: nil).count).to eq 1
      end

      with_model :Truck, superclass: :HasTypeColumn do
        table(false)
      end

      it "deletes its own rows and leaves the superclass's rows alone" do
        Truck.create!(name: "child row")
        HasTypeColumn.create!(name: "parent row")
      end
    end

    context "when a child row exists" do
      after do
        expect { HasTypeColumn.first }.not_to raise_error
      end

      with_model :Truck, superclass: :HasTypeColumn do
        table(false)
      end

      it "leaves the superclass queryable" do
        Truck.create!(name: "child row")
      end
    end

    context "with an abstract superclass" do
      with_model :TablelessSuperclass do
        table
        model do
          self.abstract_class = true
          self.table_name = nil
        end
      end

      it "does not delete rows when create raises WithModel::InvalidSuperclass" do
        HasTypeColumn.create!(name: "parent row")
        tableless_subclass = WithModel::Model.new(
          :TablelessSubclass,
          superclass: TablelessSuperclass
        )
        WithModel::Model::DSL.new(tableless_subclass).table(false)

        expect { tableless_subclass.create }.to raise_error(WithModel::InvalidSuperclass)
        expect { tableless_subclass.destroy }.not_to raise_error

        expect(HasTypeColumn.count).to eq 1
      end
    end

    context "when destruction of its row is aborted" do
      with_model :AbortsDestroy do
        table do |t|
          t.string :type
        end
        model do
          before_destroy { throw :abort }
        end
      end

      subject(:null_table) do
        WithModel::NullTable.new(AbortsDestroy, :TemporaryAbortedDestroy)
      end

      after do
        expect(Object.const_defined?(:TemporaryAbortedDestroy, false)).to be false
      end

      with_model :TemporaryAbortedDestroy, superclass: :AbortsDestroy do
        table(false)
      end

      it "fails loudly" do
        TemporaryAbortedDestroy.create!

        expect do
          null_table.teardown(TemporaryAbortedDestroy)
        end.to raise_error(ActiveRecord::RecordNotDestroyed)

        AbortsDestroy.where(type: TemporaryAbortedDestroy.sti_name).delete_all
      end
    end

    context "when its rows have dependent records protected by a foreign key" do
      with_model :HasDependentChildren do
        table do |t|
          t.string :type
        end
        model do
          has_many :dependent_children,
            class_name: "DependentChild",
            foreign_key: :parent_id,
            inverse_of: :parent,
            dependent: :destroy
        end
      end

      with_model :DependentChild do
        table do |t|
          t.references :parent,
            null: false,
            foreign_key: {to_table: HasDependentChildren.table_name}
        end
        model do
          belongs_to :parent,
            class_name: "HasDependentChildren",
            inverse_of: :dependent_children
        end
      end

      with_model :OtherDependentParent, superclass: :HasDependentChildren do
        table(false)
      end

      after do
        expect(HasDependentChildren.unscoped.ids).to contain_exactly(@superclass.id, @sibling.id)
        expect(DependentChild.pluck(:parent_id)).to contain_exactly(@superclass.id, @sibling.id)
      end

      with_model :TemporaryDependentParent, superclass: :HasDependentChildren do
        table(false)
      end

      it "destroys its dependents without removing superclass or sibling rows" do
        temporary = TemporaryDependentParent.create!
        @superclass = HasDependentChildren.create!
        @sibling = OtherDependentParent.create!
        [temporary, @superclass, @sibling].each do |parent|
          parent.dependent_children.create!
        end
      end
    end
  end

  describe "with a superclass that has a default_scope" do
    with_model :HasDefaultScope do
      table do |t|
        t.string :type
        t.boolean :archived, default: false
      end
      model do
        default_scope { where(archived: false) }
      end
    end

    after do
      expect(HasDefaultScope.unscoped.where(type: "ScopedChild").count).to eq 0
    end

    with_model :ScopedChild, superclass: :HasDefaultScope do
      table(false)
    end

    it "deletes rows the default scope would have hidden" do
      ScopedChild.create!(archived: false)
      ScopedChild.create!(archived: true)
    end
  end

  describe "with a non-standard inheritance_column" do
    with_model :HasCustomInheritanceColumn do
      table do |t|
        t.string :kind
        t.string :name
      end
      model do
        self.inheritance_column = "kind"
      end
    end

    with_model :KindedChild, superclass: :HasCustomInheritanceColumn do
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
    with_model :CustomInheritanceWithType do
      table do |t|
        t.string :kind
        t.string :type
        t.string :name
      end
      model do
        self.inheritance_column = "kind"
      end
    end

    with_model :KindedTypeChild, superclass: :CustomInheritanceWithType do
      table(false)
    end

    it "writes the custom column and leaves type null" do
      KindedTypeChild.create!(name: "x")
      row = CustomInheritanceWithType.first
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
    with_model :HasTypeColumn do
      table do |t|
        t.string :type
        t.string :name
      end
    end

    # WithModel::ConstantStubber resolves a namespaced name with `const_get` and
    # stubs only the last segment, so the namespace has to exist already.
    before { stub_const("TableFalseSpec", Module.new) }

    with_model "TableFalseSpec::Step", superclass: :HasTypeColumn do
      table(false)
    end

    it "stores and round-trips the fully qualified name" do
      TableFalseSpec::Step.create!(name: "x")
      expect(HasTypeColumn.first.type).to eq "TableFalseSpec::Step"
      expect(HasTypeColumn.first).to be_a TableFalseSpec::Step
    end
  end

  # A missing table is a fact about the schema at that moment, not about the
  # model, so it is allowed: the table may arrive later in the example, or its
  # absence may be the very thing under test.
  describe "when the superclass's table does not exist" do
    # The shape a Rails app's ApplicationRecord takes: abstract, and inherited
    # from rather than ActiveRecord::Base directly.
    with_model :ApplicationRecord do
      table
      model do
        self.abstract_class = true
        self.table_name = nil
      end
    end

    before do
      stub_active_record_class(:HasMissingTable, superclass: ApplicationRecord)
    end

    with_model :Orphan, superclass: -> { HasMissingTable } do
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
    before { stub_active_record_class(:HasLateTable) }

    with_model :LateChild, superclass: -> { HasLateTable } do
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

  describe "invalid configurations" do
    # Creates immediately the same tableless subclass normally generated by:
    #
    #   with_model :TablelessSubclass, superclass: superclass do
    #     table(false)
    #   end
    #
    # Bypassing `with_model`'s setup hook lets these examples assert failures
    # raised while the superclass is resolved or the table configuration checked.
    def create_tableless_subclass(superclass:, &dsl)
      model = WithModel::Model.new(:TablelessSubclass, superclass: superclass)
      WithModel::Model::DSL.new(model).instance_eval(&dsl || proc { table(false) })
      model.create
    end

    it "names the model, which the superclass's name does not identify" do
      expect { create_tableless_subclass(superclass: ActiveRecord::Base) }
        .to raise_error(
          WithModel::InvalidSuperclass,
          /with_model :TablelessSubclass has no table of its own/
        )
    end

    it "raises WithModel::InvalidSuperclass for ActiveRecord::Base" do
      expect { create_tableless_subclass(superclass: ActiveRecord::Base) }
        .to raise_error(WithModel::InvalidSuperclass, /ActiveRecord::Base has none to inherit/)
    end

    context "with an abstract superclass" do
      with_model :TablelessSuperclass do
        table
        model do
          self.abstract_class = true
          self.table_name = nil
        end
      end

      it "raises WithModel::InvalidSuperclass" do
        expect { create_tableless_subclass(superclass: TablelessSuperclass) }
          .to raise_error(WithModel::InvalidSuperclass, /TablelessSuperclass has none to inherit/)
      end
    end

    context "with an abstract superclass a Rails app would call ApplicationRecord" do
      with_model :ApplicationRecord do
        table
        model do
          self.abstract_class = true
          self.table_name = nil
        end
      end

      it "raises WithModel::InvalidSuperclass" do
        expect { create_tableless_subclass(superclass: ApplicationRecord) }
          .to raise_error(WithModel::InvalidSuperclass, /ApplicationRecord has none to inherit/)
      end
    end

    context "when the superclass table lacks the inheritance column" do
      with_model :HasNoTypeColumn do
        table do |t|
          t.string :name
        end
      end

      it "raises WithModel::InvalidSuperclass and names the missing column" do
        expect { create_tableless_subclass(superclass: HasNoTypeColumn) }
          .to raise_error(WithModel::InvalidSuperclass, /"type" column/)
      end
    end

    context "when the superclass disables inheritance" do
      with_model :HasNilInheritanceColumn do
        table do |t|
          t.string :name
        end
        model do
          self.inheritance_column = nil
        end
      end

      it "raises WithModel::InvalidSuperclass" do
        expect { create_tableless_subclass(superclass: HasNilInheritanceColumn) }
          .to raise_error(WithModel::InvalidSuperclass)
      end
    end

    context "when table(false) is passed a block" do
      with_model :HasTypeColumn do
        table do |t|
          t.string :type
          t.string :name
        end
      end

      it "raises ArgumentError" do
        expect do
          create_tableless_subclass(superclass: HasTypeColumn) { table(false) { |t| t.string :nope } }
        end.to raise_error(ArgumentError, /table does not take a block when its first argument is falsy/)
      end
    end

    describe "a superclass that cannot be found" do
      it "quotes the reason it could not be resolved" do
        expect { create_tableless_subclass(superclass: "NoSuchParent") }
          .to raise_error(WithModel::MissingSuperclass,
            /superclass "NoSuchParent" could not be resolved: uninitialized constant NoSuchParent/)
      end

      it "names the segment of a namespaced superclass that is missing" do
        expect { create_tableless_subclass(superclass: "NoSuchNamespace::Deep::Parent") }
          .to raise_error(WithModel::MissingSuperclass, /uninitialized constant NoSuchNamespace\./)
      end

      it "reports an unresolvable Symbol as the Symbol that was passed" do
        expect { create_tableless_subclass(superclass: :NoSuchParent) }
          .to raise_error(WithModel::MissingSuperclass,
            /superclass :NoSuchParent could not be resolved: uninitialized constant NoSuchParent/)
      end

      it "keeps the NameError as its cause" do
        # Ruby sets this for a raise inside a rescue, so the original backtrace
        # stays reachable.
        expect { create_tableless_subclass(superclass: "NoSuchParent") }
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
      expect { create_tableless_subclass(superclass: 42) }
        .to raise_error(WithModel::InvalidSuperclass,
          /name it with a String or a Symbol, or pass a callable returning it/)
    end

    it "raises WithModel::InvalidSuperclass for a value that only has a to_s" do
      # Every object has one, so honoring it would look up the constant "42".
      expect { create_tableless_subclass(superclass: 42) }
        .to raise_error(WithModel::InvalidSuperclass, /but was 42/)
    end

    it "raises WithModel::InvalidSuperclass for a callable returning a non-ActiveRecord value" do
      expect { create_tableless_subclass(superclass: -> { 42 }) }
        .to raise_error(WithModel::InvalidSuperclass, /but was 42/)
    end
  end
end

RSpec.describe "omitting table" do
  before do
    allow(WithModel.deprecator).to receive(:warn)
  end

  # Defines the supplied block as if it had appeared in an isolated group:
  #
  #   RSpec.describe "throwaway" do
  #     # supplied definitions
  #   end
  #
  # The warning happens at definition time, so the assertion cannot rely on this
  # file's own example-group load order.
  def define_group(&body)
    RSpec::Core::ExampleGroup.describe("throwaway", &body)
  end

  it "warns when no table is specified" do
    define_group { with_model(:Warned) }

    expect(WithModel.deprecator).to have_received(:warn) do |message, _callstack|
      expect(message).to match(/table/)
    end
  end

  it "names the 3.0 horizon in the warning" do
    define_group { with_model(:Warned) }

    expect(WithModel.deprecator).to have_received(:warn) do |message, _callstack|
      expect(message).to include("3.0")
    end
  end

  # Left to itself ActiveSupport::Deprecation blames the first frame it does not
  # recognize as Rails or the standard library, which is with_model's own source
  # - the same line for every omission in a suite.
  it "blames the with_model call rather than with_model's own source" do
    expected_source_line = __LINE__ + 1
    define_group { with_model(:Warned) }

    expect(WithModel.deprecator).to have_received(:warn) do |_message, callstack|
      expect(callstack.first.path).to eq(__FILE__)
      expect(callstack.first.lineno).to eq(expected_source_line)
      expect(callstack.first.path).not_to include("lib/with_model.rb")
    end
  end

  context "when table(false) is used" do
    with_model :HasTypeColumn do
      table do |t|
        t.string :type
        t.string :name
      end
    end

    it "does not warn" do
      define_group { with_model(:Quiet, superclass: HasTypeColumn) { table(false) } }

      expect(WithModel.deprecator).not_to have_received(:warn)
    end
  end

  it "does not warn for an empty table block" do
    define_group do
      with_model(:Quiet) do
        table do
        end
      end
    end

    expect(WithModel.deprecator).not_to have_received(:warn)
  end

  it "does not warn for a `table` call with no arguments" do
    define_group { with_model(:Quiet) { table } }

    expect(WithModel.deprecator).not_to have_received(:warn)
  end
end
