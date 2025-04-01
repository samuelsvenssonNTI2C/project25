require 'sinatra/reloader'
require 'sqlite3'

def getDatabase()
	db = SQLite3::Database.new('db/database.db')
	db.results_as_hash = true
	return db
end

 # Users -----------------------------------------------------------------
def getAllUsers()
	return getDatabase.execute('SELECT * FROM users')
end

def getUserById(id)
	return getDatabase.execute('SELECT * FROM users WHERE id = ?', [id]).first
end

def getUsersByName(username)
	return getDatabase.execute('SELECT * FROM users WHERE username = ?', [username])
end

def createUser(username, password, adminLevel)
	getDatabase.execute("INSERT INTO users (username, password, money, imageCreated, admin) VALUES (?,?,?,?)", [username, password, 0, 0, adminLevel])
end

def setUserImageCreated(time, id)
	getDatabase.execute('UPDATE users SET imageCreated = ? WHERE id = ?', [time, id])
end

def updateUserMoney(id, deltaMoney)
	getDatabase.execute('UPDATE users SET money = money + ? WHERE id = ?', [deltaMoney, id])
end

 # Colors ----------------------------------------------------------------
def getAllColors()
	return getDatabase.execute('SELECT * FROM colors')
end

def getColorById(id)
	return getDatabase.execute('SELECT * FROM colors WHERE id = ?', [id]).first
end

def getColorByHexcode(hexCode)
	return getDatabase.execute('SELECT * FROM colors WHERE hexCode = ?', [hexCode])
end

def createColor(hexCode)
	getDatabase.execute('INSERT INTO colors (hexCode, amount) VALUES (?, ?)', [hexCode, 1])
end

def addToColor(hexCode)
	getDatabase.execute('UPDATE colors SET amount = amount + 1 WHERE hexCode = ?', hexCode)
end

 # Orders ----------------------------------------------------------------
def getAllBuyOrders()
	return getDatabase.execute('SELECT * FROM buyOrders')
end

def getAllSellOrders()
	return getDatabase.execute('SELECT * FROM sellOrders')
end

def getBuyOrderById(id)
	return getDatabase.execute('SELECT * FROM buyOrders WHERE id = ?', [id])
end

def getSellOrderById(id)
	return getDatabase.execute('SELECT * FROM sellOrders WHERE id = ?', [id])
end

def getAllBuyOrdersFromUser(id)
	return getDatabase.execute('SELECT * FROM buyOrders WHERE userId = ?', [id])
end

def getAllSellOrdersFromUser(id)
	return getDatabase.execute('SELECT * FROM sellOrders WHERE userId = ?', [id])
end

def getAllBuyOrdersFromUserAndColor(id, colorId)
	return getDatabase.execute('SELECT * FROM buyOrders WHERE userId = ? AND colorId = ?', [id, colorId])
end

def getAllSellOrdersFromUserAndColor(id, colorId)
	return getDatabase.execute('SELECT * FROM sellOrders WHERE userId = ? AND colorId = ?', [id, colorId])
end



def createBuyOrder(userId, colorId, price, amount)
	getDatabase.execute('INSERT INTO buyOrders (userId, colorId, price, amount) VALUES (?, ?, ?, ?)', [userId, colorId, price, amount])
end

def createSellOrder(userId, colorId, price, amount)
	getDatabase.execute('INSERT INTO sellOrders (userId, colorId, price, amount) VALUES (?, ?, ?, ?)', [userId, colorId, price, amount])
end

def deleteBuyOrder(id)
	getDatabase.execute('DELETE FROM buyOrders WHERE id = ?', [id])
end

def deleteSellOrder(id)
	getDatabase.execute('DELETE FROM sellOrders WHERE id = ?', [id])
end

def updateBuyOrder(id, deltaAmount)
	getDatabase.execute('UPDATE buyOrders SET amount = amount + ? WHERE id = ?', [deltaAmount, id])
	if getBuyOrdersById(id)['amount'] <= 0
		deleteBuyOrder(id)
	end
end

def updateSellOrder(id, deltaAmount)
	getDatabase.execute('UPDATE sellOrders SET amount = amount + ? WHERE id = ?', [deltaAmount, id])
	if getSellOrdersById(id)['amount'] <= 0
		deleteSellOrder(id)
	end
end

 # UserColor -------------------------------------------------------------
def getUserColorByUserAndColor(userId, colorId)
	return getDatabase.execute('SELECT * FROM userColor WHERE userId = ? AND colorId = ?', [userId, colorId]).first
end

def createUserColor(userId, colorId, amount)
	getDatabase.execute('INSERT INTO userColor (userId, amount, colorId) VALUES (?, ?, ?)', [userId, amount, colorId])
end

def updateUserColorAmount(userId, colorId, deltaAmount)
	getDatabase.execute('UPDATE userColor SET amount = amount + ? WHERE userId = ? AND colorId = ?', [deltaAmount, userId, colorId])
end

 # Transaction -----------------------------------------------------------
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

				updateUserMoney(sellOrder['id'], sellOrder['price']*amount)
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
			end
		end
	end
end

 # Authentication --------------------------------------------------------