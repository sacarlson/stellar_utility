#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
require './stellar_utilities'
# this demonstrates the account convert functions that converts string address to keypair and keypair to string address
# it shows that you can pass them ether a String or Stellar::KeyPair to convert only if needed.
# these functions were created due to my forgeting what format was needed to send functions, so now I can send ether
# as long as you know you don't need the seed then you can send ether one needed, if you know you need the secret key
# then just be sure to send a Stellar::KeyPair that has one in in.  most my functions that can use this already have it.
 
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



