#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
require './stellar_utilities'
#works sep 12 2015

if @configs["fee"] == 0
  starting_balance = 0
elsif @configs["version"] == "fred"
  starting_balance = 1000_000000
  master      = Stellar::KeyPair.from_raw_seed("allmylifemyhearthasbeensearching") 
else
  #Stellar.default_network = Stellar::Networks::TESTNET
  Stellar.default_network = eval(@configs["default_network"])
  rs = Stellar.current_network
  puts "current_network = #{rs}"
  starting_balance = @configs["start_balance"]
  #starting_balance = 25_000000
  #master  = eval( @configs["master_keypair"])
  master  = Stellar::KeyPair.master
end
#this works ok in postgres mode also

to_pair = Stellar::KeyPair.random
from_pair = Stellar::KeyPair.random
#to_account = 'GDJUIEGLARHHM6IVNFEMV5HRX3A2CQV4YVRYUB5FEHDSBVAFENPKRHBA'
#to_pair = Stellar::KeyPair.from_address(to_account)
#to_pair = Stellar::KeyPair.from_seed("SDWTC2MQLFH5J5GBXUI4H4KIPHOFAKY77G7RQH6RDXORIX25NZAJEET5")

puts "master    #{master.address}"
puts "from_pair #{from_pair.address}"
puts "to_pair   #{to_pair.address}"
result = create_account(from_pair, master, starting_balance)
puts "#{result}"
sleep 10
result = create_account(to_pair, master, starting_balance)
puts "#{result}"
sleep 10

amount = 1.4321234
before = get_native_balance(to_pair.address)
puts "before balance = #{before}"
result = send_native(from_pair, to_pair.address, amount)
puts "#{result}"
sleep 10
after = get_native_balance(to_pair.address)
puts "after send_native #{after}"

puts "#{result}"

