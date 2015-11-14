#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
#this should create an offer on even a freshly reset stellar-core as long as allmylifemy... has funds
# this is now tested as working with stellar-core branch  b179493a...
require '../lib/stellar_utility/stellar_utility.rb'

#Utils = Stellar_utility::Utils.new("horizon")
Utils = Stellar_utility::Utils.new()
puts "Utils version: #{Utils.version}"
puts "configs: #{Utils.configs}"
puts ""
issuer = YAML.load(File.open("./secret_keypair_Live_GDW3CNKSP5AOTDQ2YCKNGC6L65CE4JDX3JS5BV427OB54HCF2J4PUEVG.yml"))
sellers_account = YAML.load(File.open("./secret_keypair_live_GBPO4N6XOLOLW2EV6X2AEQMLKOBH3WF2IJCZEQU65SVVSN4JD44WORKD.yml"))


buy_issuer = issuer
sell_issuer = buy_issuer
sell_currency = "CHP"
#sell_currency = "CHP"
buy_currency = "BEER"
amount = 2
price = 95.15
#limit = 10000



b64 = Utils.offer(sellers_account,sell_issuer,sell_currency, buy_issuer, buy_currency,amount,price)
result = Utils.send_tx(b64)
puts "send_tx result #{result}"
