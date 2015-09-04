#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
# this tested ok
require './stellar_utilities'
# note: in this case to issue BEER both accounts must be already be active and funded with native if needed on that network

issuer_pair = YAML.load(File.open("./secret_keypair_GBZH6Z74OWID6ZP67KYNF7T5ES4APLZSISYO7GZGXW7PJNMFL4XNV3PT.yml"))
puts "issuer acc #{issuer_pair.address}"
puts "issuer seed #{issuer_pair.seed}"

#to_account = 'GBZH6Z74OWID6ZP67KYNF7T5ES4APLZSISYO7GZGXW7PJNMFL4XNV3PT'
#issuer_account = 'GBZH6Z74OWID6ZP67KYNF7T5ES4APLZSISYO7GZGXW7PJNMFL4XNV3PT'
#buhrmi's account GD5GK...
to_account = 'GD5GK7WBU27XXAGD6J75JOLF7WVFGH2RXEBLOQ6OCVJTIA2JZDJLXAJ3' 
#to_pair = YAML.load(File.open("./secret_keypair_GBZH6Z74OWID6ZP67KYNF7T5ES4APLZSISYO7GZGXW7PJNMFL4XNV3PT.yml"))
#to_account = to_pair.address

issuer_address = issuer_pair.address
currency = "beer"
amount = 3


#add_trust_tx(issuer_account,to_pair,currency,limit=(2**63)-1)
result = add_trust(to_account,issuer_pair,currency)
puts "add_trust to to_pair #{result}"
sleep 11

#result = get_lines_balance(to_account,issuer_pair,currency)
#puts "before balance: #{result}"

#send_currency(from_account_pair, to_account_pair, issuer_pair, amount, currency)
#note above that only from_account_pair needs to be a pair with seed, the to_account and issuer_pair can also be just account address
result = send_currency(issuer_pair, to_account, issuer_pair, amount, currency)
puts "send_currency issuer to from_pair#{result}"
sleep 11
result = get_lines_balance(to_account,issuer_pair,currency)
puts "before balance: #{result}"



