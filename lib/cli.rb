require 'readline'

class CLI
  PROMPT = 'btree_sqlite> '

  def initialize
    require_relative 'core/sql_command_processor'
  end

  def start
    puts 'Welcome to BTreeSQLite!'
    loop do
      input = Readline.readline(PROMPT, true)
      break if input.nil? || input.strip.casecmp('.exit').zero? || input.strip.casecmp('exit').zero?

      process_input(input.strip)
    end
    puts 'Goodbye!'
  end

  private

  def process_input(input)
    if input.start_with?('.')
      handle_meta_command(input)
    else
      processor = SQLCommandProcessor.new
      result = processor.execute(input)
      puts result unless result.nil? || result.empty?
    end
  end

  def handle_meta_command(command)
    case command
    when '.help'
      puts 'Available commands:'
      puts '.help - Show this help message'
      puts '.exit - Exit the CLI'
    else
      puts "Unknown command: #{command}"
    end
  end
end
