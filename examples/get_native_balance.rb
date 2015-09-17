#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
require '../lib/stellar_utility/stellar_utility.rb'
Utils = Stellar_utility::Utils.new("horizon")
puts "Utils version: #{Utils.version}"
puts "configs: #{Utils.configs}"
puts ""

master  = Stellar::KeyPair.master
account = master.address
#account = 'GDJUIEGLARHHM6IVNFEMV5HRX3A2CQV4YVRYUB5FEHDSBVAFENPKRHBA'
#keypair = Stellar::KeyPair.random
#account = keypair.address


#result = Utils.get_native_balance_local(account)
#result = Utils.get_native_balance_horizon(account)
result = Utils.get_native_balance(account)
puts " native balance: #{result}"
