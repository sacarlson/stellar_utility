#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
require './stellar_utilities'

# note: this is to demonstrate the envelope_merge(envA,envB) function instead of the envelope_addsigners(envelope,tx,signerA_keypair) function used in the other
#this will attempt to create a multi signed transaction that will change the home_domain of the multi_sig_account_keypair account to 
# a random string of testXXXX to verify that the transaction worked or not.
# the accounts and keys including multi_sig_account_keypair is setup in create_multi_sign_account.rb that must be run before you run this
# this account was created to be set with thresholds of master_weight: 1, low: 0, medium: 2, high: 2.
# this means tx should work with any 2 of the total 3 signer keys with each having a weight of 1
# so here we sign the tx envelope with signerA_keypair and signerB_keypair and verify that the tx submit for multi_sig_account_keypair account the will work
# this test version of the same sign_mult.. was only to demonstrate the new funtion env_merge(envA,envB) that is meant to merge two or more tx envelopes
# we think this might be the funtion or functions like it to used to combine groups of signers tx sigs in the future.

def b64_to_envelope2(b64)
  #now in stellar_utilities
  bytes = Stellar::Convert.from_base64 b64
  #tr = Stellar::TransactionResult.from_xdr bytes
  env = Stellar::TransactionEnvelope.from_xdr bytes
end


if !File.file?("./multi_sig_account_keypair.yml")
  puts "you must run create_multi_sign_account.rb before you run this to create needed keys and accounts used here, will exit now"
  exit -1
end
multi_sig_account_keypair = YAML.load(File.open("./multi_sig_account_keypair.yml"))
signerA_keypair = YAML.load(File.open("./signerA_keypair.yml"))
signerB_keypair = YAML.load(File.open("./signerB_keypair.yml"))

puts "multi_sig address #{multi_sig_account_keypair.address}"

if @configs["fee"] == 0
  starting_balance = 0
else
  starting_balance = 1000_000000
end

def env_merge2(*envs)
  #this assumes all envelops have sigs of the same tx
  #this is now included in stellar_utilites as env_merge(*envs)
  tx = envs[0].tx
  sigs = []
  envs.each do |env|
    #puts "env sig #{env.signatures}"
    sigs.concat(env.signatures)
  end
  #puts "sigs #{sigs}"  
  envnew = tx.to_envelope()
  pos = 0
  sigs.each do |sig|
    envnew.signatures[pos] = sig
    pos = pos + 1
  end
  return envnew	    
end

def setup_multi_sig_tx_hash(tx, master_keypair, signer_keypair=master_keypair)
  #setup a tx_hash that will be sent to send_to_multi_sign_server(tx_hash) to publish tx to multi-sign server
  # you have the option to customize the hash after this creates a basic template
  # you can change tx_title, signer_weight, signer_sig, if desired before sending to multi-sign server
  signer_address = convert_keypair_to_address(signer_keypair)
  master_address = convert_keypair_to_address(master_keypair)
  tx_hash = {"action"=>"submit_tx","tx_title"=>"test tx", "signer_address"=>"RUTIWOPF", "signer_weight"=>"1", "master_address"=>"GAJYPMJ...","tx_envelope_b64"=>"AAAA...","signer_sig"=>""}
  tx_hash["signer_address"] = signer_address
  tx_hash["master_address"] = master_address
  envvelope = tx.to_envelope(signer_keypair)
  b64 = envelope_to_b64(envelope)
  tx_hash["tx_title"] = hash32(b64)
  tx_hash["tx_envelope_b64"] = b64
end 

puts "fee = #{@configs["fee"]}"

rnd = rand(1000...9999) 
rndstring = "test#{rnd}"
puts "#{rndstring}"
#exit -1
tx = set_options_tx(multi_sig_account_keypair,home_domain: rndstring)
check = tx.hash
#puts "check #{envelope_to_b64(check)}"
#exit -1
envA = tx.to_envelope(signerA_keypair)
envB = tx.to_envelope(signerB_keypair)
envelope = env_merge(envA,envB)
#this also works as a mirror function
#envelope = envelope_merge(envA,envB)
puts "sigs #{envelope.signatures}"
#envelope = envelope_addsigners(envelope,tx,signerA_keypair)
#puts "sigs #{envelope.signatures}"
#envelope = envelope_addsigners(envelope,tx,multi_sig_account_keypair,signerA_keypair)
#puts "sigs #{envelope.signatures}"
puts "evn before: #{envelope.signatures}"
b64 = envelope_to_b64(envelope)
env = b64_to_envelope(b64)
puts "env after: #{env.signatures}"
exit -1
if env == envelope 
  puts " yes"
end
exit -1
puts "send_tx"
result = send_tx(b64)
puts "result send_tx #{result}"



