#This class generates shell scripts from a configuration.
class Lightning
  module Generator
    extend self

    HEADER = <<-INIT.gsub(/^\s+/,'')
    #### This file was generated by Lightning. ####
    #LBIN_PATH="$PWD/bin/" #only use for development
    LBIN_PATH=""
    INIT

    def can_generate?
      respond_to? "#{shell}_generator"
    end

    def shell
      Lightning.config[:shell] || 'bash'
    end

    def run(generated_file)
      generated_file ||= Lightning.config[:generated_file]
      Cli.read_config
      output = generate(Lightning.commands.values)
      File.open(generated_file, 'w'){|f| f.write(output) }
      output
    end

    def generate(*args)
      HEADER + "\n\n" + send("#{shell}_generator", *args)
    end
    
    def bash_generator(commands)
      commands.map do |e|
        <<-EOS
          #{'#' + e['description'] if e['description']}
          #{e['name']} () {
            #{e['shell_command']} `${LBIN_PATH}lightning-translate #{e['name']} $@`
          }
          complete -o default -C "${LBIN_PATH}lightning-complete #{e['name']}" #{e['name']}
        EOS
      end.join("\n").gsub(/^\s{6,10}/, '')
    end
  end
end
