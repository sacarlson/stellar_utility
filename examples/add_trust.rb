#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com

require '../lib/stellar_utility/stellar_utility.rb'
Utils = Stellar_utility::Utils.new("horizon")
puts "Utils version: #{Utils.version}"
puts "configs: #{Utils.configs}"
puts ""

master  = Stellar::KeyPair.master

#the secrete files will have to be replaced with your own
#they can be created with create_account_save.rb
issuer_pair = YAML.load(File.open("./secret_keypair_GBPJR44JZVXBGRXRQ7PN34IUERQOJ64OG44UIF7ICOIUWLN7H5MALVIU.yml"))
issuer_account = issuer_pair.address
to_pair = YAML.load(File.open("./secret_keypair_GDJUIEGLARHHM6IVNFEMV5HRX3A2CQV4YVRYUB5FEHDSBVAFENPKRHBA.yml"))

result = Utils.create_account(issuer_pair, master)
puts "#{result}"
sleep 11

result = Utils.create_account(to_pair, master)
puts "#{result}"
sleep 11

currency = "BEER"
#limit = 10000000

result = Utils.add_trust(issuer_account,to_pair,currency)
#result = Utils.add_trust(issuer_account,to_pair,currency,limit)
puts "#{result}"


sleep 12

result = add_trust(issuer_account,to_pair,"CHP")
#result = add_trust(issuer_account,to_pair,currency,limit)
puts "#{result}"

sleep 12

result = add_trust(issuer_account,to_pair,"ABCD",10000)
#result = add_trust(issuer_account,to_pair,currency,limit)
puts "#{result}"




