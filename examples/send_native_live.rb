#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
#this is just a basic test to create two stellar accounts and then do native transactions between the two new accounts.
#this is tested as working on horizon4 only 1 out of 3 times, it works in localcore mode every time  sept 18, 2015

require '../lib/stellar_utility/stellar_utility.rb'
#Utils = Stellar_utility::Utils.new("horizon")  #hard coded horizon mode in testnet 
Utils = Stellar_utility::Utils.new()  # default points to ./stellar_utilities.cfg file recomended
#Utils = Stellar_utility::Utils.new("/home/sacarlson/github/stellar/stellar_utility/examples/stellar_utilities.cfg")
puts "Utils version: #{Utils.version}"
puts "configs: #{Utils.configs}"
puts ""

#master  = eval( @configs["master_keypair"])
#master  = Stellar::KeyPair.master
master = YAML.load(File.open("./secret_keypair_Live_GDW3CNKSP5AOTDQ2YCKNGC6L65CE4JDX3JS5BV427OB54HCF2J4PUEVG.yml"))
from_pair = master

#to_pair = Stellar::KeyPair.random
to_pair  = YAML.load(File.open("./secret_keypair_live_GBPO4N6XOLOLW2EV6X2AEQMLKOBH3WF2IJCZEQU65SVVSN4JD44WORKD.yml"))
#from_pair = Stellar::KeyPair.random
#to_account = 'GDJUIEGLARHHM6IVNFEMV5HRX3A2CQV4YVRYUB5FEHDSBVAFENPKRHBA'
#to_pair = Stellar::KeyPair.from_address(to_account)
#to_pair = Stellar::KeyPair.from_seed("SDWTC2MQLFH5J5GBXUI4H4KIPHOFAKY77G7RQH6RDXORIX25NZAJEET5")

puts "from_pair #{from_pair.address}"
puts "to_pair   #{to_pair.address}"


amount = 10
before = Utils.get_native_balance(to_pair.address)
puts "after account creation balance = #{before}"

result = Utils.send_native(from_pair, to_pair.address, amount)
puts "#{result}"

after = Utils.get_native_balance(to_pair.address)
puts "after send_native #{amount} transaction  #{after}"

