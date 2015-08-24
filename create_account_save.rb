#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
require 'yaml'
require './stellar_utilities'

master      = Stellar::KeyPair.from_raw_seed("allmylifemyhearthasbeensearching")
destination = Stellar::KeyPair.random
#File.open("./secret_keypairE.yml", "w") {|f| f.write(destination.to_yaml) }
#destination = YAML.load(File.open("./secret_keypair.yml")) 

puts "master address #{master.address}"
puts "master seed #{master.seed}"

puts "destination address #{destination.address}"
puts "destination seed #{destination.seed}"

result = create_account(destination, master, starting_balance=1000_0000000)
puts "#{result}"