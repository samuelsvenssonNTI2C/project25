require 'sqlite3'

# Database connection
# 
# @return [SQLite3::Database] the database connection
def getDatabase()
	db = SQLite3::Database.new('db/database.db')
	db.results_as_hash = true
	return db
end

# Users -----------------------------------------------------------------

# Get all users from the database
# 
# @return [Array<Hash>] an array of hashes representing all users
def getAllUsers()
	return getDatabase.execute('SELECT * FROM users')
end

# Get a user by their ID
# 
# @param id [Integer] the ID of the user to retrieve
# 
# @return [Hash, nil] a hash representing the user, or nil if not found
def getUserById(id)
	return getDatabase.execute('SELECT * FROM users WHERE id = ?', [id]).first
end

# Get a user by their username
# 
# @param username [String] the username of the user to retrieve
# 
# @return [Hash, nil] a hash representing the user, or nil if not found
def getUserByName(username)
	return getDatabase.execute('SELECT * FROM users WHERE username = ?', [username]).first
end

# Get the users with the most of one specific color
# 
# @param color_id [Integer] the ID of the color to filter by
# @param limit [Integer] the maximum number of users to retrieve (default: 10)
# 
# @return [Array<Hash>] an array of hashes representing the users with the most of the specified color
def getTopUsersByColor(color_id, limit = 10)
  db = getDatabase()
  return db.execute("SELECT * FROM users WHERE id IN (SELECT userId FROM userColor WHERE colorId = ? ORDER BY amount DESC LIMIT ?)", [color_id, limit])
end

# Create a new user in the database
# 
# @param username [String] the username of the new user
# @param password [String] the password of the new user
# @param adminLevel [Integer] the admin level of the new user (0 for normal user, 1 for admin)
def createUser(username, password, adminLevel)
	getDatabase.execute("INSERT INTO users (username, password, money, imageCreated, admin) VALUES (?,?,?,?,?)", [username, password, 0, 0, adminLevel])
end

# Update the image creation time for a user
# 
# @param time [Integer] the time to set for the image creation
# @param id [Integer] the ID of the user to update
def setUserImageCreated(time, id)
	getDatabase.execute('UPDATE users SET imageCreated = ? WHERE id = ?', [time, id])
end

# Update money for a user
# 
# @param id [Integer] the ID of the user to update
# @param deltaMoney [Integer] the amount to add to the user's money
def updateUserMoney(id, deltaMoney)
	getDatabase.execute('UPDATE users SET money = money + ? WHERE id = ?', [deltaMoney, id])
end

# Colors ----------------------------------------------------------------

# Get all colors from the database
# 
def getAllColors()
	return getDatabase.execute('SELECT * FROM colors')
end

# Get a color by its ID
# 
# @param id [Integer] the ID of the color to retrieve
# 
# @return [Hash, nil] a hash representing the color, or nil if not found
def getColorById(id)
	return getDatabase.execute('SELECT * FROM colors WHERE id = ?', [id]).first
end

# Get colors that belong to a specific user
# 
# @param userId [Integer] the ID of the user to filter by
# 
# @return [Array<Hash>] an array of hashes representing the colors that belong to the specified user
def getColorsByUser(userId)
	return getDatabase.execute('SELECT * FROM colors WHERE id IN (SELECT colorId FROM userColor WHERE userId = ?)', [userId])
end

# Get color by its hex code
# 
# @param hexCode [String] the hex code of the color to retrieve
# 
# @return [Hash, nil] a hash representing the color, or nil if not found
def getColorByHexcode(hexCode)
	return getDatabase.execute('SELECT * FROM colors WHERE hexCode = ?', [hexCode]).first
end

# Create a new color in the database
# 
# @param hexCode [String] the hex code of the new color
def createColor(hexCode)
	getDatabase.execute('INSERT INTO colors (hexCode, amount) VALUES (?, ?)', [hexCode, 1])
end

# Update the amount of a color to plus 1 in the database
def addToColor(hexCode)
	getDatabase.execute('UPDATE colors SET amount = amount + 1 WHERE hexCode = ?', hexCode)
end

# Orders ----------------------------------------------------------------

# Get all buy orders from the database
# 
def getAllBuyOrders()
	return getDatabase.execute('SELECT * FROM buyOrders')
end

# Get all sell orders from the database
def getAllSellOrders()
	return getDatabase.execute('SELECT * FROM sellOrders')
end

# Get a buy order by its ID
# 
# @param id [Integer] the ID of the buy order to retrieve
# 
# @return [Hash, nil] a hash representing the buy order, or nil if not found
def getBuyOrderById(id)
	return getDatabase.execute('SELECT * FROM buyOrders WHERE id = ?', [id]).first
end

# Get a sell order by its ID
# 
# @param id [Integer] the ID of the sell order to retrieve
# 
# @return [Hash, nil] a hash representing the sell order, or nil if not found
def getSellOrderById(id)
	return getDatabase.execute('SELECT * FROM sellOrders WHERE id = ?', [id]).first
