# set :environment, :production
require 'sinatra'
require 'bcrypt' # for password encryption
# require 'data_mapper' # Not used yet, cant get DB to work on my local
require './database_accessor.rb'

enable :sessions

# temp array to act as db for my testing
temp_db = {}
vote = 0

helpers do

  def login?
    if session[:username].nil? # probably will change session id to an actual id instead of username when db is up
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

get '/signup' do
  erb :signup
end

post '/signup' do
  # More validation will be needed (especially for DB usage)
  # this only posts username and password to the homepage, we will need to store in db
  if params[:username].to_s.empty? or params[:password].to_s.empty?
    @error = "Username or Password have to be filled"
    erb :signup
  else
    pw_salt = BCrypt::Engine.generate_salt
    pw_hash = BCrypt::Engine.hash_secret(params[:password], pw_salt)

    temp_db[params[:username]] = {
        :salt => pw_salt,
        :hash => pw_hash
    }

    print temp_db

    @user = params[:username]
    @password = pw_hash
    session[:username] = params[:username]

    erb :HomePage
  end
end

get '/login' do
  erb :login
end

post '/login' do
  if params[:username].to_s.empty? or params[:password].to_s.empty?
    @error = "Enter Username and Password"
    erb :login
  else if temp_db.has_key?(params[:username])
         user = temp_db[params[:username]]
         if user[:hash] == BCrypt::Engine.hash_secret(params[:password], user[:salt])
           session[:username] = params[:username]
           @user = params[:username]
           erb :HomePage
         end
       else
         @error = "Incorrect Username or Password"
         erb :login
       end
  end
end

get '/logout' do
  session[:username] = nil
  redirect '/'
end

get '/submissions' do
  @item = "test"
  @value = 0
  erb :Vote
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