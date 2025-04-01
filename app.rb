require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/flash'
require 'slim'
require 'sqlite3'
require 'bcrypt'

require_relative 'model/model.rb'

enable :sessions

# lägg till admin behörighet via checkbox --
	# admin kolumn => error
# ta bort användare
# ta bort/lägg till färg
# ta bort orders
# ändra pengar på användare

# visa anävndarens pengar på startsidan (och layout)

# Hantera buy/sellorders så att de köpes/säljes och i rätt ordning --?
# Updatera/ta bort orders --?

# stats sidan
# sorterbar lista över användare och deras pengar
# sorterbar lista över färger och deras antal

# user/show sidan
# visa användarens pengar
# visa användarens färger och antal (sorterbar)
# visa användarens köp och sälj ordrar

# before för inloggning --?

# kolla inloggad användare vid skyddade actions

# MVC --



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
	session[:redirect] = '/home'
	slim(:home)
end

# users ------------------------------------------------------------------
post('/users/login') do
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

	user = getUsersByName(username).first

	if user == nil
		flash[:loginError] = 'Username does not exist
		Please register if you do not have an account'
		redirect('/users/login')
	end

	pwDigest = user['password']

	if BCrypt::Password.new(pwDigest) == password
		session[:userId] = user['id']
		session[:username] = user['username']

		if session[:redirect] != nil
			redirect = session[:redirect]
			session[:redirect] = nil
			redirect(redirect)
		end
		redirect('/home')
	else
		flash[:username] = username
		flash[:loginError] = 'Wrong username or password'
		redirect('/users/login')
	end
end

get('/users/logout') do
	session.clear
	redirect('/home')
end

get('/users/login') do
	slim(:'users/login')
end

post('/users/create') do
	username = params[:username]
	password = params[:password]
	passwordConfirmation = params[:passwordConfirmation]
	admin = params[:admin]
	if admin == true
		adminLevel = 1
	else
		adminLevel = 0
	end

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

	if getUsersByName(username).first != nil
		flash[:registerError] = 'Username already exists'
		redirect('/users/new')
	end

	if password == passwordConfirmation
		passwordDigest = BCrypt::Password.create(password)
		# getDatabase.execute("INSERT INTO users (username, password, money, imageCreated, admin) VALUES (?,?,?,?)", [username, passwordDigest, 0, 0, adminLevel])
		createUser(username, passwordDigest, adminLevel)
		session[:userId] = user['id']
		session[:username] = user['username']
		if session[:redirect] != nil
			redirect = session[:redirect]
			session[:redirect] = nil
			redirect(redirect)
		end
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

# images -----------------------------------------------------------------
get('/images') do
	# Sorterbar efter olika kolumner
	colors = getAllColors
	slim(:'images/index', locals:{colors:colors})
end

post('/images/create') do
	db = getDatabase()

	user = getUserById(session[:userId])
	timeSinceLastImage = Time.now.to_i - user['imageCreated']
	if timeSinceLastImage < 60*60*24
		flash[:imageError] = 'You can only create one image per day'
		redirect('/images/new')
	end

	setUserImageCreated(Time.now.to_i, session[:userId])

	hexCode = params[:hexCode]
	if getColorByHexcode(hexCode).empty?
		createColor(hexCode)
		redirect('/images')
	else
		# db.execute("UPDATE colors SET amount = amount + 1 WHERE hexCode = (?)", hexCode)
		addToColor(hexCode)
		redirect('/images')
	end
end

get('/images/new') do
	if session[:userId] == nil
		flash[:loginRequired] = 'You need to be logged in to create an image'
		session[:redirect] = '/images/new'
		redirect('/users/login')
	end

	# user = getDatabase().execute('SELECT * FROM users WHERE id = ?', session[:userId]).first
	user = getUserById(session[:userId])
	timeSinceLastImage = Time.now.to_i - user['imageCreated'].to_i
	timeUntilNextImage = 60*60*24 - timeSinceLastImage

	slim(:'images/new', locals:{timeUntilNextImage:timeUntilNextImage})
end

get('/images/show/:id') do
	db = getDatabase()
	id = params[:id].to_i
	# color = db.execute("SELECT * FROM colors WHERE id = #{id}").first
	color = getColorById(id)
	# users = db.execute("SELECT * FROM users")
	users = getAllUsers()
	
	if session[:userId] != nil
		# userSellOrders = db.execute("SELECT * FROM sellOrders WHERE userId = #{session[:userId]} AND colorId = #{id}")
		userSellOrders = getAllSellOrdersFromUserAndColor(session[:userId], id)
		# userBuyOrders = db.execute("SELECT * FROM buyOrders WHERE userId = #{session[:userId]} AND colorId = #{id}")
		userBuyOrders = getAllBuyOrdersFromUserAndColor(session[:userId], id)
	end
	colorSellOrders = db.execute("SELECT * FROM sellOrders WHERE colorId = #{id} ORDER BY price ASC LIMIT 5")
	colorBuyOrders = db.execute("SELECT * FROM buyOrders WHERE colorId = #{id} ORDER BY price DESC LIMIT 5")
	toplist = db.execute("SELECT * FROM users WHERE id IN (SELECT userId FROM userColor WHERE colorId = #{id} ORDER BY amount DESC LIMIT 10)")
	slim(:'images/show', locals:{color:color, users:users, userSellOrders:userSellOrders, userBuyOrders:userBuyOrders, sellOrders:colorSellOrders, buyOrders:colorBuyOrders, toplist:toplist})
end

post('/order/create') do
	if session[:userId] == nil
		flash[:loginRequired] = 'You need to be logged in to create an order'
		session[:redirect] = "/images/show/#{params[:colorId]}"
		redirect('/users/login')
	end


	db = getDatabase()
	userId = session[:userId]
	colorId = params[:colorId].to_i
	price = params[:price].to_i
	amount = params[:amount].to_i
	orderType = params[:orderType]

	# user = db.execute("SELECT * FROM users WHERE id = ?", userId).first
	user = getUserById(userId)
	# userAmountOfColor = db.execute("SELECT amount FROM userColor WHERE userId = ? AND colorId = ?", [userId, colorId]).first
	userAmountOfColor = getUserColorByUserAndColor(userId, colorId)

	if orderType == 'Buy'
		if user['money'] < price*amount
			flash[:orderError] = 'Not enough money'
			redirect("/images/show/#{colorId}")
		end
		# db.execute("INSERT INTO buyOrders (userId, colorId, price, amount) VALUES (?, ?, ?, ?)", [userId, colorId, price, amount])
		createBuyOrder(userId, colorId, price, amount)
		updateUserMoney(userId, -price * amount)
		checkOrders('buy', getAllBuyOrders().last['id'])
	elsif orderType == 'Sell'
		if userAmountOfColor == nil || userAmountOfColor['amount'] < amount
			flash[:orderError] = 'Not enough of this color'
			redirect("/images/show/#{colorId}")
		end
		# db.execute("INSERT INTO sellOrders (userId, colorId, price, amount) VALUES (?, ?, ?, ?)", [userId, colorId, price, amount])
		createSellOrder(userId, colorId, price, amount)
		updateUserColorAmount(userId, colorId, -amount)
		checkOrders('sell', getAllSellOrders().last['id'])
	else 
		flash[:orderError] = 'Invalid order type'
		redirect("/images/show/#{colorId}")
	end

	

	redirect("/images/show/#{colorId}")
end

# stats ------------------------------------------------------------------
get('/stats') do
	slim(:'stats/index')
end