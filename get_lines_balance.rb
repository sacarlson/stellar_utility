#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
require './stellar_utilities'
#works sep 12, 2015

currency = "CHP"
issuer = 'GAC2ZUXVI5266NMMGDPBMXHH4BTZKJ7MMTGXRZGX2R5YLMFRYLJ7U5EA'
#account = Stellar::KeyPair.random
account = 'GCW55ICD6QFJ6UZNFXIMVMHDF7GD55LT6R6MCCTZVEWCPUPWLLJKWIM6'
 

result = get_lines_balance(account,issuer,currency)
puts "balance = #{result} #{currency}"

