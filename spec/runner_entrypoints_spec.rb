# frozen_string_literal: true

require "open3"
require "rbconfig"
require "tmpdir"

RSpec.describe "runner integration entrypoints" do
  def run_ruby(source, load_paths: ["lib"])
    Open3.capture3(
      RbConfig.ruby,
      *load_paths.map { |path| "-I#{path}" },
      "-e",
      source
    )
  end

  def expect_native_runner_to_pass(source, load_paths: ["lib"])
    stdout, stderr, status = run_ruby(source, load_paths:)

    expect(status).to be_success, <<~MESSAGE
      subprocess failed with status #{status.exitstatus}
      stdout:
      #{stdout}
      stderr:
      #{stderr}
    MESSAGE
  end

  it "configures RSpec and extends new example groups" do
    expect_native_runner_to_pass(<<~'RUBY')
      require "with_model/rspec"
      abort "runner: #{WithModel.runner.inspect}" unless WithModel.runner == :rspec

      RSpec.describe "entrypoint" do
        it "installs the DSL" do
          expect(self.class).to respond_to(:with_model)
        end
      end

      exit RSpec::Core::Runner.run([])
    RUBY
  end

  it "configures Minitest and extends new test subclasses" do
    expect_native_runner_to_pass(<<~'RUBY')
      require "with_model/minitest"
      abort "runner: #{WithModel.runner.inspect}" unless WithModel.runner == :minitest

      # Assert that minitest/autorun is not loaded
      autorun_loaded = $LOADED_FEATURES.any? { |f| f.end_with?("/minitest/autorun.rb") }
      abort "autorun should not be loaded; loaded features: #{$LOADED_FEATURES.inspect}" if autorun_loaded

      class MinitestEntrypointTest < Minitest::Test
        def test_installs_the_dsl
          assert_respond_to self.class, :with_model
        end
      end

      exit(Minitest.run ? 0 : 1)
    RUBY
  end

  it "configures Test::Unit and extends new test subclasses" do
    expect_native_runner_to_pass(<<~'RUBY')
      require "with_model/test_unit"
      abort "runner: #{WithModel.runner.inspect}" unless WithModel.runner == :test_unit

      class TestUnitEntrypointTest < Test::Unit::TestCase
        def test_installs_the_dsl
          assert_respond_to self.class, :with_model
        end
      end
    RUBY
  end

  it "propagates Test::Unit's LoadError when the framework is unavailable" do
    Dir.mktmpdir do |directory|
      Dir.mkdir(File.join(directory, "test"))
      File.write(
        File.join(directory, "test/unit.rb"),
        'raise LoadError, "distinctive test/unit LoadError"'
      )

      expect_native_runner_to_pass(<<~'RUBY', load_paths: [directory, "lib"])
        begin
          require "with_model/test_unit"
        rescue LoadError => error
          abort "unexpected LoadError: #{error.message.inspect}" unless
            error.message == "distinctive test/unit LoadError"
        else
          abort "expected a LoadError"
        end
      RUBY
    end
  end

  it "retains manual Test::Unit setup with plain with_model" do
    expect_native_runner_to_pass(<<~'RUBY')
      require "test/unit"
      require "with_model"

      WithModel.runner = :test_unit
      Test::Unit::TestCase.extend WithModel
      abort "runner: #{WithModel.runner.inspect}" unless WithModel.runner == :test_unit

      class PlainWithModelTestUnitTest < Test::Unit::TestCase
        def test_installs_the_dsl
          assert_respond_to self.class, :with_model
        end
      end
    RUBY
  end

  it "retains manual RSpec setup with plain with_model" do
    expect_native_runner_to_pass(<<~'RUBY')
      require "rspec"
      require "with_model"

      WithModel.runner = :rspec
      RSpec.configure do |config|
        config.extend WithModel
      end
      abort "runner: #{WithModel.runner.inspect}" unless WithModel.runner == :rspec

      RSpec.describe "entrypoint" do
        it "installs the DSL" do
          expect(self.class).to respond_to(:with_model)
        end
      end

      exit RSpec::Core::Runner.run([])
    RUBY
  end

  it "retains manual Minitest setup with plain with_model" do
    expect_native_runner_to_pass(<<~'RUBY')
      require "minitest"
      require "with_model"

      WithModel.runner = :minitest
      Minitest::Test.extend WithModel
      abort "runner: #{WithModel.runner.inspect}" unless WithModel.runner == :minitest

      class PlainWithModelMinitestTest < Minitest::Test
        def test_installs_the_dsl
          assert_respond_to self.class, :with_model
        end
      end

      exit(Minitest.run ? 0 : 1)
    RUBY
  end
end
