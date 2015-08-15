#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
require './stellar_utilities'

currency = "USD"
account = Stellar::KeyPair.random
account = 'GDPT2URQHZEEY4SFEJMP5BGOADOUMGRZD7IUFSIJ6GC4P26OX2XEEXFN'

result = get_lines_balance(account,currency)
puts "#{result}"

