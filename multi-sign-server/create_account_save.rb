#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
require 'yaml'
require './stellar_utilities'

#Stellar.on_network(Stellar::Networks::TESTNET, something_that_runs?)
if @configs["fee"] == 0
  starting_balance = 0
elsif @configs["version"] == "fred"
  starting_balance = 1000_000000
  master      = Stellar::KeyPair.from_raw_seed("allmylifemyhearthasbeensearching") 
else
  #Stellar.default_network = Stellar::Networks::TESTNET
  Stellar.default_network = eval(@configs["default_network"])
  rs = Stellar.current_network
  puts "current_network = #{rs}"
  starting_balance = @configs["start_balance"]
  #starting_balance = 25_000000
  #master       = Stellar::KeyPair.from_seed("SCGMPTPTZEKZFTZNJ6UQUNNTYETY4ZUPC7SQXZTFUQKKUGKLR5HUDTJU") 
  master  = eval( @configs["master_keypair"])
end

#master      = Stellar::KeyPair.from_raw_seed("allmylifemyhearthasbeensearching")
#master       = Stellar::KeyPair.from_seed("SCGMPTPTZEKZFTZNJ6UQUNNTYETY4ZUPC7SQXZTFUQKKUGKLR5HUDTJU")
#address: GBMC5TIM6WOYJYOZ43MVXXWSPJHSYOFEPOFIORQAPWM5CQK2CYQLVAPD,
#seed: SCGMPTPTZEKZFTZNJ6UQUNNTYETY4ZUPC7SQXZTFUQKKUGKLR5HUDTJU
# from friendbot https://www.stellar.org/galaxy/ only has  "balance": "100.0000000"

puts "stellar-base version: #{Gem.loaded_specs["stellar-base"].version}"
puts "starting_balance: #{starting_balance}"
puts "master address #{master.address}"
puts "master seed #{master.seed}"

destination = Stellar::KeyPair.random
#destination = Stellar::KeyPair.from_seed("SDWTC2MQLFH5J5GBXUI4H4KIPHOFAKY77G7RQH6RDXORIX25NZAJEET5")
to_file = "./secret_keypair_"+destination.address+".yml"
puts "save to file #{to_file}"

File.open(to_file, "w") {|f| f.write(destination.to_yaml) }

#destination = YAML.load(File.open("./secret_keypair.yml")) 

puts "destination address #{destination.address}"
puts "destination seed #{destination.seed}"

result = create_account(destination, master, starting_balance)
puts "#{result}"
