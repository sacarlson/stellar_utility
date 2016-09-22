#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
#this should create an offer on even a freshly reset stellar-core as long as allmylifemy... has funds
# this is now tested as working with stellar-core branch  b179493a...
require '../lib/stellar_utility/stellar_utility.rb'

#Utils = Stellar_utility::Utils.new("horizon")
#Utils = Stellar_utility::Utils.new("./stellar_utilities_standalone.cfg")
Utils = Stellar_utility::Utils.new("./stellar_utilities.cfg")

puts "Utils version: #{Utils.version}"
puts "configs: #{Utils.configs}"

def reverse_order_base(order_pair)
  #order_pair = {"amount"=>1, "price"=>0.5}
  #transpose the orders base price to be reversed
  # example order sell AAA buy BBB at  amount = 2  price = .5  reversed will be amount = .5  price = 2
  # or amount = 1  price = 3  would be  amount =1 price = 0.3333 
  # this makes it posible to set your sell price by what you see BBB is selling for, as selling is always seen in the sellers base
  #puts "pair in: #{order_pair}"
  order_pair["price"] = 1/order_pair["price"].to_f
  order_pair["amount"] = 1/order_pair["amount"].to_f
  #puts "pair out: #{order_pair}"
  return order_pair
end

def offer_sets(orders_aray,master_hash=nil)
  #master_hash = {"amount"=>0.5, "price"=>3, "account_keypair"="...", "sell_issuer"=>"Gadfd...","sell_currency"=>"USD","buy_issuer"=>"Gdsa...","buy_currency"=>"YEN"}
  #orders_aray = [{"amount"=>1, "price"=>1},{"amount"=>1, "price"=>2},{"amount"=>1, "price"=>3},{"amount"=>2, "price"=>0.5}]
  puts ""
  puts "master_hash: #{master_hash}"
  puts "start buy orders loop"
  n = 0
  orders_aray.each do |set|
    if master_hash != nil
      puts "get here?"
      set.merge!(master_hash)      
    end
    puts "order # #{n}"
    puts "order set: #{set}"
    set = reverse_order_base(set)
    puts "amount: #{set["amount"]}  price: #{set["price"]}"
    b64 = Utils.offer(set["account_keypair"],set["sell_issuer"],set["sell_currency"], set["buy_issuer"], set["buy_currency"], set["amount"],set["price"])
    
    result = Utils.send_tx(b64)
    puts "send_tx result #{result}"
    n = n + 1
  end
end

master  = Stellar::KeyPair.master

if 1==0
  #setup standard test keypair files 
  Utils.create_key_testset_and_account(122)
end

issuer = YAML.load(File.open("./multi_sig_account_keypair.yml"))

buy_issuer = issuer
sell_issuer = buy_issuer
#sell_currency = "CHP"
#buy_currency = "BEER"
#sell_currency = "AAA"
#buy_currency = "BBB"
sell_currency = "CCC"
buy_currency = "DDD"
#amount = 2
#price = 95.15
#limit = 10000


if 1==1
  sellers_account = YAML.load(File.open("./signerA_keypair.yml"))
  buyers_account = YAML.load(File.open("./signerB_keypair.yml"))
else
  puts "swap trade direction of traders is now active"
  sellers_account = YAML.load(File.open("./signerB_keypair.yml"))
  buyers_account = YAML.load(File.open("./signerA_keypair.yml"))
end
puts "sellers_account: #{sellers_account.address}"
puts "sellers_account seed: #{sellers_account.seed}"
puts "buyers_account: #{buyers_account.address}"
puts "buyers_account seed: #{buyers_account.seed}"



trade_seller_hash = {"account_keypair"=>sellers_account, "sell_issuer"=>issuer.address,"sell_currency"=>sell_currency,"buy_issuer"=>issuer.address,"buy_currency"=>buy_currency}
trade_buyer_hash = {"account_keypair"=>buyers_account, "sell_issuer"=>issuer.address,"sell_currency"=>buy_currency,"buy_issuer"=>issuer.address,"buy_currency"=>sell_currency}
orders_aray = [{"amount"=>1, "price"=>1}]

