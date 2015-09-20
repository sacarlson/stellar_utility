#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
# note: this is to demonstrate the envelope_merge(envA,envB) function instead of the envelope_addsigners(envelope,tx,signerA_keypair) function used in the other
#this will attempt to create a multi signed transaction that will change the home_domain of the multi_sig_account_keypair account to 
# a random string of testXXXX to verify that the transaction worked or not.
# the accounts and keys including multi_sig_account_keypair is setup in create_multi_sign_account.rb that must be run before you run this
# this account was created to be set with thresholds of master_weight: 1, low: 0, medium: 2, high: 2.
# this means tx should work with any 2 of the total 3 signer keys with each having a weight of 1
# so here we sign the tx envelope with signerA_keypair and signerB_keypair and verify that the tx submit for multi_sig_account_keypair account the will work
# this test version of the same sign_mult.. was only to demonstrate the new funtion env_merge(envA,envB) that is meant to merge two or more tx envelopes
# we think this might be the funtion or functions like it to used to combine groups of signers tx sigs in the future.

#we now have Utils.env_merge(envA,envB) working with both arrays of envelopes and coma deliminated envA,envB formated input.
require '../lib/stellar_utility/stellar_utility.rb'
#Utils = Stellar_utility::Utils.new("horizon")
Utils = Stellar_utility::Utils.new()
puts "Utils version: #{Utils.version}"
puts "configs: #{Utils.configs}"
puts ""

Utils.create_key_testset_and_account()
multi_sig_account_keypair = YAML.load(File.open("./multi_sig_account_keypair.yml"))
signerA_keypair = YAML.load(File.open("./signerA_keypair.yml"))
signerB_keypair = YAML.load(File.open("./signerB_keypair.yml"))
master  = Stellar::KeyPair.master

puts "multi_sig address #{multi_sig_account_keypair.address}"

thresholds = Utils.get_thresholds_local(multi_sig_account_keypair)
puts "thresholds: #{thresholds}"

rnd = rand(1000...9999) 
rndstring = "test#{rnd}"
puts "#{rndstring}"
#exit -1
#tx = Utils.set_options_tx(multi_sig_account_keypair,home_domain: rndstring)
#envC = Utils.set_thresholds(multi_sig_account_keypair, master_weight: 1, low: 0, medium: 3, high: 2 )
tx = Utils.send_native_tx(multi_sig_account_keypair, master, 1.12)
#tx = envC.tx
#threshold should change to AQABAQ== 
#default thershold code is AQAAAA==  := 1,0,0,0
#threshold code is AQAAAQ==  := 1,0,0,1

#check = tx.hash
#puts "check #{envelope_to_b64(check)}"

envA = tx.to_envelope(signerA_keypair)
envB = tx.to_envelope(signerB_keypair)
envC = tx.to_envelope(multi_sig_account_keypair)
array = [envA,envB,envC]
#envelope = Utils.env_merge(envA,envB)
#this should also works as a mirror function
envelope = Utils.envelope_merge(array)
puts ""
puts "sigs #{envelope.signatures}"
#envelope = Utils.envelope_addsigners(envelope,tx,signerA_keypair)
#puts "sigs #{envelope.signatures}"
#envelope = Utils.envelope_addsigners(envelope,tx,multi_sig_account_keypair,signerA_keypair)
#puts "sigs #{envelope.signatures}"

#both A and B signed 
b64 = Utils.envelope_to_b64(envelope)
#just A signed
#b64 = Utils.envelope_to_b64(envA)
#just B signed
#b64 = Utils.envelope_to_b64(envB)
puts "send_tx"
result = Utils.send_tx(b64)
puts "result send_tx #{result}"

__END__

#results seen if we try to provide more sigs than is required by the account:
#{"hash"=>"66dc297e6e0ad16f7b6c8031c0558dd8b898af16f8c224bbaa80e873c918f698", "result"=>"failed", "error"=>"AAAAAAAAAAr////2AAAAAA=="}
#Stellar::TransactionResultCode.tx_bad_auth_extra(-10)

#results seen if we don't have enuf signers
#{"hash"=>"595a1941104b34794eae4d13283cb4ad5c349674d98c04731efeaaae8df2d07d", "result"=>"failed", "error"=>"AAAAAAAAAAr/////AAAAAf////8AAAAA"}
#Stellar::TransactionResultCode.tx_failed(-1)

#results when we have the corect number of signers
#result send_tx {"hash":"9cef1fa514fcf4ed6cf4824e8e820bcc6849a501241b926902daf8148cd8f058","result":"received","error":null}


