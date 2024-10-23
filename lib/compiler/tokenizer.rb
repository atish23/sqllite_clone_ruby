class Tokenizer
  KEYWORDS = %w[
    SELECT INSERT UPDATE DELETE FROM WHERE INTO VALUES SET CREATE TABLE INTEGER TEXT
  ].freeze

  def tokenize(sql)
    tokens = []
    sql = sql.strip

    token_patterns = {
      /\A--.*$/ => -> { sql = ::Regexp.last_match.post_match }, # Skip comments
      /\A'([^']*)'/ => -> { tokens << { type: :STRING, value: ::Regexp.last_match(1) }; sql = ::Regexp.last_match.post_match }, # Tokenize strings
      /\A(\d+)/ => -> { tokens << { type: :NUMBER, value: ::Regexp.last_match(1).to_i }; sql = ::Regexp.last_match.post_match }, # Tokenize numbers
      /\A(\*)/ => -> { tokens << { type: :ASTERISK, value: '*' }; sql = ::Regexp.last_match.post_match }, # Tokenize asterisks
      /\A(=)/ => -> { tokens << { type: :EQUALS, value: '=' }; sql = ::Regexp.last_match.post_match }, # Tokenize equals sign
      /\A(,)/ => -> { tokens << { type: :COMMA, value: ',' }; sql = ::Regexp.last_match.post_match }, # Tokenize commas
      /\A(\()/ => -> { tokens << { type: :LPAREN, value: '(' }; sql = ::Regexp.last_match.post_match }, # Tokenize left parentheses
      /\A(\))/ => -> { tokens << { type: :RPAREN, value: ')' }; sql = ::Regexp.last_match.post_match }, # Tokenize right parentheses
      /\A(;)/ => -> { tokens << { type: :SEMICOLON, value: ';' }; sql = ::Regexp.last_match.post_match }, # Tokenize semicolons
      /\A([a-zA-Z_][a-zA-Z0-9_]*)/ => -> {
        word = ::Regexp.last_match(1).upcase
        tokens << if KEYWORDS.include?(word)
                    { type: :KEYWORD, value: word }
                  else
                    { type: :IDENTIFIER, value: ::Regexp.last_match(1) }
                  end
        sql = ::Regexp.last_match.post_match
      } # Tokenize keywords and identifiers
    }

    until sql.empty?
      # Skip whitespace
      if sql =~ /\A\s+/
        sql = ::Regexp.last_match.post_match
        next
      end

      matched = false
      token_patterns.each do |pattern, action|
        next unless sql =~ pattern

        action.call
        matched = true
        break
      end

      raise "Unrecognized token: #{sql}" unless matched

      sql = sql.strip
    end

    tokens
  end
end
