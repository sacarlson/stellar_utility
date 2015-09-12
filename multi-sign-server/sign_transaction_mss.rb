#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
require './stellar_utilities'
# this will demonstrate how a client would use the multi-sign-server to get an unsigned transaction envelope
# from the mss-server, sign it and return the signature to the mss-server that will continue to collect the remaining
# needed signatures from other signers until the threshold is met so the transaction can be submited to the stellar
# network to be validated and processed. 

if !File.file?("./multi_sig_account_keypair.yml")
  puts "you must run create_account_for_mss.rb before you run this to create needed keys and accounts used here, will exit now"
  exit -1
end
# load the keypairs needed to sign the pregenerated transaction submited with submit_transaction_to_mss.rb
#multi_sig_account_keypair = YAML.load(File.open("./multi_sig_account_keypair.yml"))
signerA_keypair = YAML.load(File.open("./signerA_keypair.yml"))
signerB_keypair = YAML.load(File.open("./signerB_keypair.yml"))

puts "signerA_keypair address #{signerA_keypair.address}"
puts "signerB_keypair address #{signerB_keypair.address}"


puts "fee = #{@configs["fee"]}"

def setup_multi_sig_sign_hash(tx_code,keypair)
  #this will search the multi-sign-server for the published transaction with a matching tx_code.
  #if the transaction is found it will get the b64 encoded transaction from the server 
  #and sign it with this keypair that is assumed to be a valid signer for this transaction.
  #after it signs the transaction it will send the signed transaction back to the multi-sign-server
  #that will continue to collect more signatures from other signers until the total signer weight threshold is met,
  #at witch point the multi-sign-server will send the fully signed transaction to the stellar network for validation
  # this function only returns the sig_hash to be sent to send_to_multi_sign_server(sig_hash) to publish signing of tx_code
  # this sig_hash can be modified before it is sent 
  # example: 
  # sig_hash["tx_title"] = "some cool transaction"
  # sig_hash["signer_weight"] = 2
  # the other values should already be filled in by the function that for the most part should not be changed.

  #this action get_tx when sent to the mss-server will returns the master created transaction with added info,  
  #{"tx_num"=>1, "signer"=>0, "tx_code"=>"7ZZUMOSZ26", "tx_title"=>"test multi sig tx", "signer_address"=>"", "signer_weight"=>"", "master_address"=>"GDZ4AFAB...", "tx_envelope_b64"=>"AAAA...","signer_sig"=>"URYE..."}
  get_tx = {"action"=>"get_tx","tx_code"=>"7ZZUMOSZ26"}
  get_tx["tx_code"] = tx_code
  result = send_to_multi_sign_server(get_tx)
  puts "mss result: #{result}"
  puts "env_b64: #{result["tx_envelope_b64"]}"
  env = b64_to_envelope(result["tx_envelope_b64"])
  if env.nil?
    puts "env was nil"
    return nil
  end
  tx = env.tx
  signature = sign_transaction_env(env,keypair)
  envnew = envelope_addsigners(env, tx, keypair)
  tx_envelope_b64 = envelope_to_b64(envnew)
  submit_sig = {"action"=>"sign_tx","tx_title"=>"test tx","tx_code"=>"JIEWFJYE", "signer_address"=>"GAJYGYI...", "signer_weight"=>"1", "tx_envelope_b64"=>"AAAA...","signer_sig"=>"JIDYR..."}
  submit_sig["tx_code"] = tx_code
  submit_sig["tx_title"] = tx_code
  #submit_sig["signer_sig"] = signature
  submit_sig["tx_envelope_b64"] = tx_envelope_b64
  submit_sig["signer_address"] = keypair.address
  return submit_sig
end

tx_code = "62RTNXJJKA"

sign_hash = setup_multi_sig_sign_hash(tx_code,signerA_keypair)
puts ""
puts "sign_hash:  #{sign_hash}"


#result = send_to_multi_sign_server(sign_hash)
#puts "sign result: #{result}"

#exit -1

sign_hash = setup_multi_sig_sign_hash(tx_code,signerB_keypair)
result = send_to_multi_sign_server(sign_hash)
puts "sign result: #{result}"

exit -1
rnd = rand(1000...9999) 
rndstring = "test#{rnd}"
puts "#{rndstring}"
#exit -1
# this is a simple transaction created to test the MSS
# to prove it worked we will detect the home_domain of the multi_sig_account change when all sigs are collected and submited
tx = set_options_tx(multi_sig_account_keypair,home_domain: rndstring)
#check = tx.hash
#puts "check #{envelope_to_b64(check)}"
tx_hash = setup_multi_sig_tx_hash(tx, multi_sig_account_keypair)

#at this point we could make some modifications to the final tx_hash before we publish it to the MSS server
#example:
#tx_hash["tx_title"]="first test of the multi-sign-server"
puts "tx_hash: #{tx_hash}"

#send the above created tx_hash to publish and prepare to process with more sig collection
send_to_multi_sign_server(tx_hash)

exit -1
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

__END__ 
# these will be moved to stellar_utilities.rb and erased from here after we finish testing

def sign_transaction2(tx,keypair)
  # this is now in stellar_utilities
  #return a signature for a transaction
  #signature = sign_transaction(tx,keypair)
  envelope = tx.to_envelope(keypair)
  return envelope.signatures
end

def merge_signatures_tx2(tx,*sigs)
  # this is now in stellar_utilities
  #merge an array of signing signatures onto a transaction
  #output is a signed envelope
  #envelope = merge_signatures(tx,sig1,sig2,sig3)
  envnew = tx.to_envelope()
  pos = 0
  sigs.each do |sig|
    envnew.signatures[pos] = sig
    pos = pos + 1
  end
  return envnew	    
end

def b64_to_envelope2(b64)
  #now in stellar_utilities
  bytes = Stellar::Convert.from_base64 b64
  #tr = Stellar::TransactionResult.from_xdr bytes
  env = Stellar::TransactionEnvelope.from_xdr bytes
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
  # you can change tx_title, signer_weight, signer_sig, if desired before sending it to the multi-sign-server
  signer_address = convert_keypair_to_address(signer_keypair)
  master_address = convert_keypair_to_address(master_keypair)
  tx_hash = {"action"=>"submit_tx","tx_title"=>"test tx", "signer_address"=>"RUTIWOPF", "signer_weight"=>"1", "master_address"=>"GAJYPMJ...","tx_envelope_b64"=>"AAAA...","signer_sig"=>""}
  tx_hash["signer_address"] = signer_address
  tx_hash["master_address"] = master_address
  envelope = tx.to_envelope(signer_keypair)
  b64 = envelope_to_b64(envelope)
  tx_hash["tx_title"] = hash32(b64)
  tx_hash["tx_envelope_b64"] = b64
  return tx_hash
end 


