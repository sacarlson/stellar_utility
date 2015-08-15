#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
# this tested ok
require './stellar_utilities'

master      = Stellar::KeyPair.from_raw_seed("allmylifemyhearthasbeensearching")
issuer_pair = Stellar::KeyPair.random
puts "issuer address #{issuer_pair.address}"
puts "issuer seed #{issuer_pair.seed}"
from_pair = Stellar::KeyPair.random
puts "from address #{from_pair.address}"
puts "from seed #{from_pair.seed}"
to_pair = Stellar::KeyPair.random
puts "to address #{to_pair.address}"
puts "to seed #{to_pair.seed}"

result = create_account(issuer_pair, master, starting_balance=1000_0000000)
puts "#{result}"
sleep 11
result = create_account(from_pair, master, starting_balance=1000_0000000)
puts "#{result}"
sleep 11
result = create_account(to_pair, master, starting_balance=1000_0000000)
puts "#{result}"
sleep 11

issuer_address = issuer_pair.address
currency = "CHP"
amount = 100

result = add_trust(issuer_address,to_pair,currency)
puts "add_trust to to_pair #{result}"
sleep 11
result = add_trust(issuer_address,from_pair,currency)
puts "add_trust to from_pair#{result}"
sleep 11


result = send_currency(issuer_pair, from_pair, issuer_pair, amount, currency)
puts "send_currency issuer to from_pair#{result}"
sleep 11
result = get_lines_balance(to_pair,currency)
puts "before balance: #{result}"
result = send_currency(from_pair, to_pair, issuer_pair, amount, currency)
puts "send_currency from_pair to to_pair #{result}"
sleep 11
result = get_lines_balance(to_pair,currency)
puts "after balance: #{result}"


