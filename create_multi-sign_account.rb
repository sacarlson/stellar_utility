#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
require './stellar_utilities'
#example using stellar_utilities.rb to recreate parts of what was seen in hackday-stellar-vault
#this will create 3 accounts (may only one of them needs to be an active account but we are still learning at this stage)
#it will setup the multi_sig_account_keypair account with 2 added signatures that include  signerA_keypair and signerB_keypair for a total of 3 keypairs
# each signer keypair and the account pair itself is assigned a weight of 1
# the thresholds are set as master_weight: 1, low: 0, medium: 2, high: 2.  This means that 2 of any of the 3 keypairs can sign a transaction for it to work
# see also sign_multi_sign_transaction.rb to see how this account key set can be used to make a transaction that requires these account keys to transact.

master      = Stellar::KeyPair.from_raw_seed("allmylifemyhearthasbeensearching")
if 1==0
  multi_sig_account_keypair = YAML.load(File.open("./secret_keypair_GBN3YBHSD653DQHADNP7AX5XA4UGZH5HFZ67MW4IIXYXGNBECTKFCZU2.yml"))
  signerA_keypair = YAML.load(File.open("./secret_keypair_GC7UGD45JFMPKCCRJTOBLTKEN64CWJC7GNBRS7WL75FNUVC5Z2B6TKGX.yml"))
  signerB_keypair = YAML.load(File.open("./secret_keypair_GC2TANKLHFXEX4MZA4WRM2ZC33JN5Z6SMNPV72WX2CQ22UWISXOGI3YA.yml"))
else
  if File.file?("./multi_sig_account_keypair.yml")
    multi_sig_account_keypair = YAML.load(File.open("./multi_sig_account_keypair.yml"))
    signerA_keypair = YAML.load(File.open("./signerA_keypair.yml"))
    signerB_keypair = YAML.load(File.open("./signerB_keypair.yml"))
  else
    multi_sig_account_keypair =Stellar::KeyPair.random
    puts "my #{multi_sig_account_keypair.address}"
    puts "mys #{multi_sig_account_keypair.seed}"
    to_file = "./multi_sig_account_keypair.yml"
    puts "save to file #{to_file}"
    File.open(to_file, "w") {|f| f.write(multi_sig_account_keypair.to_yaml) }

    signerA_keypair =Stellar::KeyPair.random
    puts "A #{signerA_keypair.address}"
    puts "As #{signerA_keypair.seed}"
    to_file = "./signerA_keypair.yml"
    puts "save to file #{to_file}"
    File.open(to_file, "w") {|f| f.write(signerA_keypair.to_yaml) }

    signerB_keypair =Stellar::KeyPair.random
    puts "B #{signerB_keypair.address}"
    puts "Bs #{signerB_keypair.seed}"
    to_file = "./signerB_keypair.yml"
    puts "save to file #{to_file}"
    File.open(to_file, "w") {|f| f.write(signerB_keypair.to_yaml) }
  end
end

if @configs["fee"] == 0
  starting_balance = 0
else
  starting_balance = 1000_000000
end

puts "fee = #{@configs["fee"]}"

if 1==1
puts "create_account multi_sig_account_keypair"
result = create_account(multi_sig_account_keypair, master, starting_balance)
puts "#{result}"
sleep 11

puts "create_account signerA"
result = create_account(signerA_keypair, master, starting_balance)
puts "#{result}"
sleep 11

puts "create_account signerB"
result = create_account(signerB_keypair, master, starting_balance)
puts "#{result}"
sleep 11
end


if 1==1
# affected account should be GBN3YBHSD653DQHADNP7AX5XA4UGZH5HFZ67MW4IIXYXGNBECTKFCZU2 for multi_sig_account_keypair
envelope = add_signer(multi_sig_account_keypair,signerA_keypair,1) 
b64 = envelope_to_b64(envelope)
puts "send_tx"
result = send_tx(b64)
puts "result send_tx #{result}"
sleep 12

envelope = add_signer(multi_sig_account_keypair,signerB_keypair,1)
b64 = envelope_to_b64(envelope)
puts "send_tx"
result = send_tx(b64)
puts "result send_tx #{result}"
sleep 11 
end

if 1==1
envelope = set_thresholds(multi_sig_account_keypair, master_weight: 1, low: 0, medium: 2, high: 2)
b64 = envelope_to_b64(envelope)
puts "send_tx"
result = send_tx(b64)
puts "result send_tx #{result}"
end
