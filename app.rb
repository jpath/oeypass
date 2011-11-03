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
  DataMapper.setup(:default, 'sqlite3://home/jhughes/dev/oeypass/db/development.db')
end

get '/' do
  @students = Student.find(:all)
  haml :index
end

get '/pass' do
  haml :pass
end

post '/pass' do
  puts params
  Student.save
end

