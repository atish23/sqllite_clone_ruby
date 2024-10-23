class SQLCommandProcessor
  def initialize
    require_relative '../compiler/tokenizer'
    require_relative '../compiler/parser'
    require_relative '../compiler/code_generator'
    require_relative 'vdbe'
  end

  def execute(sql)
    tokens = Tokenizer.new.tokenize(sql)
    return if tokens.empty?

    ast = Parser.new.parse(tokens)
    instructions = CodeGenerator.new.generate(ast)

    vdbe = VDBE.new
    vdbe.execute(instructions)
  rescue StandardError => e
    "Error: #{e.message}"
  end
end
