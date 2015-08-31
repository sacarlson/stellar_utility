#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
# this tested ok
require './stellar_utilities'
# note: in this case to issue BEER both accounts must be already active and funded with native lunes

issuer_pair = YAML.load(File.open("./secret_keypair_GBPJR44JZVXBGRXRQ7PN34IUERQOJ64OG44UIF7ICOIUWLN7H5MALVIU.yml"))
#to_account = 'GBZH6Z74OWID6ZP67KYNF7T5ES4APLZSISYO7GZGXW7PJNMFL4XNV3PT'
#to_account = 'GDJUIEGLARHHM6IVNFEMV5HRX3A2CQV4YVRYUB5FEHDSBVAFENPKRHBA'
#to_pair = YAML.load(File.open("./secret_keypair_GBZH6Z74OWID6ZP67KYNF7T5ES4APLZSISYO7GZGXW7PJNMFL4XNV3PT.yml"))
to_pair = YAML.load(File.open("./secret_keypair_GDJUIEGLARHHM6IVNFEMV5HRX3A2CQV4YVRYUB5FEHDSBVAFENPKRHBA.yml"))
to_account = to_pair.address

issuer_address = issuer_pair.address
currency = "CHP"
amount = 100000

#result = add_trust(issuer_pair,to_pair,currency)
#puts "add_trust to to_pair #{result}"
#sleep 11

result = get_lines_balance(to_account,currency)
puts "before balance: #{result}"

result = send_currency(issuer_pair, to_account, issuer_pair, amount, currency)
puts "send_currency issuer to from_pair#{result}"
sleep 11
result = get_lines_balance(to_account,currency)
puts "after balance: #{result}"



