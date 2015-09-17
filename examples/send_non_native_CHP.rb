#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
# this tested ok
# This will create an active to_pair and issuer_pair accounts and issue the to_pair CHP funds from issuer_pair
# this is just a test and to show how it's done.
require '../lib/stellar_utility/stellar_utility.rb'
Utils = Stellar_utility::Utils.new("horizon")
puts "Utils version: #{Utils.version}"
puts "configs: #{Utils.configs}"
puts ""
master  = Stellar::KeyPair.master
# these files will have to be replaced with your own secrete_keypairs see create_account_save.rb for details
issuer_pair = YAML.load(File.open("./secret_keypair_GBPJR44JZVXBGRXRQ7PN34IUERQOJ64OG44UIF7ICOIUWLN7H5MALVIU.yml"))
to_pair = YAML.load(File.open("./secret_keypair_GDJUIEGLARHHM6IVNFEMV5HRX3A2CQV4YVRYUB5FEHDSBVAFENPKRHBA.yml"))
to_account = to_pair.address

result = Utils.create_account(to_pair, master)
puts "#{result}"

result = Utils.create_account(issuer_pair, master)
puts "#{result}"

issuer_address = issuer_pair.address
currency = "CHP"
amount = 100000

result = Utils.add_trust(issuer_pair,to_pair,currency)
puts "add_trust to to_pair #{result}"

result = Utils.get_lines_balance(to_account,issuer_pair,currency)
puts "before balance: #{result}"

result = Utils.send_currency(issuer_pair, to_account, issuer_pair, amount, currency)
puts "send_currency issuer to from_pair#{result}"

result = Utils.get_lines_balance(to_account,issuer_pair,currency)
puts "after balance: #{result}"



