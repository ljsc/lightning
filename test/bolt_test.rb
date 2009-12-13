require File.join(File.dirname(__FILE__), 'test_helper')

class Lightning
  class BoltTest < Test::Unit::TestCase
    before(:all) { Cli.read_config }

    # depends on test/lightning.yml
    context "Bolt generates correct command from" do
      test "shell command" do
        assert Lightning.commands['less-app'].is_a?(Command)
      end

      test "command hash" do
        assert Lightning.commands['oa'].is_a?(Command)
      end

      test "global shell command" do
        assert Lightning.commands['grep-app'].is_a?(Command)
      end

      test "aliased global shell command in config" do
        assert Lightning.commands['v-app'].is_a?(Command)
      end

      test "global shell command which has a local config" do
        assert Lightning.commands['c'].is_a?(Command)
      end
    end
  end
end