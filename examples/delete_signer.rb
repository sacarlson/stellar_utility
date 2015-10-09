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


def env_b64_addsigners(env_b64, *keypair)
  if env_b64.class == String
    env = Utils.b64_to_envelope(env_b64)
  else
    env = env_b64
  end
  b64 = env.tx.to_envelope(*keypair).to_xdr(:base64)
  return b64
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
b64 = Utils.add_signer_weight_adjusted(multi_sig_account_keypair,signerA_keypair,weight = 0)
env = Utils.b64_to_envelope(b64)
#this signed_correctly didn't work always says fail even when it works
#puts "sig_good: #{env.signed_correctly?}"
#env = env_addsigners(env,multi_sig_account_keypair,signerA_keypair)
b64 = env_b64_addsigners(b64, multi_sig_account_keypair)
b64 = env_b64_addsigners(b64, multi_sig_account_keypair,signerC_keypair)

Utils.env_signature_info(b64)
puts ""
Utils.view_envelope(b64)
#res = Utils.envelope_to_hash(b64)
#puts "res:  #{res}"
exit -1
result = Utils.send_tx(b64)
puts "result send_tx #{result}"
thresholds = Utils.get_thresholds_local(multi_sig_account_keypair)
puts "thr: #{thresholds}"
result = Utils.get_signer_info(multi_sig_account_keypair,signerA_keypair)
puts "signer_info:  #{result}"



