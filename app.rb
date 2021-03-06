# app.rb
require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'dm-migrations'
require 'dm-timestamps'
require 'dm-validations'
require 'dm-types'
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
  property :email,      String, :required => true, :unique => true
  property :created_on, Date
  property :updated_on, Date


  has n, :visits
  has 1, :pass

  def visited_today?
    if most_recent_visit.nil?
      false
    else
      most_recent_visit.today?
    end
  end

  def most_recent_visit
    visits(:order => [:created_at.desc])[0]
  end
end

class Visit
  include DataMapper::Resource
  property :id,         Serial
  property :created_at, DateTime

  belongs_to :pass
  belongs_to :student

  def today?
    Time.now - created_at < 3.minutes
    #Time.now - created_at < 3.hours
    #false
  end
end

class Pass
  include DataMapper::Resource
  property :id,         Serial
  property :name,       String
  property :pass_type,  Enum['monthly', 'monthly_student', 'class_package', 'class_package_student', 'intro']
  property :class_qty,  Enum[1, 5, 10]
  property :month_qty,  Enum[1, 3, 6]
  property :created_on, Date
  property :updated_on, Date
  property :price,      Decimal

  validates_presence_of :pass_type
  validates_presence_of :class_qty, :if => lambda {|p| p.pass_type == 'class_package' || p.pass_type == 'class_package_student'}
  validates_presence_of :month_qty, :if => lambda {|p| p.pass_type == 'monthly' || p.pass_type == 'monthly_student'}

  belongs_to :student
  has n, :visits

  def remaining_classes
    return "n/a" unless (pass_type == "class_package" or pass_type == "class_package_student")
    class_qty - visits.size
  end

  def unlimited?
    pass_type == "monthly" or pass_type == "monthly_student" or pass_type == "intro"
  end

  def expiry
    return "n/a" unless unlimited?
    if pass_type == "monthly" || pass_type == "monthly_student"
      created_on + month_qty.to_i.months
    else # intro
      created_on + 2.weeks
    end
  end

  def days_left
    if unlimited?
      expiry - Date.today 
    end
  end

  def expires_soon?
    if unlimited?
      days_left < 7 && days_left > 0 
    end
  end

  def expired?
    if unlimited?
      days_left <= 0
    end
  end
end
# CONFIGURATION
enable :sessions
enable :method_override
configure :development do
  require 'dm-sqlite-adapter'
  #require 'ruby-debug/debugger'
  DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/db/development.db")
  DataMapper::Logger.new(STDOUT, :debug)
  DataMapper.auto_upgrade!
  #DataMapper.auto_migrate!
end

configure :production do
  require 'dm-postgres-adapter'
  DataMapper.setup(:default, ENV['DATABASE_URL'])
  DataMapper::Logger.new(STDOUT, :debug)
  DataMapper.auto_upgrade!
end

# FILTERS
before do
  @errors = session.delete :errors
end

# ROUTING
get '/' do
  haml :index
end

get '/students' do
  @students = Student.all(:order => [:name])
  haml :students
end

post '/pass' do
  DataMapper.logger.debug(params.inspect)
  @student = Student.create(:name => params[:name], :email => params[:email]) 
  @pass = Pass.new(:pass_type => params[:pass_type], :class_qty => params[:class_qty],
                   :month_qty => params[:month_qty], :price => params[:pass_price], :student_id => @student.id)
  @student.pass = @pass
  if @student.save
    redirect '/students'
  else
    session[:errors] = @student.errors.values.map{|e| e.to_s}
    session[:errors].concat(@pass.errors.values.map{|e| e.to_s})
    @student.destroy unless @student.nil?
    redirect '/'
  end
end

put '/pass' do
  @student = Student.get(params[:student_id])
  @pass = Pass.new(:pass_type => params[:pass_type], :class_qty => params[:class_qty],
                   :month_qty => params[:month_qty], :price => params[:pass_price], :student_id => @student.id)
  params.delete("_method")
  @student.pass.destroy
  @student.pass = @pass;

  if @student.save
    redirect "/student/#{@student.id}"
  else
    session[:errors] = @student.errors.values.map{|e| e.to_s}
    session[:errors].concat(@pass.errors.values.map{|e| e.to_s})
    redirect "/student/#{@student.id}"
  end
end

post '/visit' do
  student = Student.get(params[:student_id])
  @visit = Visit.create(:student_id => student.id, :pass_id => student.pass.id)

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

get '/application.css' do
  headers 'Content-Type' => 'text/css; charset=utf-8'
  sass :style
end

# HELPERS
helpers do
  def partial(page, options={})
    haml page, options.merge!(:layout => false)
  end
end
