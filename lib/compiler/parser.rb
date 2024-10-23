class Parser
  def parse(tokens)
    @tokens = tokens
    @current = 0
    ast = parse_statement
    consume(:SEMICOLON) if current_token[:type] == :SEMICOLON
    raise "Unexpected token after statement: #{current_token[:type]}" if @current < @tokens.length

    ast
  end

  private

  def parse_statement
    case current_token[:type]
    when :KEYWORD
      case current_token[:value]
      when 'SELECT'
        parse_select
      when 'INSERT'
        parse_insert
      when 'CREATE'
        parse_create_table
      else
        raise "Unsupported command: #{current_token[:value]}"
      end
    else
      raise "Expected a keyword, got #{current_token[:type]}"
    end
  end

  def parse_select
    consume(:KEYWORD, 'SELECT')
    columns = parse_select_columns
    consume(:KEYWORD, 'FROM')
    table = consume(:IDENTIFIER)
    puts "Table: #{table[:value]}, Columns: #{columns}"
    { type: :select, columns: columns, table: table[:value] }
  end

  def parse_select_columns
    if match(:ASTERISK)
      ['*']
    else
      parse_columns
    end
  end

  def parse_insert
    consume(:KEYWORD, 'INSERT')
    consume(:KEYWORD, 'INTO')
    table = consume(:IDENTIFIER)
    consume(:LPAREN)
    columns = parse_columns
    consume(:RPAREN)
    consume(:KEYWORD, 'VALUES')
    consume(:LPAREN)
    values = parse_values
    consume(:RPAREN)
    { type: :insert, table: table[:value], columns: columns, values: values }
  end

  def parse_create_table
    consume(:KEYWORD, 'CREATE')
    consume(:KEYWORD, 'TABLE')
    table_name = consume(:IDENTIFIER)[:value]
    consume(:LPAREN)
    columns = parse_column_definitions
    consume(:RPAREN)
    { type: :create_table, table: table_name, columns: columns }
  end

  def parse_column_definitions
    columns = []
    loop do
      column_name = consume(:IDENTIFIER)[:value]
      data_type = consume(:KEYWORD)[:value]
      columns << { name: column_name, data_type: data_type }
      break unless match(:COMMA)
    end
    columns
  end

  def parse_columns
    columns = []
    loop do
      token = consume(:IDENTIFIER)
      columns << token[:value]
      break unless match(:COMMA)
    end
    columns
  end

  def parse_values
    values = []
    loop do
      token = current_token
      case token[:type]
      when :NUMBER, :STRING
        values << consume(token[:type])[:value]
      else
        raise "Expected value, got #{token[:type]}"
      end
      break unless match(:COMMA)
    end
    values
  end

  def consume(expected_type, expected_value = nil)
    token = current_token
    if token[:type] == expected_type && (expected_value.nil? || token[:value] == expected_value)
      advance
      token
    else
      expected = expected_value || expected_type
      raise "Expected #{expected}, got #{token[:type]} (#{token[:value]})"
    end
  end

  def match(type)
    if current_token[:type] == type
      advance
      true
    else
      false
    end
  end

  def current_token
    @tokens[@current] || { type: :EOF, value: nil }
  end

  def advance
    @current += 1
  end
end
