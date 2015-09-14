#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
#require 'yaml'
require '../lib/stellar_utility/stellar_utility.rb'

Utils = Stellar_utility::Utils.new("horizon")
puts "Utils version: #{Utils.version}"
puts "configs: #{Utils.configs}"

puts "stellar-base version: #{Gem.loaded_specs["stellar-base"].version}"

#master  = eval( @configs["master_keypair"])
master  = Stellar::KeyPair.master
destination = Stellar::KeyPair.random
#destination = Stellar::KeyPair.from_seed("SDWTC2MQLFH5J5GBXUI4H4KIPHOFAKY77G7RQH6RDXORIX25NZAJEET5")
to_file = "./secret_keypair_"+destination.address+".yml"
puts "save to file #{to_file}"

File.open(to_file, "w") {|f| f.write(destination.to_yaml) }


#destination = YAML.load(File.open("./secret_keypair.yml")) 

puts "master address #{master.address}"
puts "master seed #{master.seed}"

puts "destination address #{destination.address}"
puts "destination seed #{destination.seed}"
result = Utils.get_native_balance(destination.address)
puts "before balance = #{result}"
result = Utils.create_account(destination, master)
puts "#{result}"
result= Utils.get_native_balance(destination.address)
puts "after balance = #{result}"
