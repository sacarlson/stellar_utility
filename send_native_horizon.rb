#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
require './stellar_utilities'
# This will create two active accounts with funds of 1000 lunes funded from the master account
# it will then setup a native lunes transaction between the two accounts.
# in this case it uses the horizion-test.stellar.org api interface to do the transactions.
# this is just an example to show how it's done and how it works and to test if it does work.


master      = Stellar::KeyPair.from_raw_seed("allmylifemyhearthasbeensearching")
to_pair = Stellar::KeyPair.random
#to_account = 'GDJUIEGLARHHM6IVNFEMV5HRX3A2CQV4YVRYUB5FEHDSBVAFENPKRHBA'
#to_pair = Stellar::KeyPair.from_address(to_account)
#to_pair = Stellar::KeyPair.from_seed("SDWTC2MQLFH5J5GBXUI4H4KIPHOFAKY77G7RQH6RDXORIX25NZAJEET5")
#from_pair = Stellar::KeyPair.from_seed("SAPMOIEX4WH3AB4FAG2YW32OSI5HCUVWHE7UBV35GMAEOTAIOFANFCZK")

result = get_account_info_horizon(master.address)
puts " master account info #{result}"

from_pair = Stellar::KeyPair.random
puts "#{from_pair.address}"
result = create_account_horizon(from_pair, master, starting_balance=1000_0000000)
puts "#{result}"
sleep 10
result = create_account_horizon(to_pair, master, starting_balance=1000_0000000)
puts "#{result}"
sleep 10

amount = 5
before = get_native_balance_horizon(to_pair.address)
#get_native_balance(account)
puts "before balance = #{before}"
#result = send_native(from_pair, to_pair.address, amount)
result = send_native_horizon(from_pair, to_pair.address, amount)
puts "#{result}"
sleep 10
after = get_native_balance_horizon(to_pair.address)
puts "after send_native #{after}"

puts "#{result}"

__END__

