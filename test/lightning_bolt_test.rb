require File.dirname(__FILE__) + '/test_helper'

class LightningBoltTest < Test::Unit::TestCase
  context "Bolt" do
    before(:each) do
      @path_map = {'path1'=>'/dir/path1','path2'=>'/dir/path2'}
      @bolt = Lightning::Bolt.new('blah')
      @bolt.path_map.map = @path_map
    end
    
    test "fetches correct completions" do
      assert_equal @bolt.completions, @path_map.keys
    end

    test "resolves completion" do
      assert_equal @path_map['path1'], @bolt.resolve_completion('path1')
    end

    test "resolves completion with test flag" do
      assert_equal @path_map['path1'], @bolt.resolve_completion('-test path1')
    end

    test "creates path_map only once" do
      assert_equal @bolt.path_map.object_id, @bolt.path_map.object_id
    end
  end
end