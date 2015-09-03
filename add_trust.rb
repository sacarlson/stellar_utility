#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
require './stellar_utilities'


master      = Stellar::KeyPair.from_raw_seed("allmylifemyhearthasbeensearching")
issuer_account = 'GBPJR44JZVXBGRXRQ7PN34IUERQOJ64OG44UIF7ICOIUWLN7H5MALVIU'
#to_pair = Stellar::KeyPair.from_seed('SB2N...')
#to_pair = YAML.load(File.open("./secret_keypair_GBZH6Z74OWID6ZP67KYNF7T5ES4APLZSISYO7GZGXW7PJNMFL4XNV3PT.yml"))
issuer_pair = YAML.load(File.open("./secret_keypair_GBPJR44JZVXBGRXRQ7PN34IUERQOJ64OG44UIF7ICOIUWLN7H5MALVIU.yml"))
issuer_account = issuer_pair.address
to_pair = YAML.load(File.open("./secret_keypair_GDJUIEGLARHHM6IVNFEMV5HRX3A2CQV4YVRYUB5FEHDSBVAFENPKRHBA.yml"))
if @configs["fee"] == 0
  starting_balance = 0
else
  starting_balance = 1000_000000
end


result = create_account(issuer_pair, master, starting_balance)
puts "#{result}"
sleep 11

result = create_account(to_pair, master, starting_balance)
puts "#{result}"
sleep 11

currency = "BEER"
#limit = 10000000

result = add_trust(issuer_account,to_pair,currency)
#result = add_trust(issuer_account,to_pair,currency,limit)
puts "#{result}"


sleep 12

result = add_trust(issuer_account,to_pair,"CHP")
#result = add_trust(issuer_account,to_pair,currency,limit)
puts "#{result}"

sleep 12

result = add_trust(issuer_account,to_pair,"ABCD",10000)
#result = add_trust(issuer_account,to_pair,currency,limit)
puts "#{result}"




