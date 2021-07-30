require_relative "../config/environment.rb"
require 'active_support/inflector'

class Song

  # returns a string which is the current class name but warped into suitable table name format
  def self.table_name
    self.to_s.downcase.pluralize
  end

  # returns an array of column names from a given table (table was created found by using class' name)
  def self.column_names
    DB[:conn].results_as_hash = true
    # create a sql query command which retrieves some relevant data for each column in a given table. Stores that rele
    # -vant data as a hash and all those hashes are located in a single array. WIthin that relevant data however, is the
    # name  of the column which we need in order to crete attribute accessors for each column name
    sql = "pragma table_info('#{table_name}')"
    # execute that command and store the array of hashes in the table_info variable
    table_info = DB[:conn].execute(sql)
    # create an array with which we'll push in all column names after extracting them from table_info
    column_names = []
    # iterate through table_info (an array of hashes) and for each hash, shovel its name into column_names
    table_info.each do |row|
      column_names << row["name"]
    end
    # now, theres a possibility that during the .each iteration, a column might not have a name and therefore would have
    # a nil value. The compact method would remove all these from our array before returning it
    column_names.compact
  end
  # creates an attribute accessor for each column name(column_names was an array of strings which represent column names)
  self.column_names.each do |col_name|
    # the .to_sym method converts a string into a symbol. ("tag".to_sym returns :tag)
    attr_accessor col_name.to_sym
  end

  def initialize(options={})
  # when initialized, options will have key/value pairs. We want to use tose key/value pairs to set values of attributes
  # so for each option, use the .send method to set value of interpolated key
    options.each do |property, value|
      self.send("#{property}=", value)
    end
  end

  # now, to create an instance variable for saving a created object.
  def save
    # usually command would look like:-
    # sql = INSERT INTO songs (name, album) VALUES ("Stronger", "Graduation")
    # but instead, we want to abstract that and get the current class name. That requires a method which acesses the class
    # table name. Also we want to fill in the first set of parentheses with parameters. These parameters are where the 
    # arguments are set in the second set of parentheses
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def table_name_for_insert
    self.class.table_name
  end

  # the goal of this method is to extract all the values for each column name (column names also happens to be the class 
  # attributes) 
  def values_for_insert
    # create an array which will store all the values (which should be be strings separated by commas)
    values = []
    # get column names and use each column name to access its actual value. We need that value in order to save that ins-
    # tance into database.
    #  send, when used with one argument apparently takes that column name(attribute) and returns the value it holds. We th
    # en shovel that value into the values array. NOw, if an attributes value is nil, we dont want that value to be part of 
    # our values array
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    # after getting all our values, we want to join them and make one big comma separated string
    values.join(", ")
  end

  # the goal of this method is to create a string of parameters for which arguments will be placed and further an object
  # would use tat info to create a row in the given table
  def col_names_for_insert
    # delete the column name which represents the ids. that would not be needed. Then, we want to combine all column names
    # with the use of join(", ")
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

end



