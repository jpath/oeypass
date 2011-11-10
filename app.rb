# myapp.rb
require 'sinatra'
require 'dm-core'
require 'dm-migrations'
require 'dm-timestamps'
require 'haml'

# MODELS
class Student
  include DataMapper::Resource
  property :id,         Serial
  property :name,       String
  property :email,      String
  property :pass_type,  String
  property :class_qty,  Integer
  property :month_qty,  Integer
  property :created_on, Date
  property :updated_on,  Date

  has n, :visits
  def remaining_classes
  end
  def pass_expiry
  end
end

class Visit
  include DataMapper::Resource
  property :id,         Serial
  property :created_at, DateTime

  belongs_to :student
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
  DataMapper.logger.debug(params.inspect)
  @students = Student.all
  haml :students
end

post '/pass' do
  DataMapper.logger.debug(params.inspect)
  @student = Student.create(:name => params[:name], :email => params[:email]) 
  redirect '/students'
end

