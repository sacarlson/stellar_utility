#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
require './stellar_utilities'

currency = "beer"
issuer = 'GBZH6Z74OWID6ZP67KYNF7T5ES4APLZSISYO7GZGXW7PJNMFL4XNV3PT'
#account = Stellar::KeyPair.random
account = 'GD5GK7WBU27XXAGD6J75JOLF7WVFGH2RXEBLOQ6OCVJTIA2JZDJLXAJ3'
 

result = get_lines_balance(account,issuer,currency)
puts "balance = #{result} #{currency}"

