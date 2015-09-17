#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
require '../lib/stellar_utility/stellar_utility.rb'
Utils = Stellar_utility::Utils.new("horizon")
puts "Utils version: #{Utils.version}"
puts "configs: #{Utils.configs}"
puts ""

currency = "CHP"
issuer = 'GAC2ZUXVI5266NMMGDPBMXHH4BTZKJ7MMTGXRZGX2R5YLMFRYLJ7U5EA'
#account = Stellar::KeyPair.random
account = 'GCW55ICD6QFJ6UZNFXIMVMHDF7GD55LT6R6MCCTZVEWCPUPWLLJKWIM6'
 

result = Utils.get_lines_balance(account,issuer,currency)
puts "balance = #{result} #{currency}"

