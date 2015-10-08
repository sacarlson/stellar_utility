#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
#here we will create a function to delete or add signer and adjust signing weights in a single transaction
# work in progress

require '../lib/stellar_utility/stellar_utility.rb'
#Utils = Stellar_utility::Utils.new("horizon")
Utils = Stellar_utility::Utils.new()
puts "Utils version: #{Utils.version}"
puts "configs: #{Utils.configs}"
puts ""

def envelope_addsigners(env,tx,*keypair)
  #this is used to add needed keypair signitures to a transaction
  # and combine your added signed tx with someone elses envelope that has signed tx's in it
  # you can add one or more keypairs to the envelope
  sigs = env.signatures
  envnew = tx.to_envelope(*keypair)
  pos = envnew.signatures.length
  #puts "pos start #{pos}"
  sigs.each do |sig|
    #puts "sig #{sig}"
    envnew.signatures[pos] = sig
    pos = pos + 1
  end
  return envnew
end


def env_addsigners(env, *keypair)
  tx = env.tx
  puts "keypair:  #{keypair}"
  envnew = tx.to_envelope(*keypair)
end

def env_sig_info(envelope)
  #output an array of key addresses that have valid signatures on this envelope
  puts "sig.count:  #{envelope.signatures.length}"
  hash = Utils.envelope_to_hash(envelope)
  tx = envelope.tx
  sigs = envelope.signatures
  sig_info = Utils.get_signer_info(hash["source_address"])
  puts "sig_info:  #{sig_info}"
  address = []
  sig_info.each do |row|
    puts "row: #{row}"    
    sigs.each do |sig|
      puts "sig_b64:  #{sig.to_xdr(:base64)}"
      sig_b64 = sig.to_xdr(:base64)
      check = Utils.verify_signature(envelope, row["publickey"], sig_b64)
      puts "check: #{Utils.verify_signature(envelope, row["publickey"], sig_b64)}"
      if check
        address.push(row["publickey"])
      end
    end
  end
  puts "good_keys.count: #{address.length}"
  return address
end


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

result = Utils.get_signer_info(multi_sig_account_keypair,signerA_keypair)
puts "signer_info:  #{result}"
b64 = Utils.add_signer_weight_adjusted(multi_sig_account_keypair,signerA_keypair,weight = 1)
env = Utils.b64_to_envelope(b64)
#this signed_correctly didn't work always says fail even when it works
#puts "sig_good: #{env.signed_correctly?}"
#env = env_addsigners(env,multi_sig_account_keypair,signerA_keypair)
b64 = env.tx.to_envelope(multi_sig_account_keypair,signerC_keypair).to_xdr(:base64)
env = Utils.b64_to_envelope(b64)
puts "sigs: #{env.signatures}"
puts "sigs.count: #{env.signatures.length}"
#env_sig_info(env)
Utils.env_signature_info(env)
puts ""
Utils.view_envelope(b64)
#res = Utils.envelope_to_hash(b64)
#puts "res:  #{res}"
exit -1
puts "b64: #{b64}"
result = Utils.send_tx(b64)
puts "result send_tx #{result}"
thresholds = Utils.get_thresholds_local(multi_sig_account_keypair)
puts "thr: #{thresholds}"
result = Utils.get_signer_info(multi_sig_account_keypair,signerA_keypair)
puts "signer_info:  #{result}"



