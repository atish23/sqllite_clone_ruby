class VDBE
  def initialize
    require_relative '../backend/btree'
    @btree = BTree.new
  end

  def execute(instructions)
    result = []
    puts "VDBE Instructions: #{instructions}"
    instructions.each do |instruction|
      case instruction[:op]
      when :CreateTable
        @btree.create_table(instruction[:table], instruction[:columns])
        result << "Table '#{instruction[:table]}' created successfully."
      when :OpenRead
        @btree.open(instruction[:table], mode: :read)
      when :OpenWrite
        @btree.open(instruction[:table], mode: :write)
      when :Column
        @columns = instruction[:columns]
      when :ResultRow
        rows = @btree.select(@columns)
        rows.each do |row|
          result << row.join(' | ')
        end
      when :Insert
        @btree.insert(instruction[:columns], instruction[:values])
        result << 'Record inserted successfully.'
      when :Close
        @btree.close
      else
        raise "Unknown opcode: #{instruction[:op]}"
      end
    end
    result.join("\n")
  end
end
