#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
require './stellar_utilities'

#my-stellar
#issuer_account = 'GCZSBCPPUPBGMESSKBZQVSUNEZZFFR37DDEZ3V2MUMUASWDOMS5PNUSA'
#to_pair = Stellar::KeyPair.from_seed("SCPY5UQQH4HZSKS3NZGZVWS2C7FOSEKK65M5QWKFRR4JQ3Q2D6VAJJWC")
#fred's

to_pair = Stellar::KeyPair.from_seed('SB2NQE7LDVNLZPI3VU5Y6SQFY4FHWB6XL5CMEPMIGM2E3G6ZQ3Y3AELX')
keypairA = YAML.load(File.open("./secret_keypairA.yml")) 
keypairB = YAML.load(File.open("./secret_keypairB.yml"))
keypairC = YAML.load(File.open("./secret_keypairC.yml")) 
keypairD = YAML.load(File.open("./secret_keypairD.yml"))
issuer_account = keypairA.address
issuer_pair = keypairA

currency = "USD"
limit = 10000
amount = 1000

result = add_trust(issuer_account,keypairB,"USD")
#result = add_trust(issuer_account,to_pair,currency,limit)
puts "#{result}"
sleep 11

result = send_currency(issuer_pair, keypairB, issuer_pair, amount, "USD")
puts "#{result}"
sleep 11

result = add_trust(issuer_account,keypairB,"CHP")
#result = add_trust(issuer_account,to_pair,currency,limit)
puts "#{result}"
sleep 12

result = send_currency(issuer_pair, keypairB, issuer_pair, amount, "CHP")
puts "#{result}"
sleep 11

result = add_trust(issuer_account,keypairB,"EUR")
#result = add_trust(issuer_account,to_pair,currency,limit)
puts "#{result}"
sleep 12

result = send_currency(issuer_pair, keypairB, issuer_pair, amount, "EUR")
puts "#{result}"
sleep 11

result = add_trust(issuer_account,keypairC,"CHP")
#result = add_trust(issuer_account,to_pair,currency,limit)
puts "#{result}"
sleep 12

result = send_currency(issuer_pair, keypairC, issuer_pair, amount, "CHP")
puts "#{result}"
sleep 11

result = add_trust(issuer_account,keypairC,"USD",10000)
#result = add_trust(issuer_account,to_pair,currency,limit)
puts "#{result}"
sleep 11

result = send_currency(issuer_pair, keypairC, issuer_pair, amount, "USD")
puts "#{result}"
sleep 11

result = add_trust(issuer_account,keypairC,"EUR",10000)
#result = add_trust(issuer_account,to_pair,currency,limit)
puts "#{result}"
sleep 11

result = send_currency(issuer_pair, keypairC, issuer_pair, amount, "EUR")
puts "#{result}"
sleep 11

result = add_trust(issuer_account,keypairD,"EUR",10000)
#result = add_trust(issuer_account,to_pair,currency,limit)
puts "#{result}"
sleep 11

result = send_currency(issuer_pair, keypairD, issuer_pair, amount, "EUR")
puts "#{result}"
sleep 11

result = add_trust(issuer_account,keypairD,"USD",10000)
#result = add_trust(issuer_account,to_pair,currency,limit)
puts "#{result}"
sleep 11

result = send_currency(issuer_pair, keypairD, issuer_pair, amount, "USD")
puts "#{result}"
sleep 11

result = add_trust(issuer_account,keypairD,"CHP",10000)
#result = add_trust(issuer_account,to_pair,currency,limit)
puts "#{result}"
sleep 11

result = send_currency(issuer_pair, keypairD, issuer_pair, amount, "CHP")
puts "#{result}"
sleep 11


