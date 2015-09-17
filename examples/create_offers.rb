#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
#this should create an offer on even a freshly reset stellar-core as long as allmylifemy... has funds
# this is now tested as working with stellar-core branch  b179493a...
require '../lib/stellar_utility/stellar_utility.rb'

Utils = Stellar_utility::Utils.new("horizon")
puts "Utils version: #{Utils.version}"
puts "configs: #{Utils.configs}"
puts ""
master  = Stellar::KeyPair.master
sellers_account = Stellar::KeyPair.random
to_file = "./secret_keypair_"+sellers_account.address+".yml"
puts "save sellers_account keypair to file #{to_file}"
File.open(to_file, "w") {|f| f.write(sellers_account.to_yaml) }

result = Utils.create_account(sellers_account, master)
puts "create_account results #{result}"
sleep 10

#this secret_keypair will have to be replaced as I've already deleted it
#use create_account_save.rb to make a new secret_keypair of your own and add it here.
buy_issuer = YAML.load(File.open("./secret_keypair_GBPJR44JZVXBGRXRQ7PN34IUERQOJ64OG44UIF7ICOIUWLN7H5MALVIU.yml"))
result = Utils.create_account(buy_issuer, master)
puts "result create_account buy_issuer #{result}"
sleep 11


sell_issuer = buy_issuer
sell_currency = "BEER"
#sell_currency = "CHP"
buy_currency = "USD"
amount = 500
price = 0.00202003
#limit = 10000

result = Utils.add_trust(buy_issuer,sellers_account,sell_currency)
#result = Utils.add_trust(issuer_account,to_pair,currency,limit)
puts "#{result}"
sleep 11
result = Utils.add_trust(buy_issuer,sellers_account,buy_currency)
#result = Utils.add_trust(issuer_account,to_pair,currency,limit)
puts "#{result}"
sleep 11

result = Utils.send_currency(buy_issuer, sellers_account, sell_issuer, amount*10, sell_currency)
puts "send_currency issuer to from_pair#{result}"
sleep 11

seq = Utils.next_sequence(sellers_account)
puts "next_seq on sellers_account #{seq}"

b64 = Utils.offer(sellers_account,sell_issuer,sell_currency, buy_issuer, buy_currency,amount,price)
result = Utils.send_tx(b64)
puts "send_tx result #{result}"
