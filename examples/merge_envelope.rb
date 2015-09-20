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

#to really get this to work I want to see Utils.env_merge(envA,envB) work with arrays of envelopes and coma deliminated env.  seems only one or the other will work
require '../lib/stellar_utility/stellar_utility.rb'
Utils = Stellar_utility::Utils.new("horizon")
puts "Utils version: #{Utils.version}"
puts "configs: #{Utils.configs}"
puts ""

master  = Stellar::KeyPair.master

Utils.create_key_testset_and_account(100)
from_pair = YAML.load(File.open("./multi_sig_account_keypair.yml"))
to_pair = YAML.load(File.open("./signerA_keypair.yml"))
#signerB_keypair = YAML.load(File.open("./signerB_keypair.yml"))

#puts "create account to_pair"
#result = Utils.create_account(to_pair, master)
#puts "#{result}"

puts "from_pair.address: #{from_pair.address}"
puts "to_pair.address:  #{to_pair.address}"
amount = 1

# both accounts look good on stellar db
#from_pair.address: GBUXOWW5PGTJNRL3ZOQGCUG5UGSNXDZN4DXKMDYLYAUIKZ4M3Z2QNHET
#to_pair.address:  GCR26OFV4UASHRAHCOAOWMTJ2B2OG4MS3DMPR76DR7HII2BYCLE4FLGQ
#Stellar::TransactionResultCode.tx_bad_auth_extra(-10)
# this will never work due to env_merge(env,enva) only merges sigs not contents so we have to test a different way

txA = Utils.send_native_tx(from_pair, to_pair, 1, seqadd=0)
envA = txA.to_envelope(from_pair)
puts "envA.inspect:  #{envA.inspect}"
txB = Utils.send_native_tx(to_pair, from_pair, 2, seqadd=0)
envB = txB.to_envelope(to_pair)
#envA = tx.to_envelope(signerA_keypair)

array = [envA,envB]
envelope = Utils.env_merge(envA,envB)
puts ""
puts ""
puts "envelope.inspect:  #{envelope.inspect}"
exit -1
#envelope = Utils.env_merge(array)
#this also works as a mirror function
#envelope = Utils.envelope_merge(envA,envB)
#puts "sigs #{envelope.signatures}"
#envelope = Utils.envelope_addsigners(envelope,tx,signerA_keypair)
#puts "sigs #{envelope.signatures}"
#envelope = Utils.envelope_addsigners(envelope,tx,multi_sig_account_keypair,signerA_keypair)
#puts "sigs #{envelope.signatures}"
#envelope = envB
b64 = Utils.envelope_to_b64(envelope)
result = Utils.get_native_balance(to_pair.address)
puts "before balance = #{result}"
puts "send_tx"
result = Utils.send_tx(b64)
puts "result send_tx #{result}"
sleep 4
result = Utils.get_native_balance(to_pair.address)
puts "after balance = #{result}"

#we now get
#Stellar::TransactionResultCode.tx_bad_auth_extra(-10)

