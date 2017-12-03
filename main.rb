# set :environment, :production
require 'sinatra'
require 'bcrypt'
require 'sqlite3'
require 'zip'
require 'csv'
require 'sequel'
require 'fileutils'

enable :sessions

fsub = {}
pos = Array.new
$first = true

database = SQLite3::Database.new("database/UserData.database")
database.execute("CREATE TABLE IF NOT EXISTS UserData (
                            id STRING   PRIMARY KEY,
                            username    STRING UNIQUE,
                            password    STRING,
                            role        INTEGER,
                            vote1       STRING,
                            vote2       STRING,
                            vote3       STRING);")

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

  def not_voted1?
    if session[:voted1] == "nil"
      return true
    else
      return false
    end
  end

  def not_voted2?
    if session[:voted2] == "nil"
      return true
    else
      return false
    end
  end

  def not_voted3?
    if session[:voted3] == "nil"
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
  if params[:username].to_s.empty? or params[:password].to_s.empty?
    @error = "Username or Password have to be filled"
    return erb :signup
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
    database.execute("INSERT INTO UserData VALUES(?,?,?,?,?,?,?)", pw_salt, params[:username], pw_hash, role, "nil", "nil", "nil")
  rescue SQLite3::ConstraintException
    @error = "Username already taken"
    return erb :signup
  else
    @user = params[:username]
    session[:username] = params[:username]
    session[:id] = role
    session[:voted1] = "nil"
    session[:voted2] = "nil"
    session[:voted3] = "nil"

    return erb :HomePage
  end
end

get '/login' do
  erb :login
end

post '/login' do
  name = database.execute("SELECT username FROM UserData WHERE username=?", params[:username])
  if params[:username].to_s.empty? or params[:password].to_s.empty?
    @error = "Enter Username and Password"
    return erb :login
    else if name.empty?
           @error = "Incorrect Username or Password"
           return erb :login
         else
           pw_db = database.execute("SELECT password FROM UserData WHERE username=?", params[:username])
           salt_db = database.execute("SELECT id FROM UserData WHERE username=?", params[:username])
           role = database.execute("SELECT role FROM UserData WHERE username=?", params[:username])
           vote = database.execute("SELECT vote1,vote2,vote3 FROM UserData WHERE username=?", params[:username])
           if pw_db[0][0] == BCrypt::Engine.hash_secret(params[:password], salt_db[0][0])
             session[:username] = params[:username]
             session[:id] = role[0][0]
             session[:voted1] = vote[0][0]
             session[:voted2] = vote[0][1]
             session[:voted3] = vote[0][2]
             @user = params[:username]
             return erb :HomePage
           else
             @error = "Incorrect Username or Password"
             return erb :login
           end
         end
  end
end

get '/logout' do
  session[:username] = nil
  session[:id] = nil
  session[:voted1] = nil
  session[:voted2] = nil
  session[:voted3] = nil
  redirect '/'
end

get '/submissions' do
  i = 0
  begin
    Dir.chdir('public/content/')
    Dir.glob('*').select do |f|
      File.directory? f
      fsub[i] = {
          :id => f,
          :score => 0
      }
      pos << i
      i += 1
    end
  rescue
      puts ""
  end
  order = 1 + rand(fsub.length) # try to randomize, not working yet

  if session[:username].nil?
    @error = "You need to sign up to view submissions"
    return erb :signup
  else if $first
    $displayArr = Array.new(i) { Array.new(4) }
    i -= 1
    while i != -1 do
      $displayArr[i][0] = "view/" + fsub[i].values[0].to_s
      $displayArr[i][1] = fsub[i].values[0]
      $displayArr[i][2] = fsub[i].values[1]
      i -= 1
    end
    $first = false
    @item = $displayArr
    return erb :Vote
  else
    @item = $displayArr
    return erb :Vote
       end
  end
end

