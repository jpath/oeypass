# app.rb
require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'dm-migrations'
require 'dm-timestamps'
require 'dm-validations'
require 'dm-types'
require 'dm-sqlite-adapter'

# Latest version has bug: eg. Time.now - 1.days raises Date#advance NoMethodError
gem 'activesupport', "= 3.0.5"
#require 'active_support/core_ext/numeric/time'
require 'active_support/all' # Need this instead of previous for months() method to work 
require 'haml'

# MODELS
class Student
  include DataMapper::Resource
  property :id,         Serial
  property :name,       String, :required => true
  property :email,      String, :required => true
  property :pass_type,  Enum['monthly', 'class_package', 'intro']
  property :class_qty,  Enum[1, 5, 10]
  property :month_qty,  Enum[1, 3, 6]
  property :created_on, Date
  property :updated_on, Date

  validates_presence_of :class_qty, :if => lambda {|s| s.pass_type == 'class_package'}
  validates_presence_of :month_qty, :if => lambda {|s| s.pass_type == 'monthly'}

  has n, :visits

  def remaining_classes
    return "n/a" if pass_type != "class_package"
    class_qty - visits.size
  end

  def pass_expiry
    return "n/a" if pass_type != "monthly"
    created_on + month_qty.to_i.months
  end
end

class Visit
  include DataMapper::Resource
  property :id,         Serial
  property :created_at, DateTime

  belongs_to :student
end

enable :sessions

# CONFIGURATION
configure :development do
  DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/db/development.db")
  DataMapper::Logger.new(STDOUT, :debug)
  DataMapper.auto_migrate!
end

configure :production do
  DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/db/production.db")
  DataMapper::Logger.new(STDOUT, :debug)
  DataMapper.auto_upgrade!
end

before do
  @errors = session.delete :errors
end

get '/' do
  haml :index
end

get '/students' do
  @students = Student.all
  haml :students
end

post '/pass' do
  DataMapper.logger.debug(params.inspect)
  @student = Student.create(:name => params[:name], :email => params[:email],
                           :pass_type => params[:pass_type], :class_qty => params[:class_qty],
                           :month_qty => params[:month_qty]) 
  if @student.saved?
    redirect '/students'
  else
    session[:errors] = @student.errors.values.map{|e| e.to_s}
    redirect '/'
  end
end

post '/visit' do
  @visit = Visit.create(:student_id => params[:student_id])
  if @visit.saved?
    redirect '/students'
  else
    session[:errors] = @visit.errors.values.map{|e| e.to_s}
    redirect '/students'
  end
end

get '/student/:id' do
  @student = Student.get(params[:id])
  haml :student
end
