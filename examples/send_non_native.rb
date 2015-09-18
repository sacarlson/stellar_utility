#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
# this tested ok
# a test that sets up 3 active funded accounts that are issuer_pair, from_pair, to_pair
# it then sets up needed trustlines on the accounts that need them, then has the issuer send the from_pair account some CHP assets
# then the from_pair sends the to_pair some CHP assets just to show how it's done and verify it works.
#works sept 14, 2015

require '../lib/stellar_utility/stellar_utility.rb'

Utils = Stellar_utility::Utils.new("horizon")
#Utils = Stellar_utility::Utils.new()
puts "Utils version: #{Utils.version}"
puts "configs: #{Utils.configs}"

issuer_pair = Stellar::KeyPair.random
puts "issuer address #{issuer_pair.address}"
puts "issuer seed #{issuer_pair.seed}"
from_pair = Stellar::KeyPair.random
puts "from address #{from_pair.address}"
puts "from seed #{from_pair.seed}"
to_pair = Stellar::KeyPair.random
puts "to address #{to_pair.address}"
puts "to seed #{to_pair.seed}"

master  = Stellar::KeyPair.master
issuer_address = issuer_pair.address
currency = "CHP"
amount = "105.12"


result = Utils.create_account(issuer_pair, master)
puts "#{result}"
#sleep 11
result = Utils.create_account(from_pair, master)
puts "#{result}"
#sleep 11
result = Utils.create_account(to_pair, master)
puts "#{result}"
#sleep 11

result = Utils.add_trust(issuer_address,to_pair,currency)
puts "add_trust to to_pair #{result}"
#sleep 11
result = Utils.add_trust(issuer_address,from_pair,currency)
puts "add_trust to from_pair #{result}"
#sleep 11

result = Utils.send_currency(issuer_pair, from_pair, issuer_pair, amount, currency)
puts "send_currency issuer to from_pair #{result}"
#sleep 11
result = Utils.get_lines_balance(to_pair, issuer_address, currency)
puts "before balance: #{result}"
result = Utils.send_currency(from_pair, to_pair, issuer_pair, amount, currency)
puts "send_currency from_pair to to_pair #{result}"
#sleep 11
result = Utils.get_lines_balance(to_pair, issuer_address, currency)
puts "after balance: #{result}"


