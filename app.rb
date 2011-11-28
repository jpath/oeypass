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

  belongs_to :student

  def today?
    Time.now - created_at < 8.hours
    #false
  end
end

class Pass
  include DataMapper::Resource
  property :id,         Serial
  property :name,       String
  property :pass_type,  Enum['monthly', 'class_package', 'intro']
  property :class_qty,  Enum[1, 5, 10]
  property :month_qty,  Enum[1, 3, 6]
  property :created_on, Date
  property :updated_on, Date
  property :price,      Decimal

  validates_presence_of :class_qty, :if => lambda {|p| p.pass_type == 'class_package'}
  validates_presence_of :month_qty, :if => lambda {|p| p.pass_type == 'monthly'}

  belongs_to :student

  def remaining_classes
    return "n/a" if pass_type != "class_package"
    class_qty - student.visits.size
  end

  def expiry
    return "n/a" unless pass_type == "monthly" or pass_type == "intro"
    if pass_type == "monthly"
      created_on + month_qty.to_i.months
    else
      created_on + 2.weeks
    end
  end
end
# CONFIGURATION
enable :sessions
enable :method_override
configure :development do
  require 'dm-sqlite-adapter'
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
  @students = Student.all
  haml :students
end

post '/pass' do
  DataMapper.logger.debug(params.inspect)
  @pass = Pass.new(:pass_type => params[:pass_type], :class_qty => params[:class_qty],
                   :month_qty => params[:month_qty])
  @student = Student.create(:name => params[:name], :email => params[:email]) 
  @student.pass = @pass;
  @student.save
  if @student.saved?
    redirect '/students'
  else
    session[:errors] = @student.errors.values.map{|e| e.to_s}
    redirect '/'
  end
end

put '/pass' do
  @pass = Pass.new(:pass_type => params[:pass_type], :class_qty => params[:class_qty],
                   :month_qty => params[:month_qty])
  @student = Student.get(params[:student_id])
  params.delete("_method")
  @student.pass.destroy
  @student.pass = @pass;
  @student.save

  if @student.saved?
    redirect "/student/#{@student.id}"
  else
    session[:errors] = @student.errors.values.map{|e| e.to_s}
    redirect "/student/#{@student.id}"
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

# HELPERS
helpers do
  def partial(page, options={})
    haml page, options.merge!(:layout => false)
  end
end
