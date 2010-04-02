module Lightning
  # Generates hashes of bolt attributes using methods defined in Generators.
  # Bolt hashes are inserted under config[:bolts] and Config.config_file is saved.
  class Generator
    DEFAULT_GENERATORS = %w{gem gem_doc ruby local_ruby wild bin}

    # Hash of generators and their descriptions
    def self.generators
      load_plugins
      Generators.generators
    end

    # Runs generator
    # @param [Array] String which point to instance methods in Generators
    def self.run(gens=[], options={})
      load_plugins
      new.run(gens, options)
    rescue
      $stderr.puts "Error: #{$!.message}"
    end

    def self.load_plugins
      @loaded ||= begin
        Util.load_plugins File.dirname(__FILE__), 'generators'
        Util.load_plugins Lightning.dir, 'generators'
        true
      end
    end

    attr_reader :underling
    def initialize
      @underling = Object.new.extend(Generators)
    end

    def run(gens, options)
      if options.key?(:once)
        run_once(gens, options)
      else
        # @silent = true
        gens = DEFAULT_GENERATORS if Array(gens).empty?
        gens = Hash[*gens.zip(gens).flatten] if gens.is_a?(Array)
        generate_bolts gens
      end
    end

    def run_once(bolt, options)
      generator = options[:once] || bolt
      if options[:test]
        puts Config.bolt(call_generator(generator))['globs']
      else
        if generate_bolts(bolt=>generator)
          puts "Generated following globs for bolt '#{bolt}':"
          puts Lightning.config.bolts[bolt]['globs'].map {|e| "  "+e }
          true
        end
      end
    end

    protected
    def generate_bolts(bolts)
      results = bolts.map {|bolt, gen|
        (globs = call_generator(gen)) && Lightning.config.bolts[bolt.to_s] = Config.bolt(globs)
      }
      Lightning.config.save if results.any?
      results.all?
    end

    def call_generator(gen)
      raise "Generator method doesn't exist." unless @underling.respond_to?(gen)
      Array(@underling.send(gen)).map {|e| e.to_s }
    rescue
      $stdout.puts "Generator '#{gen}' failed with: #{$!.message}" unless @silent
    end
  end
end