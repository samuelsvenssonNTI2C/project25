require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/flash'
require 'slim'
require 'sqlite3'
require 'bcrypt'

enable :sessions

def getDatabase()
	db = SQLite3::Database.new('db/database.db')
	db.results_as_hash = true
	return db
end

get('/') do
	redirect('/home')
end

get('/home') do
	# Behöver db från user och color
	# Behöver db från sellOrders och buyOrders med inloggad användare
	slim(:home)
end

post('/users/login') do
	# Checka allt med login och databas!!!
	username = params[:username]
	password = params[:password]

	if username.empty?
		flash[:loginError] = 'Missing username'
		redirect('/users/login')
	elsif password.empty?
		flash[:username] = username
		flash[:loginError] = 'Missing password'
		redirect('/users/login')
	end

	user = getDatabase().execute('SELECT * FROM users WHERE username = ?', username).first
	pwDigest = user['pwDigest']

	if BCrypt::Password.new(pwDigest) == password
		session[:userId] = user['id']
		session[:username] = user['username']
		redirect('/home')
	else
		flash[:username] = username
		flash[:loginError] = 'Wrong username or password'
		redirect('/users/login')
	end
end

get('/users/login') do
	slim(:'users/login')
end

post('/users/create') do
	username = params[:username]
	password = params[:password]
	passwordConfirmation = params[:passwordConfirmation]

	if username.empty?
		flash[:registerError] = 'Missing username'
		redirect('/users/new')
	elsif password.empty?
		flash[:registerError] = 'Missing password'
		flash[:username] = username
		redirect('/users/new')
	elsif passwordConfirmation.empty?
		flash[:username] = username
		flash[:registerError] = 'Missing password confirmation'
		redirect('/users/new')
	end

	if password == passwordConfirmation
		passwordDigest = BCrypt::Password.create(password)
		getDatabase.execute("INSERT INTO users (username, password, money, dailyImage) VALUES (?,?,?,?)", [username, passwordDigest, 0, false])
		redirect('/home')
	else
		flash[:username] = username
		flash[:registerError] = 'Passwords do not match'
		redirect('/users/new')
	end
end

get('/users/new') do
	slim(:'users/new')
end

get('users/show/:id') do
	userId = params[:id].to_i
	slim(:'users/show', locals:{id:userId})
end

get('/images') do
	# Sorterbar efter olika kolumner
	colors = getDatabase().execute('SELECT * FROM colors')
	slim(:'images/index', locals:{colors:colors})
end

post('/images/create') do
	db = getDatabase()
	hexCode = params[:hexCode]
	if db.execute("SELECT * FROM colors WHERE hexCode = (?)", hexCode).empty?
		db.execute("INSERT INTO colors (hexCode, amount) VALUES (?, ?)", [hexCode, 1])
		redirect('/images')
	else
		db.execute("UPDATE colors SET amount = amount + 1 WHERE hexCode = (?)", hexCode)
		redirect('/images')
	end
end

get('/images/new') do
	slim(:'images/new')
end

get('/images/show/:id') do
	db = getDatabase()
	id = params[:id].to_i
	color = db.execute("SELECT * FROM colors WHERE id = #{id}").first
	colorSellOrders = db.execute("SELECT * FROM sellOrders WHERE colorId = #{id} ORDER BY price ASC LIMIT 5")
	colorBuyOrders = db.execute("SELECT * FROM buyOrders WHERE colorId = #{id} ORDER BY price DESC LIMIT 5")
	# Relations tabell userColor: userId, amount, colorId
	toplist = db.execute("SELECT * FROM users WHERE id = (SELECT userId FROM userColor WHERE colorId = #{id} ORDER BY amount DESC LIMIT 10)")
	# toplist = []
	slim(:'images/show', locals:{color:color, sellOrders:colorSellOrders, buyOrders:colorBuyOrders}, toplist:toplist)
end

post('/order/create') do
	db = getDatabase()
	userId = session[:userId]
	colorId = params[:colorId].to_i
	price = params[:price].to_i
	amount = params[:amount].to_i
	orderType = params[:orderType]

	# Dubbelkolla kolumner!!!
	if orderType == 'buy'
		db.execute("INSERT INTO buyOrders (userId, colorId, price, amount) VALUES (?, ?, ?, ?)", userId, colorId, price, amount)
	else
		db.execute("INSERT INTO sellOrders (userId, colorId, price, amount) VALUES (?, ?, ?, ?)", userId, colorId, price, amount)
	end
end

get('/stats') do
	slim(:'stats/index')
end