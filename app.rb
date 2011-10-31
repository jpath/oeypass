# myapp.rb
require 'sinatra'
require 'data_mapper'
require 'haml'

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

class Student
  include DataMapper::Resource
  property :id,       Serial
  property :name,     String
  property :email,     String
  property :pass_type, String
  property :quantity, String
end

