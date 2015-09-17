#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
# note: I can't get this to work yet Aug 12, 2015
# see sign_multi_sign_transactions_test.rb that has a closer to working merge_tx
# when I get that working I'll fix this as a demo
require '../lib/stellar_utility/stellar_utility.rb'
Utils = Stellar_utility::Utils.new("horizon")
puts "Utils version: #{Utils.version}"
puts "configs: #{Utils.configs}"
puts ""

#master      = Stellar::KeyPair.from_raw_seed("allmylifemyhearthasbeensearching")
master  = eval( @configs["master_keypair"])

create_key_testset_and_account(0)

from_pair = YAML.load(File.open("./multi_sig_account_keypair.yml"))
to_pair = YAML.load(File.open("./signerA_keypair.yml"))
#signerB_keypair = YAML.load(File.open("./signerB_keypair.yml"))
result = create_account(to_pair, master, starting_balance=50)
puts "#{result}"
result = create_account(from_pair, master, starting_balance=50)
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

result = Utils.get_native_balance(to_pair)
puts "#{result}"

