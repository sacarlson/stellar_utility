#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
# this tested ok
require './stellar_utilities'
# a test that sets up 3 active funded accounts that are issuer_pair, from_pair, to_pair
# it then sets up needed trustlines on the accounts that need them, then has the issuer send the from_pair account some CHP assets
# then the from_pair sends the to_pair some CHP assets just to show how it's done and verify it works.

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

issuer_address = issuer_pair.address
currency = "CHP"
amount = 100
if @configs["fee"] == 0
  starting_balance = 0
else
  starting_balance = 1000_000000
end

result = create_account(issuer_pair, master, starting_balance)
puts "#{result}"
sleep 11
result = create_account(from_pair, master, starting_balance)
puts "#{result}"
sleep 11
result = create_account(to_pair, master, starting_balance)
puts "#{result}"
sleep 11

result = add_trust(issuer_address,to_pair,currency)
puts "add_trust to to_pair #{result}"
sleep 11
result = add_trust(issuer_address,from_pair,currency)
puts "add_trust to from_pair#{result}"
sleep 11

result = send_currency(issuer_pair, from_pair, issuer_pair, amount, currency)
puts "send_currency issuer to from_pair#{result}"
sleep 11
result = get_lines_balance(to_pair, issuer_address, currency)
puts "before balance: #{result}"
result = send_currency(from_pair, to_pair, issuer_pair, amount, currency)
puts "send_currency from_pair to to_pair #{result}"
sleep 11
result = get_lines_balance(to_pair, issuer_address, currency)
puts "after balance: #{result}"


