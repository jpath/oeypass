# myapp.rb
require 'sinatra'
require 'data_mapper'
require 'haml'

get '/' do
  haml :index
end

get '/pass' do
  haml :pass
end

post '/pass' do
  puts params
end

