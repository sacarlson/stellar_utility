#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
require './stellar_utilities'

master      = Stellar::KeyPair.from_raw_seed("allmylifemyhearthasbeensearching")
to_pair = Stellar::KeyPair.random
#to_account = 'GDJUIEGLARHHM6IVNFEMV5HRX3A2CQV4YVRYUB5FEHDSBVAFENPKRHBA'
#to_pair = Stellar::KeyPair.from_address(to_account)
#to_pair = Stellar::KeyPair.from_seed("SDWTC2MQLFH5J5GBXUI4H4KIPHOFAKY77G7RQH6RDXORIX25NZAJEET5")

from_pair = Stellar::KeyPair.random
puts "#{from_pair.address}"
result = create_account(from_pair, master, starting_balance=1000_0000000)
puts "#{result}"
sleep 10
result = create_account(to_pair, master, starting_balance=1000_0000000)
puts "#{result}"
sleep 10

amount = 5
before = get_native_balance(to_pair.address)
puts "before balance = #{before}"
result = send_native(from_pair, to_pair.address, amount)
puts "#{result}"
sleep 10
after = get_native_balance(to_pair.address)
puts "after send_native #{after}"

puts "#{result}"

