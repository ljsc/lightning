require File.join(File.dirname(__FILE__), 'test_helper')

class Lightning::ConfigTest < Test::Unit::TestCase
  context "A config" do
    before(:all) {
      @config = Lightning::Config.new
    }
    
    should "be a hash" do
      assert @config.is_a?(Hash)
    end
    
    should "have keys that are symbols" do
      assert @config.keys.all? {|e| e.is_a?(Symbol)}
    end
    
    should "have read supported keys" do
      supported_keys = [:generated_file, :ignore_basenames, :bolts, :shell, :complete_regex]
      assert_arrays_equal supported_keys, @config.keys 
    end
    
    should "have a generated_file key which is a string" do
      assert @config[:generated_file].is_a?(String)
    end
    
    should "have a paths key which is a hash" do
      assert @config[:bolts].is_a?(Hash)
    end
    
    should "have an ignore_basenames key which is an array" do
      assert @config[:ignore_basenames].is_a?(Array)
    end
  end
end
