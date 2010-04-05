require 'yaml'
module Lightning
  # Handles reading and writing of a config file used to generate bolts and commands and offer
  # custom Lightning behavior.
  class Config < ::Hash
    class <<self
      attr_accessor :config_file
      # Defaults to a local lightning.yml if it exists. Otherwise a global ~/.lightning.yml.
      def config_file
        @config_file ||= File.exists?('lightning.yml') ? 'lightning.yml' :
          File.join(Lightning.home,".lightning.yml")
      end

      def bolt(globs)
        {'globs'=>globs.map {|e| e.sub(/^~/, Lightning.home) }}
      end
    end

    DEFAULT = {:complete_regex=>true, :bolts=>{}, :shell_commands=>{'cd'=>'cd', 'echo'=>'echo'} }
    def initialize(hash=read_config_file)
      hash = DEFAULT.merge hash
      super
      replace(hash)
    end

    def source_file
      @source_file ||= self[:source_file] || File.join(Lightning.dir, 'functions.sh')
    end

    # Global shell commands used to generate Functions for all Bolts.
    # @return [Array]
    def global_commands
      shell_commands.keys
    end

    # @return [Hash]
    # Maps shell command names to their aliases using @config[:shell_commands]
    def shell_commands
      self[:shell_commands]
    end

    def unaliased_command(cmd)
      shell_commands.invert[cmd] || cmd
    end

    def bolts
      self[:bolts]
    end

    # Extracts shell command from a shell_command string
    def only_command(shell_command)
      shell_command[/\w+/]
    end

    # Creates a command name from its shell command and bolt i.e. "#{command}-#{bolt}".
    # Uses aliases for either if they exist.
    def function_name(shell_command, bolt)
      cmd = only_command shell_command
      "#{shell_commands[cmd] || cmd}-#{bolt}"
    end

    def create_bolt(bolt, globs)
      bolts[bolt] = self.class.bolt(globs)
      save_and_say "Created bolt '#{bolt}'"
    end

    def unalias_bolt(bolt)
      bolts[bolt] ? bolt : (Array(bolts.find {|k,v| v['alias'] == bolt })[0] || bolt)
    end

    def if_bolt_found(bolt)
      bolt = unalias_bolt(bolt)
      bolts[bolt] ? yield(bolt) : puts("Can't find bolt '#{bolt}'")
    end

    def alias_bolt(bolt, bolt_alias)
      if_bolt_found(bolt) do |bolt|
        bolts[bolt]['alias'] = bolt_alias
        save_and_say "Aliased bolt '#{bolt}' to '#{bolt_alias}'"
      end
    end

    def delete_bolt(bolt)
      if_bolt_found(bolt) do |bolt|
        bolts.delete(bolt)
        save_and_say "Deleted bolt '#{bolt}' and its functions"
      end
    end

    def show_bolt(bolt)
      if_bolt_found(bolt) {|b| puts bolts[b].to_yaml.sub("--- \n", '') }
    end

    def globalize_bolts(boolean, arr)
      return puts("First argument must be 'on' or 'off'") unless %w{on off}.include?(boolean)
      if boolean == 'on'
        valid = arr.select {|b| if_bolt_found(b) {|bolt| bolts[bolt]['global'] = true } }
        save_and_say "Global on for bolts #{valid.join(', ')}"
      else
        valid = arr.select {|b| if_bolt_found(b) {|bolt| bolts[bolt].delete('global') ; true } }
        save_and_say "Global off for bolts #{valid.join(', ')}"
      end
    end

    # Saves config to Config.config_file
    def save
      File.open(self.class.config_file, "w") {|f| f.puts Hash.new.replace(self).to_yaml }
    end

    protected
    def save_and_say(message)
      save
      puts message
    end

    def read_config_file
      File.exists?(self.class.config_file) ?
        Util.symbolize_keys(YAML::load_file(self.class.config_file)) : {}
    rescue
      raise $!.message.sub('syntax error', "Syntax error in '#{Config.config_file}'")
    end
  end
end
