require 'yaml'
module Lightning
  # Handles config file used to generate bolts and functions.
  # The config file is in YAML so it's easy to manually edit. Nevertheless, it's recommended to modify
  # the config through lightning commands since their API is more stable than the config file's API.
  #
  # == Config File Format
  # 
  # Top level keys:
  #
  # * *:source_file*: Location of shell file generated by {Builder}. Defaults to ~/.lightning/functions.sh
  # * *:ignore_paths*: Array of paths to globally ignore when generating possible completions
  # * *:complete_regex*: true or false (default is true). When true, regular expressions can be used while
  #   completing. See {Completion} for more details.
  # * *:shell*: Specifies shell Builder uses to generate completions. Defaults to bash.
  # * *:bolts*: Array of bolts with each bolt being a hash with the following keys:
  #   * *name*(required): Unique name
  #   * *alias*: Abbreviated name which can be used to reference bolt in most lightning commands. This is used
  #     over name when generating function names.
  #   * *global*: true or false (default is false). When set, uses bolt to generate functions with each command
  #     in :shell_commands.
  #   * *globs*(required): Array of globs which defines group of paths bolt handles
  #   * *functions*: Array of lightning functions. A function can either be a string (shell command with default
  #     options) or a hash with the following keys:
  #     * *name*: Name of the lightning function
  #     * *shell_command*(required): Shell command with default options which this function wraps
  #     * *aliases*: A hash of custom aliases and full paths only for this function
  #     * *post_path*: String to add immediately after a resolved path
  # * *:shell_commands*: Hash of global shell commands which are combined with all global bolts to generate functions
  class Config < ::Hash
    class <<self
      attr_accessor :config_file
      # @return [String] ~/.lightningrc
      def config_file
        @config_file ||= File.join(Lightning.home,".lightningrc")
      end

      # @return [Hash] Creates a bolt hash given globs
      def bolt(globs)
        {'globs'=>globs.map {|e| e.sub(/^~/, Lightning.home) }}
      end
    end

    DEFAULT = {:complete_regex=>true, :bolts=>{}, :shell_commands=>{'cd'=>'cd', 'echo'=>'echo'} }
    attr_accessor :source_file
    def initialize(hash=read_config_file)
      hash = DEFAULT.merge hash
      super
      replace(hash)
    end

    # @return [String] Shell file generated by Builder. Defaults to ~/.lightning/functions.sh
    def source_file
      @source_file ||= self[:source_file] || File.join(Lightning.dir, 'functions.sh')
    end

    # @return [Array] Global shell commands used to generate Functions for all Bolts.
    def global_commands
      shell_commands.keys
    end

    # @return [Hash] Maps shell command names to their aliases
    def shell_commands
      self[:shell_commands]
    end

    # @return [Hash] Maps bolt names to their config hashes
    def bolts
      self[:bolts]
    end

    # @return [String] Converts shell command alias to shell command
    def unaliased_command(cmd)
      shell_commands.invert[cmd] || cmd
    end

    # @return [String] Converts bolt alias to bolt's name
    def unalias_bolt(bolt)
      bolts[bolt] ? bolt : (Array(bolts.find {|k,v| v['alias'] == bolt })[0] || bolt)
    end

    # @return [String] Extracts shell command from a shell_command string
    def only_command(shell_command)
      shell_command[/\w+/]
    end

    # @return [String] Creates a command name from its shell command and bolt in the form "#{command}-#{bolt}".
    # Uses aliases for either if they exist.
    def function_name(shell_command, bolt)
      cmd = only_command shell_command
      "#{shell_commands[cmd] || cmd}-#{bolt}"
    end

    # Saves config to Config.config_file
    def save
      File.open(self.class.config_file, "w") {|f| f.puts Hash.new.replace(self).to_yaml }
    end

    protected
    def read_config_file
      File.exists?(self.class.config_file) ?
        Util.symbolize_keys(YAML::load_file(self.class.config_file)) : {}
    rescue
      raise $!.message.sub('syntax error', "Syntax error in '#{Config.config_file}'")
    end
  end
end
