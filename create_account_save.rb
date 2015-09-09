#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
require 'yaml'
require './stellar_utilities'
#Stellar.default_network = Stellar::Networks::TESTNET
Stellar.on_network(Stellar::Networks::TESTNET)

#master      = Stellar::KeyPair.from_raw_seed("allmylifemyhearthasbeensearching")
master       = Stellar::KeyPair.from_seed("SCGMPTPTZEKZFTZNJ6UQUNNTYETY4ZUPC7SQXZTFUQKKUGKLR5HUDTJU")
#address: GBMC5TIM6WOYJYOZ43MVXXWSPJHSYOFEPOFIORQAPWM5CQK2CYQLVAPD,
#seed: SCGMPTPTZEKZFTZNJ6UQUNNTYETY4ZUPC7SQXZTFUQKKUGKLR5HUDTJU
# from friendbot https://www.stellar.org/galaxy/ only has  "balance": "100.0000000"

rs = Stellar.current_network
puts "current_network = #{rs}"
puts "and  #{@default_network}"
exit -1
destination = Stellar::KeyPair.random
#destination = Stellar::KeyPair.from_seed("SDWTC2MQLFH5J5GBXUI4H4KIPHOFAKY77G7RQH6RDXORIX25NZAJEET5")
to_file = "./secret_keypair_"+destination.address+".yml"
puts "save to file #{to_file}"

File.open(to_file, "w") {|f| f.write(destination.to_yaml) }
if @configs["fee"] == 0
  starting_balance = 0
else
  starting_balance = 25.0
end

#destination = YAML.load(File.open("./secret_keypair.yml")) 

puts "master address #{master.address}"
puts "master seed #{master.seed}"

puts "destination address #{destination.address}"
puts "destination seed #{destination.seed}"

result = create_account(destination, master, starting_balance)
puts "#{result}"
