#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com

require '../lib/stellar_utility/stellar_utility.rb'
Utils = Stellar_utility::Utils.new("horizon")
puts "Utils version: #{Utils.version}"
puts "configs: #{Utils.configs}"
puts ""

master  = Stellar::KeyPair.master
account = master.address
#account = 'GANOA5VBG3OMPMO7TG5NQD35IOHI627VBJYMXGPCUUFQRDGCT4MGPLL2'
#account = 'GD5GK7WBU27XXAGD6J75JOLF7WVFGH2RXEBLOQ6OCVJTIA2JZDJLXAJ3'

seq = Utils.get_sequence_local(account)

puts "seq = #{seq}"
