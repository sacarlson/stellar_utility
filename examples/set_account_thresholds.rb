#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
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

puts "thresholds: #{Utils.get_thresholds_local(multi_sig_account_keypair)}"
#b64 = Utils.add_signer_weight_adjusted(multi_sig_account_keypair,signerC_keypair)

#def add_signer_and_weight_manual(target_keypair,add_address,weight_signer,weight_med_high)
b64 = Utils.add_signer_and_weight_manual(multi_sig_account_keypair,signerC_keypair,1,0)
#result = Utils.send_tx(b64)
#puts "result send_tx:  #{result}"

env = Utils.set_options(multi_sig_account_keypair, master_weight: 1, thresholds: {low: 0, medium: 2, high: 2})

#env_b64_addsigners(env_b64, *keypair)
b64 = Utils.env_b64_addsigners(env, multi_sig_account_keypair)
#b64 = Utils.env_b64_addsigners(env, multi_sig_account_keypair,signerC_keypair)
Utils.view_envelope(b64)

if 1 == 1
result = Utils.send_tx(b64)
puts "result send_tx:  #{result}"
puts "#{Utils.get_thresholds_local(multi_sig_account_keypair)}"
puts "thresholds: #{Utils.get_thresholds_local(multi_sig_account_keypair)}"
end

#"unlock_env_b64" from "action" make_unlock_transaction return from multi-sign-websocket
b64 = "AAAAAHF++eHSNz1b3M59q378jS8MpjHhDfpxX5CUM9NjWzrXAAAAZAAAAjMAAAANAAAAAQAAAABWGm6OHPXE+1KFtBAAAAAAAAAAAQAAAAAAAAAFAAAAAAAAAAEAAAAAAAAAAQAAAAAAAAABAAAAAQAAAAEAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAEGjFFJAAAAQBPbVRemWqYxeA1MrCzSsLOAWmz9DJF3DOaxX7tULFXfNvUywqfvHGCIKnDD5N8H2CEi6ujwB5he7pBccmYwmgI="
Utils.view_envelope(b64)
b64 = Utils.push_sig(b64,multi_sig_account_keypair)
#Utils.view_envelope(b64)

#b64 = Utils.env_b64_addsigners(env, multi_sig_account_keypair)
#Utils.view_envelope(b64)

result = Utils.send_tx(b64)
puts "result send_tx:  #{result}"
puts "#{Utils.get_thresholds_local(multi_sig_account_keypair)}"
#results return {:master_weight=>1, :low=>0, :medium=>0, :high=>0}  it works!!



