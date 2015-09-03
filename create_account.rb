#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com

require './stellar_utilities'

master      = Stellar::KeyPair.from_raw_seed("allmylifemyhearthasbeensearching")
destination = Stellar::KeyPair.random
if @configs["fee"] == 0
  starting_balance = 0
else
  starting_balance = 1000_000000
end

puts "master address #{master.address}"
puts "master seed #{master.seed}"

puts "destination address #{destination.address}"
puts "destination seed #{destination.seed}"

result = create_account(destination, master, starting_balance)
puts "#{result}"
# this body thing didn't work
#puts "#{result.body}"
