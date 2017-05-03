require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord

  # define the table name based on the class name
  def self.table_name
    self.to_s.downcase.pluralize
  end

  # returns all of our column names in an array
  def self.column_names
    # get the table column info (names) as a hash
    DB[:conn].results_as_hash = true
    sql = "PRAGMA table_info('#{table_name}')"
    table_info = DB[:conn].execute(sql)

    # place the column names into an array
    column_names = []
    table_info.each do |column|
      column_names << column["name"]
    end
    # remove any nil column names
    column_names.compact
  end

  # returns the table name for an instance
  def table_name_for_insert
    self.class.table_name
  end

  # initialize our object
  def initialize(options={})
    options.each do |property, value|
      self.send("#{property}=", value)
    end
  end

  # returns the column names (minus ID) in a comma seperated format
  def col_names_for_insert
    self.class.column_names.delete_if { |col| col == "id" }.join(", ")
  end

  # returns the instance values in a comma separated format
  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    values.join(", ")
  end

  def save
    sql = <<-SQL
      INSERT INTO #{table_name_for_insert} (#{col_names_for_insert})
      VALUES (#{values_for_insert})
    SQL

    DB[:conn].execute(sql)

    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def self.find_by_name(name)
    sql = <<-SQL
      SELECT * FROM #{self.table_name}
      WHERE name = '#{name}'
    SQL

    DB[:conn].execute(sql)
  end

  def self.find_by(attribute)
    sql = <<-SQL
      SELECT * FROM #{self.table_name}
      WHERE #{attribute.keys[0].to_s} = "#{attribute.values[0]}"
    SQL

    DB[:conn].execute(sql)
  end

end
