# set :environment, :production
require 'sinatra'
require 'bcrypt'
require 'sqlite3'
require 'zip'
require 'csv'
require 'sequel'
# require 'FileUtils'

enable :sessions

vote = 0

database = SQLite3::Database.new("database/UserData.database")
database.execute("CREATE TABLE IF NOT EXISTS UserData (
                            id STRING   PRIMARY KEY,
                            username    STRING UNIQUE,
                            password    STRING,
                            role        INTEGER,
                            voteID      STRING);")

helpers do

  def login?
    if session[:username].nil?
      return false
    else
      return true
    end
  end

  def admin?
    if session[:id] == 2
      return true
    else
      return false
    end
  end

  def not_voted?
    print session[:voted]
    if session[:voted] == "nil"
      return true
    else
      return false
    end
  end

  def username
    return session[:username]
  end

end

get '/' do
  @user = session[:username]
  erb :HomePage
end

post '/' do
  erb :HomePage
end

get '/signup' do
  erb :signup
end

post '/signup' do
  # More validation will be needed (especially for DB usage)
  if params[:username].to_s.empty? or params[:password].to_s.empty?
    @error = "Username or Password have to be filled"
    erb :signup
  else
    pw_salt = BCrypt::Engine.generate_salt
    pw_hash = BCrypt::Engine.hash_secret(params[:password], pw_salt)
  end

  if params[:role] == 'on'
    role = 2
  else
    role = 1
  end

  begin
    database.execute("INSERT INTO UserData VALUES(?,?,?,?,?)", pw_salt, params[:username], pw_hash, role, "nil")
  rescue SQLite3::ConstraintException
    @error = "Username already taken"
    erb :signup
  else
    @user = params[:username]
    session[:username] = params[:username]
    session[:id] = role
    session[:voted] = "nil"

    erb :HomePage
  end
end

get '/login' do
  erb :login
end

post '/login' do
  name = database.execute("SELECT username FROM UserData WHERE username=?", params[:username])
  if params[:username].to_s.empty? or params[:password].to_s.empty?
    @error = "Enter Username and Password"
    erb :login
    else if name.empty?
           @error = "Incorrect Username or Password"
           erb :login
         else
           pw_db = database.execute("SELECT password FROM UserData WHERE username=?", params[:username])
           salt_db = database.execute("SELECT id FROM UserData WHERE username=?", params[:username])
           role = database.execute("SELECT role FROM UserData WHERE username=?", params[:username])
           vote = database.execute("SELECT voteID FROM UserData WHERE username=?", params[:username])
           if pw_db[0][0] == BCrypt::Engine.hash_secret(params[:password], salt_db[0][0])
             session[:username] = params[:username]
             session[:id] = role[0][0]
             session[:voted] = vote
             @user = params[:username]
             erb :HomePage
           else
             @error = "Incorrect Username or Password"
             erb :login
           end
         end
  end
end

get '/logout' do
  session[:username] = nil
  session[:id] = nil
  redirect '/'
end

get '/submissions' do
  if session[:username].nil?
    @error = "You need to sign up to view submissions"
    erb :signup
  else
    @item = "test"
    @value = 0
    @voteID = "TEST ID NEED TO BE RANDOM" # needs to be random/sequential for each website
    erb :Vote
  end
end

post '/submissions' do
  if params.keys[0] == 'up'
    vote = vote + 1
    database.execute("UPDATE UserData SET voteID=? WHERE username=?", params[:up], session[:username])
    session[:voted] = params[:up]
  end
  @value = vote
  @item = "test"
  @voteID = "TEST ID NEED TO BE RANDOM"
  erb :Vote
end

get '/test' do
  # send_file File.read('\content\bootstrap project\bootstrap.html')
  send_file 'public/content/bootstrap project/bootstrap.html'
end

get '/upload' do
  erb :upload
end

post '/upload' do
  if params['myFile'][:type] == "application/vnd.ms-excel"
    fname = 'public/uploads/CSV/' + params['myFile'][:filename]

    File.open(fname, "w") do |f|
      f.write(params['myFile'][:tempfile].read)
    end
    # BEGIN CODING CHANGES -----------------------------------------------------
    # CSV Row Format:  strArr[i] => ['Username', 'Password', 'Role #']

    strArr = CSV.read fname

    database.execute("DELETE FROM Userdata")

    # Add all elements from CSV to Database. Make sure that .csv file does not
    # Contain blank spaces!
    strArr.each do |s|
      pw_salt = BCrypt::Engine.generate_salt
      pw_hash = BCrypt::Engine.hash_secret(s[1], pw_salt)
      database.execute("INSERT INTO UserData VALUES(?,?,?,?,?)", pw_salt,
                       s[0], pw_hash, s[2], "nil")
    end
    # END CODING CHANGES -------------------------------------------------------

    @uploaded = "CSV File Successfully Uploaded"
  end
  if params['myFile'][:type] == "application/octet-stream"
    File.open('public/uploads/ZIP/' + params['myFile'][:filename], "w") do |f|
      f.write(params['myFile'][:tempfile].read)
    end

    Zip::File.open('public/uploads/ZIP/' + params['myFile'][:filename]) { |zip_file|
      zip_file.each { |f|
        f_path=File.join("public/content", f.name)
        FileUtils.mkdir_p(File.dirname(f_path))
        zip_file.extract(f, f_path) unless File.exist?(f_path)
      }
    }
    @uploaded = "ZIP File Successfully Uploaded"
  end
  erb :upload
end

get '/report' do
  @arr = database.execute("SELECT username,voteID FROM UserData WHERE role NOT LIKE 2")
  erb :report
end

post '/report' do
  items = database.execute("SELECT username,password,role FROM UserData")
  File.open('public/uploads/CSV/data.csv', 'w') do |f|
    items.each do |data|
      f << data.to_csv(:force_quotes => true, :skip_blanks => true).gsub('\r\n', '\n')
    end
  end

  send_file'public/uploads/CSV/data.csv', :type => 'application/csv', :disposition => 'attachment'
end