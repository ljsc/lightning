require File.join(File.dirname(__FILE__), 'test_helper')

context "Function" do
  def create_function(attributes={})
    # bolt, path and aliases depend on test/lightning.yml
    @fn = Function.new({'name'=>'blah', 'bolt'=>Bolt.new('app'), 'desc'=>'blah'}.merge(attributes))
    @fn.completion_map.map = {'path1'=>'/dir/path1','path2'=>'/dir/path2',
      'path3'=>'/dir/path3', 'file 1'=>'/dir/file 1'}
  end

  def translate(input, *expected)
    Lightning.functions['blah'] = @fn
    mock(Commands).puts(expected.join("\n"))
    run_command :translate, ['blah'] + input.split(' ')
  end

  before_all do
    create_function
    @map = @fn.completion_map
  end

  test "has correct completions" do
    assert_arrays_equal %w{a1 a2}+['file 1']+%w{path1 path2 path3}, @fn.completions
  end

  test "has bolt's globs" do
    @fn.globs.should.not.be.empty?
    @fn.globs.should == @fn.bolt.globs
  end

  test "has bolt's aliases" do
    @fn.aliases.should.not.be.empty?
    @fn.aliases.should == @fn.bolt.aliases
  end

  test "can have a desc" do
    @fn.desc.should.not.be.empty?
  end

  test "translates a completion" do
    translate 'path1', @map['path1']
  end

  test "translates multiple completions separately" do
    translate 'path1 path2', @map['path1'], @map['path2']
  end

  test "translates instant multiple completions (..)" do
    translate 'path.. blah a1', @map['path1'], @map['path2'], @map['path3'], 'blah', @map['a1']
  end

  test "translates instant multiple completions containing spaces" do
    translate 'file..', @map['file 1']
  end

  test "translates non-completion to same string" do
    translate 'blah', 'blah'
  end

  test "translates completion anywhere amongst non-completions" do
    translate '-r path1', "-r", "#{@map['path1']}"
    translate '-r path1 doc/', "-r", "#{@map['path1']}", "doc/"
  end

  test "translates completion embedded in subdirectory completion" do
    translate '-r path1/sub/dir', "-r", "#{@map['path1']}/sub/dir"
  end

  test "translates completion with a superdirectory" do
    mock(File).expand_path("#{@map['path1']}/../file1") { '/dir/file1' }
    translate 'path1/../file1', '/dir/file1'
  end

  test "translates completion over alias" do
    translate 'path3', '/dir/path3'
  end

  test "translates alias" do
    translate 'a1', @map['a1']
  end

  after_all { Lightning.config[:aliases] = {}}

  context "function attributes:" do
    test "post_path added after each translation" do
      create_function 'post_path'=>'/rdoc/index.html'
      translate '-r path1 path2', "-r", "/dir/path1/rdoc/index.html", "/dir/path2/rdoc/index.html"
    end
  end
end
