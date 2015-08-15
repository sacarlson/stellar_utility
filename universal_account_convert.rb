#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
require './stellar_utilities'
# this demonstrates the account convert functions
# it shows that you can pass them ether a String or Stellar::KeyPair to convert only if needed.
# these functions were created due to my forgeting what format was needed to send functions, so no I can send ether
 
to_pair = Stellar::KeyPair.random
to_account = 'GDJUIEGLARHHM6IVNFEMV5HRX3A2CQV4YVRYUB5FEHDSBVAFENPKRHBA'

puts "to_account class #{to_account.class}"
puts "to_pair class #{to_pair.class}"

result = convert_keypair_to_address(to_account)
puts "#{result}"
result = convert_keypair_to_address(to_pair)
puts "#{result}"
result = convert_address_to_keypair(to_account)
puts "#{result.address}"
result = convert_address_to_keypair(to_pair)
puts "#{result.address}"



