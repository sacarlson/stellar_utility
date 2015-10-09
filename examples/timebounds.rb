#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
#This demonstrates and tests the new function tx = Utils.add_timebounds(tx,min,max) to create transactions with time bounds
#this was now working on Oct 9, 2015

require '../lib/stellar_utility/stellar_utility.rb'
#Utils = Stellar_utility::Utils.new("horizon")
Utils = Stellar_utility::Utils.new()
puts "Utils version: #{Utils.version}"
puts "configs: #{Utils.configs}"
puts ""

master  = Stellar::KeyPair.master

Utils.create_key_testset_and_account(122)
multi_sig_account_keypair = YAML.load(File.open("./multi_sig_account_keypair.yml"))
signerA_keypair = YAML.load(File.open("./signerA_keypair.yml"))
signerB_keypair = YAML.load(File.open("./signerB_keypair.yml"))
signerC_keypair = YAML.load(File.open("./secret_keypair_GCYSIZB4Q6ISTHFDXQMBBUPI4BVY7KW6QKCIZKTXAQBDXQYGRRIUTYSX.yml"))
puts "multi: #{multi_sig_account_keypair.address}"
puts "signerA: #{signerA_keypair.address}"
puts "signerB: #{signerB_keypair.address}"
puts "signerC: #{signerC_keypair.address}"
puts ""



domain = "test.timebonds2"
if 1 == 0
tx = Utils.set_options_tx(multi_sig_account_keypair, home_domain: domain)
min = Time.now.to_i
max = Time.now.to_i + 10
tx = Utils.add_timebounds(tx,min,max)
b64 = tx.to_envelope(multi_sig_account_keypair).to_xdr(:base64)
puts "b64: #{b64}"
Utils.view_envelope(b64)
sleep 20
result = Utils.send_tx(b64)
#result send_tx Stellar::TransactionResultCode.tx_too_late(-3)
puts "result send_tx #{result}"
end

tx = Utils.set_options_tx(multi_sig_account_keypair, home_domain: domain)
min = Time.now.to_i + 20
#max = Time.now.to_i + 40
max = 0
tx = Utils.add_timebounds(tx,min,max)
b64 = tx.to_envelope(multi_sig_account_keypair).to_xdr(:base64)
puts "b64: #{b64}"
Utils.view_envelope(b64)
sleep 10

#result send_tx Stellar::TransactionResultCode.tx_too_early(-2)
result = Utils.send_tx(b64)
puts "result send_tx #{result}"

sleep 20
#"resultcode"=>Stellar::TransactionResultCode.tx_success(0)}
result = Utils.send_tx(b64)
puts "result send_tx #{result}"
