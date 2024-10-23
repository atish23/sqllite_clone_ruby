class CodeGenerator
  def generate(ast)
    case ast[:type]
    when :select
      generate_select(ast)
    when :insert
      generate_insert(ast)
    when :create_table
      generate_create_table(ast)
    else
      raise "Unknown AST node: #{ast[:type]}"
    end
  end

  private

  def generate_select(ast)
    instructions = []
    instructions << { op: :OpenRead, table: ast[:table] }
    instructions << { op: :Column, columns: ast[:columns] }
    instructions << { op: :ResultRow }
    instructions << { op: :Close }
    puts instructions
    instructions
  end


  def generate_insert(ast)
    instructions = []
    instructions << { op: :OpenWrite, table: ast[:table] }
    instructions << { op: :Insert, columns: ast[:columns], values: ast[:values] }
    instructions << { op: :Close }
    instructions
  end

  def generate_create_table(ast)
    instructions = []
    instructions << { op: :CreateTable, table: ast[:table], columns: ast[:columns] }
    instructions
  end
end
