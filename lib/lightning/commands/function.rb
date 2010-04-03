module Lightning::Commands
  meta '(list [--command=SHELL_COMMAND] [--bolt=BOLT] | create SHELL_COMMAND BOLT [function] | delete FUNCTION)',
    'Commands for managing functions. Defaults to listing them.'
  def function(argv)
    subcommand = argv.shift || 'list'
    subcommand = %w{create delete list}.find {|e| e[/^#{subcommand}/]} || subcommand
    function_subcommand(subcommand, argv) if subcommand_has_required_args(subcommand, argv)
  end

  def function_subcommand(subcommand, argv)
    case subcommand
    when 'list'
      Lightning.setup
      args, options = parse_args argv
      functions = if options[:bolt]
        Lightning.functions.values.select {|e| e.bolt.name == options[:bolt] }.map {|e| e.name}
      elsif options[:command]
        Lightning.functions.values.select {|e| e.shell_command == options[:command] }.map {|e| e.name}
      else
        Lightning.functions.keys
      end
      puts functions.sort
    when 'create'  then Lightning.config.create_function_and_bolt(argv)
    when 'delete'  then Lightning.setup; Lightning.config.delete_function argv.shift
    else puts "Invalid subcommand '#{subcommand}'", command_usage
    end
  end
end