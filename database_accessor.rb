# Design and implement functions which access, add to, or remove data from
# a database.

require 'dm-core'
require 'dm-timestamps'
require 'dm-validations'
require 'dm-migrations'
require 'csv'

# This sets up the database each time the program is run.
class User
  include DataMapper::Resource

  property :id       , Serial
  property :username , String
  property :password , String
  property :role     , String
end

# Adds a single entry given a username and password.  Note that
# the method will return true if the addition was successful
# and false if it was not.
def AddEntry(username, password, role)
  user = User.new username: username, password: password, role: role
  user.save
end

# Adds username and password entries from CSV file to database.  Note
# that the CSV needs to be in proper format, consisting of
# two columns.  Add to existing indicates whether entries should be
# added to the database (TRUE) or if they should overwrite existing
# data (FALSE)
def AddEntriesFromCSV(filename = 'database/exampleDBSource.csv', addToExisting)
  DataMapper.auto_migrate! unless addToExisting

  strArr = CSV.read filename

  strArr.each do |s|
    AddEntry s[0], s[1], s[2]
  end
end

# Returns a two-element array with the username as the first element
# and the password as the second.  NOTE THAT 1 IS THE FIRST INDEX OF
# DATABASE ENTRIES, NOT 0!
def AccessEntry(index)
  [User.get(index).username, User.get(index).password, User.get(index).role]
end

# Returns a string array with size [N, 2] containing all N elements in
# the database.
def AccessAll()
  strArray = []

  User.all.each_with_index do |s, i|
    strArray[i] = [s.username, s.password, s.role]
  end

  strArray
end

# Debugging function only.
def PrintTable(twoDArray)
  twoDArray.each_with_index do |s, i|
    s.each_with_index do |t, j|
      print "#{t}, "
    end
    puts
  end
end

def Data_Mapper_Setup(dbfilename = 'database\uname_pwd.db')
  DataMapper.setup :default, "sqlite://#{Dir.pwd}/#{dbfilename}"
end

if __FILE__ == $0
  # TODO: your implementation of the following
  # sqlite://#{Dir.pwd}/[YOUR DATABASE NAME HERE]
  Data_Mapper_Setup()

  # auto_migrate clears existing data, while auto_upgrade sets up the
  # table so that data is added.
  DataMapper.auto_upgrade!

  # Insert your .csv filename as an argument.
  AddEntriesFromCSV(false)

  strArr = AccessAll()
  # puts "Dim 0.size = #{strArr.size}, Dim 1.size = #{strArr[0].size}"
  PrintTable strArr
end