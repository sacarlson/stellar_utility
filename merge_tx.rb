#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
# note: I can't get this to work yet Aug 12, 2015
require './stellar_utilities'

master      = Stellar::KeyPair.from_raw_seed("allmylifemyhearthasbeensearching")
from_pair = Stellar::KeyPair.random
puts "from address #{from_pair.address}"
puts "from seed #{from_pair.seed}"
to_pair = Stellar::KeyPair.random
puts "to address #{to_pair.address}"
puts "to seed #{to_pair.seed}"
amount = 5
result = create_account(to_pair, master, starting_balance=1000_0000000)
puts "#{result}"
sleep 11
result = create_account(from_pair, master, starting_balance=1000_0000000)
puts "#{result}"
sleep 11

tx1 = send_native_tx(from_pair, to_pair.address, amount)
tx2 = send_native_tx(from_pair, to_pair.address, amount,1)
b64 = tx_merge(from_pair,tx1,tx2)

result = send_tx(b64)
puts "#{result}"
# {"status"=>"ERROR", "error"=>"AAAAAAAAAAD////3AAAAAA=="}  result returned not sure why
# this code translates to txInsufficientFee that I don't know how to setup or change
# maybe just another stellar-core bug?
