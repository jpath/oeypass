# myapp.rb
require 'sinatra'

get '/' do
  haml :index
end

get '/pass' do
  haml :pass
end

post '/pass' do
  puts params
end

