#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
require 'yaml'
require './stellar_utilities'

keypairA = YAML.load(File.open("./secret_keypairA.yml"))
keypairB = YAML.load(File.open("./secret_keypairB.yml"))
keypairC = YAML.load(File.open("./secret_keypairC.yml"))
keypairD = YAML.load(File.open("./secret_keypairD.yml"))
buy_issuer = keypairA
sell_issuer = keypairA
account = keypairC
sell_currency = "EUR"
buy_currency = "USD"
amount = 2
price = 0.6

b64 = offer(account,sell_issuer,sell_currency, buy_issuer, buy_currency,amount,price)
result = send_tx(b64)
puts "#{result}"
