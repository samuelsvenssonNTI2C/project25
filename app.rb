require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'

enable :sessions

get('/') do
	redirect('/home')
end

get('/home') do
	slim(:home)
end

post('/user/login') do

end

get('/user/login') do
	slim(:'user/index')
end

post('/user/create') do
	
end

get('user/new') do
	slim(:'user/new')
end

get('user/show/:id') do
	userId = params[:id]
	slim(:'user/show', locals:{id:userId})
end

get('/images') do
	slim(:'images/index')
end

post('/images/create') do

end

get('/images/new') do
	slim(:'images/new')
end

get('/images/show/:id') do
	imageId = params[:id]
	slim(:'images/show', locals:{id:imageId})
end

get('/stats') do
	slim(:'stats/index')
end