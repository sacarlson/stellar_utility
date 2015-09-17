#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
require '../lib/stellar_utility/stellar_utility.rb'
Utils = Stellar_utility::Utils.new("horizon")
puts "Utils version: #{Utils.version}"
puts "configs: #{Utils.configs}"
puts ""
#starting_balance = @configs["start_balance"]
#starting_balance = 1000_000000

#master      = Stellar::KeyPair.from_raw_seed("allmylifemyhearthasbeensearching") 
#master  = eval( @configs["master_keypair"])
master  = Stellar::KeyPair.master


to_pair = Stellar::KeyPair.random
from_pair = Stellar::KeyPair.random
#to_account = 'GDJUIEGLARHHM6IVNFEMV5HRX3A2CQV4YVRYUB5FEHDSBVAFENPKRHBA'
#to_pair = Stellar::KeyPair.from_address(to_account)
#to_pair = Stellar::KeyPair.from_seed("SDWTC2MQLFH5J5GBXUI4H4KIPHOFAKY77G7RQH6RDXORIX25NZAJEET5")

puts "master    #{master.address}"
puts "from_pair #{from_pair.address}"
puts "to_pair   #{to_pair.address}"
puts "starting_balance: #{Utils.configs["start_balance"]}"

before = Utils.get_native_balance(to_pair.address)
puts "before balance = #{before}"
exit -1

result = Utils.create_account(from_pair, master)
puts "#{result}"
sleep 10
result = Utils.create_account(to_pair, master)
puts "#{result}"
sleep 10

amount = 1.4321234
before = Utils.get_native_balance(to_pair.address)
puts "before balance = #{before}"
result = Utils.send_native(from_pair, to_pair.address, amount)
puts "#{result}"
sleep 10
after = Utils.get_native_balance(to_pair.address)
puts "after send_native #{after}"

puts "#{result}"