if 1==1 #account already created and funded then disable this


if 1==0
  puts "create issuer accounts"
  result = Utils.create_account(issuer, master,10000)
  puts "result: #{result}"
  puts "create sellers_account"
  result = Utils.create_account(sellers_account, master,10000)
  puts "result: #{result}"
  puts "create buyer  accounts"
  result = Utils.create_account(buyers_account, master,10000)
  puts "result: #{result}"
end

if 1==0
  puts "add more native currency if needed"
  amount = 10000
  result = Utils.send_native(master,sellers_account, amount)
  result = Utils.send_native(master,buyers_account, amount)
end


if 1==1
  puts "add trustlines"
  result = Utils.add_trust(issuer,sellers_account,sell_currency)
  #result = Utils.add_trust(issuer_account,to_pair,currency,limit)
  puts "#{result}"
  result = Utils.add_trust(issuer,sellers_account,buy_currency)
  #result = Utils.add_trust(issuer_account,to_pair,currency,limit)
  puts "#{result}"
  result = Utils.add_trust(issuer,buyers_account,sell_currency)
  #result = Utils.add_trust(issuer_account,to_pair,currency,limit)
  puts "#{result}"
  result = Utils.add_trust(issuer,buyers_account,buy_currency)
  #result = Utils.add_trust(issuer_account,to_pair,currency,limit)
  puts "#{result}"
end



if 1==1
  amount = 1000000
  puts "fund the traders assets start all with the same 1M each currency"
  result = Utils.send_currency(issuer, sellers_account, issuer, amount, sell_currency)
  result = Utils.send_currency(issuer, buyers_account, issuer, amount, sell_currency)
  result = Utils.send_currency(issuer, sellers_account, issuer, amount, buy_currency)
  result = Utils.send_currency(issuer, buyers_account, issuer, amount, buy_currency)
end


end # fund creation and funding completed

puts "sellers account balances"
result = Utils.get_lines_balance(sellers_account,issuer,sell_currency)
puts "balance= #{result} #{sell_currency}"
result = Utils.get_lines_balance(sellers_account,issuer,buy_currency)
puts "balance = #{result} #{buy_currency}"

puts "buyers_account balances"
result = Utils.get_lines_balance(buyers_account,issuer,sell_currency)
puts "balance= #{result} #{sell_currency}"
result = Utils.get_lines_balance(buyers_account,issuer,buy_currency)
puts "balance = #{result} #{buy_currency}"
puts ""


#offer_sets(orders_aray, trade_seller_hash)
#orders_aray = [{"amount"=>1, "price"=>1}]
order = {"amount"=>1, "price"=>1}
order2 = {"amount"=>1, "price"=>1}
array = []
array2 = []
amount = 1
(0..20).each do |n|
  price = (1.15**n)-0.9
  price2 = (1.15**(20-n)) 
  puts "price:  #{price}" 
  puts "price2:  #{price2}" 
  #puts "n = #{n}  price #{v}  amount #{v.round(0)}"
  array.push({"amount"=>amount,"price"=>price})
  array2.push(reverse_order_base({"amount"=>amount,"price"=>price2}))  
end

puts "array: #{array}"
puts ""
puts "array2: #{array2}"


offer_sets(array, trade_seller_hash)
offer_sets(array2,trade_buyer_hash)
#orders_aray = [{"amount"=>1, "price"=>1}]

puts "sellers account balances"
result = Utils.get_lines_balance(sellers_account,issuer,sell_currency)
puts "balance= #{result} #{sell_currency}"
result = Utils.get_lines_balance(sellers_account,issuer,buy_currency)
puts "balance = #{result} #{buy_currency}"

puts "buyers_account balances"
result = Utils.get_lines_balance(buyers_account,issuer,sell_currency)
puts "balance= #{result} #{sell_currency}"
result = Utils.get_lines_balance(buyers_account,issuer,buy_currency)
puts "balance = #{result} #{buy_currency}"
