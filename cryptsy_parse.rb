require 'net/http'
require 'json'
require 'set'
require 'date'

class Coin
	attr_accessor :canBuyWith
	attr_accessor :prices

	def initialize(name)
		@name = name
		@canBuyWith = Set.new
		@prices = {}
	end

	def setTradesWith other, price
		@canBuyWith.add other
		@prices[other] = price
	end
end

url = 'http://pubapi.cryptsy.com/api.php?method=marketdatav2'

doLoop = true
while doLoop
	sleep 1
	begin
		resp = Net::HTTP.get_response(URI.parse(url))
		parsed = JSON.parse(resp.body)

		if parsed['success'] == 1
			puts DateTime.now.strftime('%T') + ' : pinged'

			rawMarkets = parsed['return']['markets']
			markets = {}

			rawMarkets.each do |key, val|
				sp = key.split '/'
				left = sp[0]
				right = sp[1]
				if markets[left] == nil
					markets[left] = Coin.new left
				end
				if markets[right] == nil
					markets[right] = Coin.new right
				end

				bestSell = 9999999.0
				val['sellorders'].each do |listing|
					if listing['price'].to_f < bestSell
						bestSell = listing['price'].to_f
					end
				end
				bestBuy = 99999999.0
				val['buyorders'].each do |listing|
					if listing['price'].to_f < bestBuy
						bestBuy = listing['price'].to_f
					end
				end

				markets[left].setTradesWith right, bestBuy
				markets[right].setTradesWith left, 1.0 / bestSell
			end

			loops = Set.new
			name = 'BTC'
			markets[name].canBuyWith.each do |name2|
				if name2 != name
					markets[name2].canBuyWith.each do |name3|
						if markets[name3].canBuyWith.member? name
							p1 = markets[name].prices[name2]
							p2 = markets[name2].prices[name3]
							p3 = markets[name3].prices[name]
							loops.add [p1 * p2 * p3, name, p1, name2, p2, name3, p3]
						end
					end
				end
			end
			loops = loops.sort {|x, y| x[0] <=> y[0]}

			# loops.each do |list|
			# 	puts list.to_s
			# end
			# puts 'Found ' + loops.size.to_s + ' loops'

			# puts ''

			goodLoops = loops.select {|x| x[0] > 1.0}
			goodLoops.each do |list|
				puts list.to_s
			end
		end
	rescue Interrupt => i
		doLoop = false
	rescue Exception => e
	end
end