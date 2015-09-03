#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
require './stellar_utilities'
#this should create an offer on even a freshly reset stellar-core as long as allmylifemy... has funds
# this is now tested as working with stellar-core branch  b179493a...

master      = Stellar::KeyPair.from_raw_seed("allmylifemyhearthasbeensearching")
sellers_account = Stellar::KeyPair.random
to_file = "./secret_keypair_"+sellers_account.address+".yml"
puts "save sellers_account keypair to file #{to_file}"
File.open(to_file, "w") {|f| f.write(sellers_account.to_yaml) }
if @configs["fee"] == 0
  starting_balance = 0
else
  starting_balance = 1000_000000
end

result = create_account(sellers_account, master, starting_balance)
puts "create_account results #{result}"
sleep 10

buy_issuer = YAML.load(File.open("./secret_keypair_GBPJR44JZVXBGRXRQ7PN34IUERQOJ64OG44UIF7ICOIUWLN7H5MALVIU.yml"))
result = create_account(buy_issuer, master, starting_balance)
puts "result create_account buy_issuer #{result}"
sleep 11


sell_issuer = buy_issuer
sell_currency = "BEER"
#sell_currency = "CHP"
buy_currency = "USD"
amount = 500
price = 0.00202003
#limit = 10000

result = add_trust(buy_issuer,sellers_account,sell_currency)
#result = add_trust(issuer_account,to_pair,currency,limit)
puts "#{result}"
sleep 11
result = add_trust(buy_issuer,sellers_account,buy_currency)
#result = add_trust(issuer_account,to_pair,currency,limit)
puts "#{result}"
sleep 11

result = send_currency(buy_issuer, sellers_account, sell_issuer, amount*10, sell_currency)
puts "send_currency issuer to from_pair#{result}"
sleep 11

seq = next_sequence(sellers_account)
puts "next_seq on sellers_account #{seq}"

b64 = offer(sellers_account,sell_issuer,sell_currency, buy_issuer, buy_currency,amount,price)
result = send_tx(b64)
puts "send_tx result #{result}"
