require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/flash'
require 'slim'
require 'sqlite3'
require 'bcrypt'

require_relative 'model/model.rb'
also_reload 'model/model.rb'

enable :sessions

# ADMIN
# ta bort användare (oprioriterad)
# ta bort/lägg till färg (oprioriterad)
# ändra pengar på användare (oprioriterad)

# Image/Show
# toplistan (oprioriterad)

# Stats (oprioriterad)
# sorterbar lista över användare och deras pengar
# sorterbar lista över färger och deras antal

# User/show (oprioriterad)
# visa användarens pengar
# visa användarens färger och antal (sorterbar)
# visa användarens köp och sälj ordrar

# kolla inloggad användare vid skyddade actions

# Route to redirect to home page
# 
get('/') do
	redirect('/home')
end

# Display the home page
#
# @see Model#getUserById
# @see Model#getColorsByUser
# @see Model#getUserColorByUser
get('/home') do
	user = getUserById(session[:userId])
	colors = getColorsByUser(session[:userId])
	userColors = getUserColorByUser(session[:userId])
	slim(:home, locals:{user:user, colors:colors, userColors:userColors})
end

# users ------------------------------------------------------------------
# Logs in the user
# 
# @param username [String] the username of the user
# @param password [String] the password of the user
# 
# @see Model#getUserByName
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

	user = getUserByName(username)

	if user == nil
		flash[:loginError] = 'Username does not exist
		Please register if you do not have an account'
		redirect('/users/login')
	end

	pwDigest = user['password']

	if BCrypt::Password.new(pwDigest) == password
		session[:userId] = user['id']
		session[:username] = user['username']

		if user['admin'] == 1
			session[:admin] = true
		else
			session[:admin] = false
		end

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

# Logs out the user
# 
get('/users/logout') do
	session.clear
	redirect('/home')
end

# Display the login page
#
get('/users/login') do
	slim(:'users/login')
end

# Registers a new user
# 
# @param username [String] the username of the user
# @param password [String] the password of the user
# @param passwordConfirmation [String] the password confirmation of the user
# @param admin [String] the admin level of the user
# 
# @see Model#getUserByName
# @see Model#createUser
post('/users/create') do
	username = params[:username]
	password = params[:password]
	passwordConfirmation = params[:passwordConfirmation]
	admin = params[:admin]
	if admin == 'on'
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

	if getUserByName(username) != nil
		flash[:registerError] = 'Username already exists'
		redirect('/users/new')
	end

	if password == passwordConfirmation
		passwordDigest = BCrypt::Password.create(password)
		createUser(username, passwordDigest, adminLevel)
		user = getUserByName(username)
		session[:userId] = user['id']
		session[:username] = user['username']
		if user['admin'] == 1
			session[:admin] = true
		else
			session[:admin] = false
		end
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

# Display the register page
#
get('/users/new') do
	slim(:'users/new')
end

# Display a specific user page
#
# @param id [Integer] the id of the user to display
get('users/show/:id') do
	userId = params[:id].to_i
	slim(:'users/show', locals:{id:userId})
end

# images -----------------------------------------------------------------

# Display the images page
#
# @see Model#getAllColors
get('/images') do
	# Sorterbar efter olika kolumner
	colors = getAllColors()
	slim(:'images/index', locals:{colors:colors})
end

# Creates a new image
# 
# @param hexCode [String] the hex code of the image
# 
# @see Model#getUserById
# @see Model#setUserImageCreated
# @see Model#getColorByHexcode
# @see Model#addToColor
# @see Model#createColor
# @see Model#getUserColorByUserAndColor
# @see Model#createUserColor
# @see Model#updateUserColorAmount
post('/images/create') do
	user = getUserById(session[:userId])
	timeSinceLastImage = Time.now.to_i - user['imageCreated']
	if timeSinceLastImage < 60*60*24
		flash[:imageError] = 'You can only create one image per day'
		redirect('/images/new')
	end

	setUserImageCreated(Time.now.to_i, session[:userId])

	hexCode = params[:hexCode]
	if getColorByHexcode(hexCode)
		addToColor(hexCode)
	else
		createColor(hexCode)
	end

	colorId = getColorByHexcode(hexCode)['id']
	if getUserColorByUserAndColor(user['id'], colorId) == nil
		createUserColor(user['id'], colorId, 1)
	else
		updateUserColorAmount(user['id'], colorId, 1)
	end

	redirect('/images')
