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
	return getDatabase.execute('SELECT * FROM buyOrders WHERE id = ?', [id]).first
end

def getSellOrderById(id)
	return getDatabase.execute('SELECT * FROM sellOrders WHERE id = ?', [id]).first
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
	if getBuyOrderById(id)['amount'] <= 0
		deleteBuyOrder(id)
	end
end

def updateSellOrder(id, deltaAmount)
	getDatabase.execute('UPDATE sellOrders SET amount = amount + ? WHERE id = ?', [deltaAmount, id])
	if getSellOrderById(id)['amount'] <= 0
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
	puts 'nu checkar vi!!!'
	if orderType == 'buy'
		puts 'Det var en köporder'
		buyOrder = getBuyOrderById(orderId)
		buyerId = buyOrder['userId']
		colorId = buyOrder['colorId']
		puts "köporderns id: #{buyerId} och färgid: #{colorId}"
		getAllSellOrders().each do |sellOrder|
			puts 'Vi jämför med en sälj order'
			if sellOrder['price'] == buyOrder['price']
				puts 'vi hittade en matchning i pris'
				if sellOrder['amount'] >= buyOrder['amount']
					puts 'Det sälj mer än det köps'
					amount = buyOrder['amount']
				else
					amount = sellOrder['amount']
					puts 'Det köps mer än vad som säljs'
				end
				puts "total mängd blev #{amount}"
				if getUserColorByUserAndColor(buyerId, colorId)
					puts 'köparen hade av denna färg'
					updateUserColorAmount(buyerId, colorId, amount)
				else
					puts 'köparen hade inga av denna färg'
					createUserColor(buyerId, colorId, amount)
				end

				updateSellOrder(sellOrder['id'], -amount)
				puts 'Vi uppdaterar säljordern'
				updateBuyOrder(buyOrder['id'], -amount)
				puts 'vi uppdaterar köpordern'

				updateUserMoney(sellOrder['id'], sellOrder['price']*amount)
				puts 'vi uppdaterar säljarens pengar'
			end
		end
	elsif orderType == 'sell'
		puts 'Det var en köporder'
		sellOrder = getSellOrderById(orderId)
		sellerId = sellOrder['userId']
		colorId = sellOrder['colorId']
		puts "säljorderns id: #{sellerId} och färgid: #{colorId}"
		getAllBuyOrders().each do |buyOrder|
			puts 'Vi jämför med en köp order'
			if buyOrder['price'] == sellOrder['price']
				puts 'vi hittade en matchning i pris'
				if buyOrder['amount'] >= sellOrder['amount']
					amount = sellOrder['amount']
					puts 'Det köps mer än det säljs'
				else
					amount = buyOrder['amount']
					puts 'Det säljs mer än det köps'
				end
				puts "total mängd blev #{amount}"

				if getUserColorByUserAndColor(buyOrder['userId'], colorId)
					updateUserColorAmount(buyOrder['userId'], colorId, amount)
					puts 'köparen hade av denna färg'
				else
					puts 'köparen hade inga av denna färg'
					createUserColor(buyOrder['userId'], colorId, amount)
				end

				updateBuyOrder(buyOrder['id'], -amount)
				puts 'Vi uppdaterar köpordern'
				updateSellOrder(sellOrder['id'], -amount)
				puts 'Vi uppdaterar säljordern'

				updateUserMoney(sellerId, sellOrder['price'] * amount)
				puts 'vi uppdaterar säljarens pengar'
			end
			break
		end
	end
end

 # Authentication --------------------------------------------------------