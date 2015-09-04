#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
require './stellar_utilities'
#this will attempt to create a multi signed transaction that will change the home_domain of the multi_sig_account_keypair account to 
# a random string of testXXXX to verify that the transaction worked or not.
# the accounts and keys including multi_sig_account_keypair is setup in create_multi_sign_account.rb that must be run before you run this
# this account was created to be set with thresholds of master_weight: 1, low: 0, medium: 2, high: 2.
# this means tx should work with any 2 of the total 3 signer keys with each having a weight of 1
# so here we sign the tx envelope with signerA_keypair and signerB_keypair and verify that the tx submit for multi_sig_account_keypair account the will work


if !File.file?("./multi_sig_account_keypair.yml")
  puts "you must run create_multi_sign_account.rb before you run this to create needed keys and accounts used here, will exit now"
  exit -1
end
multi_sig_account_keypair = YAML.load(File.open("./multi_sig_account_keypair.yml"))
signerA_keypair = YAML.load(File.open("./signerA_keypair.yml"))
signerB_keypair = YAML.load(File.open("./signerB_keypair.yml"))

puts "multi_sig address #{multi_sig_account_keypair.address}"
exit -1

if @configs["fee"] == 0
  starting_balance = 0
else
  starting_balance = 1000_000000
end

puts "fee = #{@configs["fee"]}"

rnd = rand(1000...9999) 
rndstring = "test#{rnd}"
puts "#{rndstring}"
#exit -1
tx = set_options_tx(multi_sig_account_keypair,home_domain: rndstring)

envelope = tx.to_envelope(signerB_keypair)
puts "sigs #{envelope.signatures}"
envelope = envelope_addsigners(envelope,tx,signerA_keypair)
puts "sigs #{envelope.signatures}"
#envelope = envelope_addsigners(envelope,tx,multi_sig_account_keypair,signerA_keypair)
#puts "sigs #{envelope.signatures}"
#exit -1
b64 = envelope_to_b64(envelope)
puts "send_tx"
result = send_tx(b64)
puts "result send_tx #{result}"



