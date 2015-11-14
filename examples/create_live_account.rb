#!/usr/bin/ruby
require '../lib/stellar_utility/stellar_utility.rb'

#Utils = Stellar_utility::Utils.new("horizon")
Utils = Stellar_utility::Utils.new()
puts "Utils version: #{Utils.version}"
puts "configs: #{Utils.configs}"

master = YAML.load(File.open("./secret_keypair_Live_GDW3CNKSP5AOTDQ2YCKNGC6L65CE4JDX3JS5BV427OB54HCF2J4PUEVG.yml"))

#master  = eval( @configs["master_keypair"])

destination = Stellar::KeyPair.random
#destination = Stellar::KeyPair.from_seed("SYXIOZ.....")

#new master live account
#GDW3CNKSP5AOTDQ2YCKNGC6L65CE4JDX3JS5BV427OB54HCF2J4PUEVG

to_file = "./secret_keypair_"+destination.address+".yml"
puts "save to file #{to_file}"

File.open(to_file, "w") {|f| f.write(destination.to_yaml) }


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


