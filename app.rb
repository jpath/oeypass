# myapp.rb
require 'sinatra'
require 'dm-core'
require 'dm-migrations'
require 'dm-timestamps'
require 'dm-validations'
require 'dm-types'
require 'active_support/core_ext/numeric/time'
require 'haml'

# MODELS
class Student
  include DataMapper::Resource
  property :id,         Serial
  property :name,       String, :required => true
  property :email,      String, :required => true
  property :pass_type,  String
  property :class_qty,  Enum[1, 5, 10]
  property :month_qty,  Enum[1, 3, 6]
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

