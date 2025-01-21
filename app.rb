require 'sinatra'
require 'sinatra/reloader'
require 'sessions'
require 'slim'
require 'sqlite3'
require 'bcrypt'

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

end

post('/images/create') do

end

get('/images/new') do

end

get('/images/show/:id') do

end