end

# Display the create image page
#
# @see Model#getUserById
get('/images/new') do
	if session[:userId] == nil
		flash[:loginRequired] = 'You need to be logged in to create an image'
		session[:redirect] = '/images/new'
		redirect('/users/login')
	end

	user = getUserById(session[:userId])
	timeSinceLastImage = Time.now.to_i - user['imageCreated'].to_i
	timeUntilNextImage = 60*60*24 - timeSinceLastImage

	slim(:'images/new', locals:{timeUntilNextImage:timeUntilNextImage})
end

# Display a specific image page
#
# @param id [Integer] the id of the image to display
# @see Model#getColorById
# @see Model#getAllUsers
# @see Model#getAllSellOrdersFromUserAndColor
# @see Model#getAllBuyOrdersFromUserAndColor
# @see Model#getSellOrdersByColorId
# @see Model#getBuyOrdersByColorId
# @see Model#getTopUsersByColor
get('/images/show/:id') do
	id = params[:id].to_i
	color = getColorById(id)
	users = getAllUsers()
	
	if session[:userId] != nil
		userSellOrders = getAllSellOrdersFromUserAndColor(session[:userId], id)
		userBuyOrders = getAllBuyOrdersFromUserAndColor(session[:userId], id)
	end
	colorSellOrders = getSellOrdersByColorId(id)
	colorBuyOrders = getBuyOrdersByColorId(id)
	toplist = getTopUsersByColor(id)
	slim(:'images/show', locals:{color:color, users:users, userSellOrders:userSellOrders, userBuyOrders:userBuyOrders, sellOrders:colorSellOrders, buyOrders:colorBuyOrders, toplist:toplist})
end

# Creates a new order
# 
# # @param colorId [Integer] the id of the color to create an order for
# # @param price [Integer] the price per color
# # @param amount [Integer] the amount of colors to buy/sell
# # # @param orderType [String] the type of order (buy/sell)
# 
# @see Model#getUserById
# @see Model#getUserColorByUserAndColor
# @see Model#createBuyOrder
# @see Model#updateUserMoney
# @see Model#checkOrders
# @see Model#createSellOrder
# @see Model#updateUserColorAmount
post('/order/create') do
	if session[:userId] == nil
		flash[:loginRequired] = 'You need to be logged in to create an order'
		session[:redirect] = "/images/show/#{params[:colorId]}"
		redirect('/users/login')
	end

	userId = session[:userId]
	colorId = params[:colorId].to_i
	price = params[:price].to_i
	amount = params[:amount].to_i
	orderType = params[:orderType]

	user = getUserById(userId)
	userAmountOfColor = getUserColorByUserAndColor(userId, colorId)

	if orderType == 'Buy'
		if user['money'] < price*amount
			flash[:orderError] = 'Not enough money'
			redirect("/images/show/#{colorId}")
		end
		createBuyOrder(userId, colorId, price, amount)
		updateUserMoney(userId, -price * amount)
		checkOrders('buy', getAllBuyOrders().last['id'])
	elsif orderType == 'Sell'
		if userAmountOfColor == nil || userAmountOfColor['amount'] < amount
			flash[:orderError] = 'Not enough of this color'
			redirect("/images/show/#{colorId}")
		end
		createSellOrder(userId, colorId, price, amount)
		updateUserColorAmount(userId, colorId, -amount)
		checkOrders('sell', getAllSellOrders().last['id'])
	else 
		flash[:orderError] = 'Invalid order type'
		redirect("/images/show/#{colorId}")
	end

	

	redirect("/images/show/#{colorId}")
end

# Deletes an order
# 
# @param orderId [Integer] the id of the order to delete
# @param orderType [String] the type of order (buy/sell)
# 
# @see Model#getBuyOrderById
# @see Model#deleteBuyOrder
# @see Model#getSellOrderById
# @see Model#deleteSellOrder
post('/order/delete') do
	orderId = params[:orderId].to_i
	orderType = params[:type]
	if orderType == 'buy'
		colorId = getBuyOrderById(orderId)['colorId']
		deleteBuyOrder(orderId)
	elsif orderType == 'sell'
		colorId = getSellOrderById(orderId)['colorId']
		deleteSellOrder(orderId)
	end
	redirect("/images/show/#{colorId}")
end

# stats ------------------------------------------------------------------

# Display the stats page
#
get('/stats') do
	slim(:'stats/index')
end