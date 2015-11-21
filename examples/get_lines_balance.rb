#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
require '../lib/stellar_utility/stellar_utility.rb'
#Utils = Stellar_utility::Utils.new("horizon")
Utils = Stellar_utility::Utils.new("mss")
puts "Utils version: #{Utils.version}"
puts "configs: #{Utils.configs}"
puts ""

currency = "AAA"
issuer = 'GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF'
#account = Stellar::KeyPair.random

account = 'GAMCHGO4ECUREZPKVUCQZ3NRBZMK6ESEQVHPRZ36JLUZNEH56TMKQXEB'
 

result = Utils.get_lines_balance(account,issuer,currency)
puts "balance = #{result} #{currency}"