end

# Get all buy orders from a specific user
# 
# @param id [Integer] the ID of the user to filter by
# 
# @return [Array<Hash>] an array of hashes representing the buy orders that belong to the specified user
def getAllBuyOrdersFromUser(id)
	return getDatabase.execute('SELECT * FROM buyOrders WHERE userId = ?', [id])
end

# Get all sell orders from a specific user
# 
# @param id [Integer] the ID of the user to filter by
# 
# @return [Array<Hash>] an array of hashes representing the sell orders that belong to the specified user
def getAllSellOrdersFromUser(id)
	return getDatabase.execute('SELECT * FROM sellOrders WHERE userId = ?', [id])
end

# Get all buy orders from a specific user and color
# 
# @param id [Integer] the ID of the user to filter by
# @param colorId [Integer] the ID of the color to filter by
# 
# @return [Array<Hash>] an array of hashes representing the buy orders that belong to the specified user and color
def getAllBuyOrdersFromUserAndColor(id, colorId)
	return getDatabase.execute('SELECT * FROM buyOrders WHERE userId = ? AND colorId = ?', [id, colorId])
end

# Get all sell orders from a specific user and color
# 
# @param id [Integer] the ID of the user to filter by
# @param colorId [Integer] the ID of the color to filter by
# 
# @return [Array<Hash>] an array of hashes representing the sell orders that belong to the specified user and color
def getAllSellOrdersFromUserAndColor(id, colorId)
	return getDatabase.execute('SELECT * FROM sellOrders WHERE userId = ? AND colorId = ?', [id, colorId])
end

# Get all sell orders for a specific color with a limit
# 
# @param color_id [Integer] the ID of the color to filter by
# @param limit [Integer] the maximum number of sell orders to retrieve (default: 5)
# 
# @return [Array<Hash>] an array of hashes representing the sell orders for the specified color
def getSellOrdersByColorId(color_id, limit = 5)
  db = getDatabase()
  db.execute("SELECT * FROM sellOrders WHERE colorId = ? ORDER BY price ASC LIMIT ?", [color_id, limit])
end

# Get all buy orders for a specific color with a limit
# 
# @param color_id [Integer] the ID of the color to filter by
# @param limit [Integer] the maximum number of buy orders to retrieve (default: 5)
# 
# @return [Array<Hash>] an array of hashes representing the buy orders for the specified color
def getBuyOrdersByColorId(color_id, limit = 5)
  db = getDatabase()
  db.execute("SELECT * FROM buyOrders WHERE colorId = ? ORDER BY price DESC LIMIT ?", [color_id, limit])
end

# Create a new buy order in the database
# 
# @param userId [Integer] the ID of the user creating the buy order
# @param colorId [Integer] the ID of the color to buy
# @param price [Integer] the price per color
# @param amount [Integer] the amount of colors to buy
def createBuyOrder(userId, colorId, price, amount)
	getDatabase.execute('INSERT INTO buyOrders (userId, colorId, price, amount) VALUES (?, ?, ?, ?)', [userId, colorId, price, amount])
end

# Create a new sell order in the database
#
# @param userId [Integer] the ID of the user creating the sell order
# @param colorId [Integer] the ID of the color to sell
# @param price [Integer] the price per color
# @param amount [Integer] the amount of colors to sell
def createSellOrder(userId, colorId, price, amount)
	getDatabase.execute('INSERT INTO sellOrders (userId, colorId, price, amount) VALUES (?, ?, ?, ?)', [userId, colorId, price, amount])
end

# Delete a buy order from the database and give the money back to the user
# 
# @param id [Integer] the ID of the buy order to delete
# 
# @see Model#getBuyOrderById
# @see Model#updateUserMoney
def deleteBuyOrder(id)
	buyOrder = getBuyOrderById(id)
	updateUserMoney(buyOrder['userId'], buyOrder['price'] * buyOrder['amount'])
	getDatabase.execute('DELETE FROM buyOrders WHERE id = ?', [id])
end

# Delete a sell order from the database and give the color back to the user
# 
# @param id [Integer] the ID of the sell order to delete
# 
# @see Model#getSellOrderById
# @see Model#updateUserColorAmount
def deleteSellOrder(id)
	sellOrder = getSellOrderById(id)
	updateUserColorAmount(sellOrder['userId'], sellOrder['colorId'], sellOrder['amount'])
	getDatabase.execute('DELETE FROM sellOrders WHERE id = ?', [id])
end

# Update a buy order in the database
# 
# @param id [Integer] the ID of the buy order to update
# @param deltaAmount [Integer] the amount to add to the buy order
# 
# @see Model#getBuyOrderById
# @see Model#deleteBuyOrder
def updateBuyOrder(id, deltaAmount)
	getDatabase.execute('UPDATE buyOrders SET amount = amount + ? WHERE id = ?', [deltaAmount, id])
	if getBuyOrderById(id)['amount'] <= 0
		deleteBuyOrder(id)
	end