post '/submissions' do
  if params.values[0] == '1'
    database.execute("UPDATE UserData SET vote1=? WHERE username=?", params[:name], session[:username])
    session[:voted1] = params[:name]
    row = $displayArr.detect{|aa| aa.include?(params[:name].to_s)}
    pair =  [row.index(params[:name]), $displayArr.index(row)]

    if fsub.values[pair[1]][:id] == params[:name]
      fsub.values[pair[1]][:score] += 3
      $displayArr[pair[1]][2] += 3
    end
  end
  if params.values[0] == '2'
    database.execute("UPDATE UserData SET vote2=? WHERE username=?", params[:name], session[:username])
    session[:voted2] = params[:name]
    row = $displayArr.detect{|aa| aa.include?(params[:name].to_s)}
    pair =  [row.index(params[:name]), $displayArr.index(row)]

    if fsub.values[pair[1]][:id] == params[:name]
      fsub.values[pair[1]][:score] += 2
      $displayArr[pair[1]][2] += 2
    end
  end
  if params.values[0] == '3'
    database.execute("UPDATE UserData SET vote3=? WHERE username=?", params[:name], session[:username])
    session[:voted3] = params[:name]
    row = $displayArr.detect{|aa| aa.include?(params[:name].to_s)}
    pair =  [row.index(params[:name]), $displayArr.index(row)]

    if fsub.values[pair[1]][:id] == params[:name]
      fsub.values[pair[1]][:score] += 1
      $displayArr[pair[1]][2] += 1
    end
  end
  @item = $displayArr
  return erb :Vote
end

get '/view/:id' do |id|
  send_file "public/content/#{id}/index.html"
end

get '/upload' do
  erb :upload
end

post '/upload' do
  begin
    if params['myFile'][:type] == "application/vnd.ms-excel"
      fname = 'public/uploads/CSV/' + params['myFile'][:filename]

      File.open(fname, "w") do |f|
        f.write(params['myFile'][:tempfile].read)
      end

      # CSV Row Format:  strArr[i] => ['Username', 'Password', 'Role #']
      strArr = CSV.read fname

      database.execute("DELETE FROM Userdata")

      # Add all elements from CSV to Database. Make sure that .csv file does not
      # Contain blank spaces!
      strArr.each do |s|
        pw_salt = BCrypt::Engine.generate_salt
        pw_hash = BCrypt::Engine.hash_secret(s[1], pw_salt)
        database.execute("INSERT INTO UserData VALUES(?,?,?,?,?,?,?)", pw_salt,
                         s[0], pw_hash, s[2], "nil", "nil", "nil")
      end

      @uploaded = "CSV File Successfully Uploaded"
    end
    if params['myFile'][:type] == "application/octet-stream"
      corrupt = true
      File.open('public/uploads/ZIP/' + params['myFile'][:filename], "w") do |f|
        f.write(params['myFile'][:tempfile].read)
      end

      Zip::File.open('public/uploads/ZIP/' + params['myFile'][:filename]) { |zip_file|
        zip_file.each { |f|
          f_path = File.join('public/content', f.name)
          FileUtils.mkdir_p(File.dirname(f_path))
          zip_file.extract(f, f_path) unless File.exist?(f_path)
          corrupt = false
        }
      }
      if corrupt
        @uploaded = "ZIP File Corrupt"
      else
        @uploaded = "ZIP File Successfully Uploaded"
      end
    else
      @uploaded = "No File"
    end
  rescue
    @uploaded = "Upload Valid File Type (.csv or .zip)"
  end
  return erb :upload
end

get '/report' do
  @arr = database.execute("SELECT username,vote1,vote2,vote3 FROM UserData WHERE role NOT LIKE 2")
  return erb :report
end

post '/report' do
  items = database.execute("SELECT username,password,role FROM UserData")
  FileUtils.mkdir_p('/uploads/CSV/') unless File.exists?('/uploads/CSV/')
  File.open(File.join('public/uploads/CSV/', 'data.csv'), 'w') do |f|
    items.each do |data|
      f << data.to_csv(:force_quotes => true, :skip_blanks => true).gsub('\r\n', '\n')
    end
  end

  send_file'public/uploads/CSV/data.csv', :type => 'application/csv', :disposition => 'attachment'
end