require 'fileutils'

class Pager
  PAGE_SIZE = 4096  # 4KB per page
  HEADER_SIZE = 128 # Size for storing metadata

  attr_reader :schema, :table_name

  def initialize(table_name, mode)
    @table_name = table_name
    @mode = mode
    @dir_path = "data/#{table_name}"
    @meta_file_path = "#{@dir_path}/metadata.meta"

    unless Dir.exist?(@dir_path) && File.exist?(@meta_file_path)
      raise "Table '#{table_name}' does not exist."
    end

    @schema = Marshal.load(File.read(@meta_file_path))
    @node_counter = last_node_reference  # Initialize node counter

    if File.exist?(root_ref_file_path)
      @root_node_ref = load_root_node_ref
    else
      # If the root node reference doesn't exist yet, and we're in write mode,
      # we'll create it later during table creation
      if @mode == :write
        @root_node_ref = nil
      else
        raise "Root node reference not found."
      end
    end
  end

  def self.create_table(table_name, columns)
    dir = "data/#{table_name}"
    FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
    meta_file_path = "#{dir}/metadata.meta"

    if File.exist?(meta_file_path)
      raise "Table '#{table_name}' already exists."
    end

    # Save schema to metadata file
    File.write(meta_file_path, Marshal.dump(columns))

    # Create an instance of Pager in write mode
    pager = Pager.new(table_name, :write)

    # Initialize root node
    root_node = BTreeNode.new(true)
    root_node_ref = pager.generate_node_reference

    # Save the root node
    pager.write_node(root_node_ref, root_node)

    # Save root node reference
    pager.save_root_node_ref(root_node_ref)

    # Update the pager's root node reference
    pager.instance_variable_set(:@root_node_ref, root_node_ref)
  end

  def insert_btree(record)
    @root_node = load_node(@root_node_ref)
    puts "Inserting record: #{record}"
    puts "Root node: #{@root_node}"
    result = insert_into_btree(@root_node, record)
    puts "Result: #{result}"
    if result.is_a?(SplitResult)
      # Root node was split, create a new root
      new_root = BTreeNode.new(false)
      new_root.keys = [result.promoted_key]
      new_root.children = [result.left_ref, result.right_ref]
      @root_node_ref = generate_node_reference
      puts "New root node reference: #{@root_node_ref}"
      puts "New root node: #{new_root}"
      write_node(@root_node_ref, new_root)
      save_root_node_ref(@root_node_ref)
    else
      write_node(@root_node_ref, @root_node)
    end
  end

  def traverse_btree
    @root_node = load_node(@root_node_ref)
    puts @root_node.inspect
    traverse_node(@root_node)
  end

  def close
    # No open file handles to close in this implementation
  end

  def insert_into_btree(node, record)
    key = record[@schema.first[:name]]

    if node.is_leaf
      insert_key_into_node(node, record)
      if node.keys.size > (2 * BTree::DEGREE - 1)
        split_node(node)
      else
        node
      end
    else
      # Find the child to which the key should be added
      index = node.keys.find_index { |k| key < k[@schema.first[:name]] } || node.keys.size
      child_ref = node.children[index]
      child_node = load_node(child_ref)
      result = insert_into_btree(child_node, record)

      if result.is_a?(SplitResult)
        # Insert promoted key into current node
        node.keys.insert(index, result.promoted_key)
        node.children[index] = result.left_ref
        node.children.insert(index + 1, result.right_ref)

        if node.keys.size > (2 * BTree::DEGREE - 1)
          split_node(node)
        else
          write_node(child_ref, child_node)
          write_node(node_ref(node), node)
          node
        end
      else
        write_node(child_ref, child_node)
        node
      end
    end
  end

  def split_node(node)
    mid_index = node.keys.size / 2
    promoted_key = node.keys[mid_index]

    left_node = BTreeNode.new(node.is_leaf)
    left_node.keys = node.keys[0...mid_index]
    left_node.children = node.children[0..mid_index] unless node.is_leaf

    right_node = BTreeNode.new(node.is_leaf)
    right_node.keys = node.keys[(mid_index + 1)..]
    right_node.children = node.children[(mid_index + 1)..] unless node.is_leaf

    left_ref = generate_node_reference
    right_ref = generate_node_reference

    write_node(left_ref, left_node)
    write_node(right_ref, right_node)

    SplitResult.new(promoted_key, left_ref, right_ref)
  end

  def insert_key_into_node(node, record)
    key = record[@schema.first[:name]]
    index = node.keys.find_index { |k| key < k[@schema.first[:name]] } || node.keys.size
    node.keys.insert(index, record)
  end

  def traverse_node(node)
    records = []
    if node.is_leaf
      records += node.keys
    else
      node.children.each_with_index do |child_ref, index|
        child_node = load_node(child_ref)
        records += traverse_node(child_node)
        records << node.keys[index] if index < node.keys.size
      end
    end
    puts "Traversing node #{node}: #{records}"
    records
  end

  def generate_node_reference
    @node_counter ||= last_node_reference
    @node_counter += 1
  end

  def node_ref(node)
    @node_refs ||= {}
    @node_refs[node.object_id]
  end


  def write_node(node_ref, node)
    node_data = Marshal.dump(node)
    puts "Writing node #{node_ref}: #{node_data}"
    File.write(node_file_path(node_ref), node_data)
    @node_refs ||= {}
    @node_refs[node.object_id] = node_ref
  end

  def load_node(node_ref)
    node_data = File.read(node_file_path(node_ref))
    Marshal.load(node_data)
  end

  def node_file_path(node_ref)
    "#{@dir_path}/node_#{node_ref}.nd"
  end

  def last_node_reference
    node_files = Dir.glob("#{@dir_path}/node_*.nd")
    refs = node_files.map { |f| f.match(/node_(\d+)\.nd$/)[1].to_i }
    refs.max || 0
  end

  def save_root_node_ref(ref)
    File.write(root_ref_file_path, ref.to_s)
  end

  def load_root_node_ref
    if File.exist?(root_ref_file_path)
      File.read(root_ref_file_path).to_i
    else
      raise "Root node reference not found."
    end
  end

  def root_ref_file_path
    "#{@dir_path}/root.ref"
  end
  private

  class BTreeNode
    attr_accessor :keys, :children, :is_leaf

    def initialize(is_leaf)
      @is_leaf = is_leaf
      @keys = []
      @children = []
    end
  end

  class SplitResult
    attr_accessor :promoted_key, :left_ref, :right_ref

    def initialize(promoted_key, left_ref, right_ref)
      @promoted_key = promoted_key
      @left_ref = left_ref
      @right_ref = right_ref
    end
  end

end