end

# Update a sell order in the database
# 
# @param id [Integer] the ID of the sell order to update
# @param deltaAmount [Integer] the amount to add to the sell order
# 
# @see Model#getSellOrderById
# @see Model#deleteSellOrder
def updateSellOrder(id, deltaAmount)
	getDatabase.execute('UPDATE sellOrders SET amount = amount + ? WHERE id = ?', [deltaAmount, id])
	if getSellOrderById(id)['amount'] <= 0
		deleteSellOrder(id)
	end
end

# UserColor -------------------------------------------------------------

# Get all userColor relations from specified user
# 
# @param userId [Integer] the ID of the user to filter by
#
# @return [Array<Hash>] an array of hashes representing the userColor relations for the specified user
def getUserColorByUser(userId)
	return getDatabase.execute('SELECT * FROM userColor WHERE userId = ?', [userId])
end

# Get all userColor relation from specified user and color
# 
# @param userId [Integer] the ID of the user to filter by
# @param colorId [Integer] the ID of the color to filter by
# 
#@return [Hash, nil] a hash representing the userColor relation, or nil if not found
def getUserColorByUserAndColor(userId, colorId)
	return getDatabase.execute('SELECT * FROM userColor WHERE userId = ? AND colorId = ?', [userId, colorId]).first
end

# Create a new userColor relation in the database
# 
# @param userId [Integer] the ID of the user to create the relation for
# @param colorId [Integer] the ID of the color to create the relation for
# @param amount [Integer] the amount of colors in the relation
def createUserColor(userId, colorId, amount)
	getDatabase.execute('INSERT INTO userColor (userId, amount, colorId) VALUES (?, ?, ?)', [userId, amount, colorId])
end

# Update the amount of a color in a userColor relation in the database
# 
# @param userId [Integer] the ID of the user to update the relation for
# @param colorId [Integer] the ID of the color to update the relation for
# @param deltaAmount [Integer] the amount to add to the userColor relation
def updateUserColorAmount(userId, colorId, deltaAmount)
	getDatabase.execute('UPDATE userColor SET amount = amount + ? WHERE userId = ? AND colorId = ?', [deltaAmount, userId, colorId])
end

# Transaction -----------------------------------------------------------

# Check if a buy or sell order can be fulfilled and update the database accordingly
# 
# @param orderType [String] the type of order (buy/sell)
# @param orderId [Integer] the ID of the order to check
# 
# @see Model#getBuyOrderById
# @see Model#getSellOrderById
# @see Model#getAllSellOrders
# @see Model#getAllBuyOrders
# @see Model#getUserColorByUserAndColor
# @see Model#updateUserColorAmount
# @see Model#createUserColor
# @see Model#updateSellOrder
# @see Model#updateBuyOrder
# @see Model#updateUserMoney
def checkOrders(orderType, orderId)
	if orderType == 'buy'
		buyOrder = getBuyOrderById(orderId)
		buyerId = buyOrder['userId']
		colorId = buyOrder['colorId']
		getAllSellOrders().each do |sellOrder|
			if sellOrder['price'] == buyOrder['price']
				if sellOrder['amount'] >= buyOrder['amount']
					amount = buyOrder['amount']
				else
					amount = sellOrder['amount']
				end
				if getUserColorByUserAndColor(buyerId, colorId)
					updateUserColorAmount(buyerId, colorId, amount)
				else
					createUserColor(buyerId, colorId, amount)
				end

				updateSellOrder(sellOrder['id'], -amount)
				updateBuyOrder(buyOrder['id'], -amount)

				updateUserMoney(sellOrder['userId'], sellOrder['price']*amount)
				if getBuyOrderById(orderId) == nil
					break
				else 
					buyOrder = getBuyOrderById(orderId)
				end
			end
		end
	elsif orderType == 'sell'
		sellOrder = getSellOrderById(orderId)
		sellerId = sellOrder['userId']
		colorId = sellOrder['colorId']
		getAllBuyOrders().each do |buyOrder|
			if buyOrder['price'] == sellOrder['price']
				if buyOrder['amount'] >= sellOrder['amount']
					amount = sellOrder['amount']
				else
					amount = buyOrder['amount']
				end

				if getUserColorByUserAndColor(buyOrder['userId'], colorId)
					updateUserColorAmount(buyOrder['userId'], colorId, amount)
				else
					createUserColor(buyOrder['userId'], colorId, amount)
				end

				updateBuyOrder(buyOrder['id'], -amount)
				updateSellOrder(sellOrder['id'], -amount)

				updateUserMoney(sellerId, sellOrder['price'] * amount)
				if getSellOrderById(orderId) == nil
					break
				else 
					sellOrder = getSellOrderById(orderId)
				end
			end
		end
	end
end

# Authentication --------------------------------------------------------