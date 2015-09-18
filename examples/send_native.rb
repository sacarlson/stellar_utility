#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
#this is just a basic test to create two stellar accounts and then do native transactions between the two new accounts.
#this is tested as working on horizon4 only 1 out of 3 times, it works in localcore mode every time  sept 18, 2015

require '../lib/stellar_utility/stellar_utility.rb'
Utils = Stellar_utility::Utils.new("horizon")
#Utils = Stellar_utility::Utils.new("/home/sacarlson/github/stellar/stellar_utility/examples/stellar_utilities.cfg")
#Utils = Stellar_utility::Utils.new()
puts "Utils version: #{Utils.version}"
puts "configs: #{Utils.configs}"
puts ""

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
puts "before account created balance on to_pair = #{before}"

result = Utils.create_account(from_pair, master)
puts "#{result}"
sleep 10
result = Utils.create_account(to_pair, master)
puts "#{result}"
sleep 10

amount = 1.4321234
before = Utils.get_native_balance(to_pair.address)
puts "after account creation balance = #{before}"
result = Utils.send_native(from_pair, to_pair.address, amount)
puts "#{result}"
sleep 10
after = Utils.get_native_balance(to_pair.address)
puts "after send_native #{amount} transaction  #{after}"

puts "#{result}"

