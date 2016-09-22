#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
# this tested ok
# a test that sets up 3 active funded accounts that are issuer_pair, from_pair, to_pair
# it then sets up needed trustlines on the accounts that need them, then has the issuer send the from_pair account some CHP assets
# then the from_pair sends the to_pair some CHP assets just to show how it's done and verify it works.
#works sept 14, 2015

require '../lib/stellar_utility/stellar_utility.rb'

#Utils = Stellar_utility::Utils.new("horizon")
Utils = Stellar_utility::Utils.new()
puts "Utils version: #{Utils.version}"
puts "configs: #{Utils.configs}"


from_pair  = YAML.load(File.open("./secret_keypair_Live_GDW3CNKSP5AOTDQ2YCKNGC6L65CE4JDX3JS5BV427OB54HCF2J4PUEVG.yml"))
issuer_address = from_pair
currency = "BEER"
amount = "1000"
#to_account = "GDVXG2FMFFSUMMMBIUEMWPZAIU2FNCH7QNGJMWRXRD6K5FZK5KJS4DDR"
to_account  = YAML.load(File.open("./secret_keypair_live_GBPO4N6XOLOLW2EV6X2AEQMLKOBH3WF2IJCZEQU65SVVSN4JD44WORKD.yml"))

result = Utils.add_trust(issuer_address,to_account,currency)
puts "add_trust result: #{result}"

exit -1
result = Utils.get_lines_balance(to_account, issuer_address, currency)
puts "before balance: #{result}"

result = Utils.send_currency(from_pair, to_account, issuer_address, amount, currency)
puts "send_currency from_pair to to_pair #{result}"

result = Utils.get_lines_balance(to_account, issuer_address, currency)
puts "after balance: #{result}"


