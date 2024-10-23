class BTree
  DEGREE = 2  # Minimum degree (defines the range for number of keys)

  def initialize
    require_relative 'pager'
  end

  def create_table(table_name, columns)
    Pager.create_table(table_name, columns)
  end

  def open(table_name, mode:)
    puts "Opening table '#{table_name}' in #{mode} mode."
    @pager = Pager.new(table_name, mode)
    puts "@pager: #{@pager.schema}"
    @schema = @pager.schema
  end

  def insert(columns, values)
    raise 'Column count does not match value count.' if columns.size != values.size

    # Ensure columns exist in the table schema
    columns.each do |col|
      raise "Unknown column '#{col}' in table '#{@pager.table_name}'." unless @schema.any? { |c| c[:name] == col }
    end

    record = Hash[columns.zip(values)]
    @pager.insert_btree(record)
  end

  def select(columns)
    # Handle '*' (select all columns)
    columns = @schema.map { |col| col[:name] } if columns == ['*']

    # Ensure requested columns exist
    columns.each do |col|
      raise "Unknown column '#{col}' in table '#{@pager.table_name}'." unless @schema.any? { |c| c[:name] == col }
    end

    records = @pager.traverse_btree
    records.map { |record| columns.map { |col| record[col].to_s } }
  end

  def close
    @pager&.close
  end
end
