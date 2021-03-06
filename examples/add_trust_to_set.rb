#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
require './stellar_utilities'
# note: these accounts must be active and native funded if running on stellar network

#to_keypair = Stellar::KeyPair.from_seed('SB2NQE...')
keypairA = YAML.load(File.open("./secret_keypair_GBPJR44JZVXBGRXRQ7PN34IUERQOJ64OG44UIF7ICOIUWLN7H5MALVIU.yml")) 
keypairB = YAML.load(File.open("./secret_keypair_GBZH6Z74OWID6ZP67KYNF7T5ES4APLZSISYO7GZGXW7PJNMFL4XNV3PT.yml"))
keypairC = YAML.load(File.open("./secret_keypair_GCMZXKLCURDHSACMVOTWG67JWICOPUPV5GTI2LN6ZQCKBEIXHOFW7W4L.yml")) 
keypairD = YAML.load(File.open("./secret_keypair_GD3DYNE54777BUJLMZVML53LBKG4FQX523NJYOEXFFCZKKXAQABUQPT4.yml"))
issuer_account = keypairA.address
issuer_pair = keypairA

currency = "USD"
limit = 10000000
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


