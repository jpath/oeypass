# myapp.rb
require 'sinatra'
require 'data_mapper'
require 'haml'

# MODELS
class Student
  include DataMapper::Resource
  property :id,         Serial
  property :name,       String
  property :email,      String
  property :pass_type,  String
  property :quantity,   String
end

# CONFIGURATION
configure :development do
  DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/db/development.db")
  DataMapper::Logger.new(STDOUT, :debug)
  DataMapper.auto_migrate!
end

get '/' do
  haml :index
end

get '/students' do
  @students = Student.all
  haml :students
end

post '/pass' do
  puts params
  @student = Student.create(:name => params[:name], :email => params[:email]) 
  redirect '/students'
end

