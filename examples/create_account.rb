#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
require '../lib/stellar_utility/stellar_utility.rb'

Utils = Stellar_utility::Utils.new("horizon")
puts "Utils version: #{Utils.version}"
puts "configs: #{Utils.configs}"

master      = Stellar::KeyPair.from_raw_seed("allmylifemyhearthasbeensearching")
# original master address and seed but I note it looks someone cleaned it out at some point on testnet
# GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ
# SBQWY3DNPFWGSZTFNV4WQZLBOJ2GQYLTMJSWK3TTMVQXEY3INFXGO52X
master  = Stellar::KeyPair.master
destination = Stellar::KeyPair.random

puts "master address #{master.address}"
puts "master seed #{master.seed}"

puts "destination address #{destination.address}"
puts "destination seed #{destination.seed}"
exit -1
result = create_account(destination, master, starting_balance)
puts "#{result}"
# this body thing didn't work
#puts "#{result.body}"
