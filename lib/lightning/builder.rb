module Lightning
  # Builds shell file ~/.lightning/functions.sh from the config file. This file
  # is built and sourced into a user's shell using `lightning-reload`.
  # Currently supports bash and zsh shells. Defaults to building for bash.
  module Builder
    extend self

    # @private
    HEADER = <<-INIT.gsub(/^\s{4}/,'')
    #### This file was built by lightning. ####
    #LBIN_PATH="$PWD/bin/" #only use for development
    LBIN_PATH=""
    
    lightning-reload() {
      lightning install $@
      source_file=$(lightning source_file)
      source $source_file
      echo Loaded $source_file
    }
    INIT

    # @return [Boolean] Determines if Builder can build a file for its current shell
    def can_build?
      respond_to? "#{shell}_builder"
    end

    # @return [String] Current shell, defaults to 'bash'
    def shell
      Lightning.config[:shell] || 'bash'
    end

    # @return [String] Builds shell file
    def run
      return puts("No builder exists for #{Builder.shell} shell") unless Builder.can_build?
      functions = Lightning.functions.values
      check_for_existing_commands(functions)
      output = build(functions)
      File.open(Lightning.config.source_file, 'w') {|f| f.write(output) }
      output
    end

    # @param [Array] Function objects
    # @return [String] Shell file string to be saved and sourced
    def build(args)
      HEADER + "\n\n" + send("#{shell}_builder", *[args])
    end

    protected
    def bash_builder(functions)
      functions.map do |e|
        <<-EOS.gsub(/^\s{10}/,'')
          #{e.name} () {
            local IFS=$'\\n'
            local arr=( $(${LBIN_PATH}lightning-translate #{e.name} $@) )
            #{e.shell_command} "${arr[@]}"
          }
          complete -o default -C "${LBIN_PATH}lightning-complete #{e.name}" #{e.name}
        EOS
      end.join("\n")
    end

    def zsh_builder(functions)
      functions.map do |e|
        <<-EOS.gsub(/^\s{10}/,'')
          #{e.name} () {
            local IFS=$'\\n'
            local arr
            arr=( $(${LBIN_PATH}lightning-translate #{e.name} $@) )
            #{e.shell_command} "${arr[@]}"
          }
          _#{e.name} () {
            local IFS=$'\\n'
            reply=( $(${LBIN_PATH}lightning-complete #{e.name} "${@}") )
          }
          compctl -QK _#{e.name} #{e.name}
        EOS
      end.join("\n")
    end

    def check_for_existing_commands(functions)
      if !(existing_commands = functions.select {|e| Util.shell_command_exists?(e.name) }).empty?
        puts "The following commands already exist in $PATH and are being generated: "+
          "#{existing_commands.map {|e| e.name}.join(', ')}"
      end
    end
  end
end
