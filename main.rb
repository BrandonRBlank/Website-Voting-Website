# set :environment, :production
require 'sinatra'
require 'bcrypt'
require 'sqlite3'

enable :sessions

vote = 0

database = SQLite3::Database.new("database/UserData.database")
database.execute("CREATE TABLE IF NOT EXISTS UserData (
                            id STRING PRIMARY KEY,
                            username STRING UNIQUE,
                            password STRING,
                            role INTEGER);")

helpers do

  def login?
    if session[:username].nil?
      return false
    else
      return true
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
  File.open('public/uploads/' + params['myFile'][:filename], "w") do |f|
    f.write(params['myFile'][:tempfile].read)
  end
  @uploaded = "File successfully uploaded"
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

  begin
    database.execute("INSERT INTO UserData VALUES(?,?,?,?)", pw_salt, params[:username], pw_hash, "0")
  rescue SQLite3::ConstraintException
    @error = "Username already taken"
    erb :signup
  else
    @user = params[:username]
    session[:username] = params[:username]

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
           if pw_db[0][0] == BCrypt::Engine.hash_secret(params[:password], salt_db[0][0])
             session[:username] = params[:username]
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
  redirect '/'
end

get '/submissions' do
  if session[:username].nil?
    @error = "You need to sign up to view submissions"
    erb :signup
  else
    @item = "test"
    @value = 0
    erb :Vote
  end
end

post '/submissions' do
  if params.keys[0] == 'up'
    vote = vote + params[:up].to_s.to_i
  end
  if params.keys[0] == 'down'
    vote = vote + params[:down].to_s.to_i
  end
  @value = vote
  @item = "test"
  erb :Vote
end

get '/test' do
  # send_file File.read('\content\bootstrap project\bootstrap.html')
  send_file '\content\bootstrap project\bootstrap.html'
end