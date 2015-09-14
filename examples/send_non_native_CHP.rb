#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
# this tested ok
require './stellar_utilities'
# This will create an active to_pair and issuer_pair accounts and issue the to_pair CHP funds from issuer_pair
# this is just a test and to show how it's done.

master      = Stellar::KeyPair.from_raw_seed("allmylifemyhearthasbeensearching")
issuer_pair = YAML.load(File.open("./secret_keypair_GBPJR44JZVXBGRXRQ7PN34IUERQOJ64OG44UIF7ICOIUWLN7H5MALVIU.yml"))
to_pair = YAML.load(File.open("./secret_keypair_GDJUIEGLARHHM6IVNFEMV5HRX3A2CQV4YVRYUB5FEHDSBVAFENPKRHBA.yml"))
to_account = to_pair.address
if @configs["fee"] == 0
  starting_balance = 0
else
  starting_balance = 1000_000000
end

result = create_account(to_pair, master, starting_balance)
puts "#{result}"
sleep 11
result = create_account(issuer_pair, master, starting_balance)
puts "#{result}"
sleep 11

issuer_address = issuer_pair.address
currency = "CHP"
amount = 100000

result = add_trust(issuer_pair,to_pair,currency)
puts "add_trust to to_pair #{result}"
sleep 11

result = get_lines_balance(to_account,issuer_pair,currency)
puts "before balance: #{result}"

result = send_currency(issuer_pair, to_account, issuer_pair, amount, currency)
puts "send_currency issuer to from_pair#{result}"
sleep 11
result = get_lines_balance(to_account,issuer_pair,currency)
puts "after balance: #{result}"



