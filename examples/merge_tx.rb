#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
# this was a test and proof of the tx_merge function
# note: this was now working on Oct 7 2015

require '../lib/stellar_utility/stellar_utility.rb'
#Utils = Stellar_utility::Utils.new("horizon")
Utils = Stellar_utility::Utils.new()
puts "Utils version: #{Utils.version}"
puts "configs: #{Utils.configs}"
puts ""

#master      = Stellar::KeyPair.from_raw_seed("allmylifemyhearthasbeensearching")
#master  = eval( @configs["master_keypair"])
master  = Stellar::KeyPair.master

Utils.create_key_testset_and_account(0)

from_pair = YAML.load(File.open("./multi_sig_account_keypair.yml"))
to_pair = YAML.load(File.open("./signerA_keypair.yml"))
#signerB_keypair = YAML.load(File.open("./signerB_keypair.yml"))
result = Utils.create_account(to_pair, master, starting_balance=50)
puts "#{result}"
result = Utils.create_account(from_pair, master, starting_balance=50)
puts "#{result}"


puts "from_pair.address:  #{from_pair.address}"
puts "to_pair.address:    #{to_pair.address}"

#send_native_tx(from_pair, to_account, amount, seqadd=0)
tx1 = Utils.send_native_tx(from_pair, to_pair.address, 1)
tx2 = Utils.send_native_tx(from_pair, to_pair.address, 2)
tx3 = Utils.send_native_tx(from_pair, to_pair.address, 3)
# if all 3 tx above do work, the output should have 6 more native balance 1+2+3

tx = Utils.tx_merge(tx1,tx2,tx3)
b64 = tx.to_envelope(from_pair).to_xdr(:base64)

result = Utils.get_native_balance(to_pair)
puts "#{result}"

result = Utils.send_tx(b64)
puts "#{result}"

#result after complete was a bal of 114 started at 118 so it worked!!
result = Utils.get_native_balance(to_pair)
puts "#{result}"

