#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
require './stellar_utilities'
#example using stellar_utilities.rb to recreate parts of what was seen in hackday-stellar-vault
#this will create 3 accounts (may only one of them needs to be an active account but we are still learning at this stage)
#it will setup the multi_sig_account_keypair account with 2 added signatures that include  signerA_keypair and signerB_keypair for a total of 3 keypairs
# each signer keypair and the account pair itself is assigned a weight of 1
# the thresholds are set as master_weight: 1, low: 0, medium: 2, high: 2.  This means that 2 of any of the 3 keypairs can sign a transaction for it to work
# see also sign_multi_sign_transaction.rb to see how this account key set can be used to make a transaction that requires these account keys to transact.

if @configs["fee"] == 0
  starting_balance = 0
elsif @configs["version"] == "fred"
  starting_balance = 1000_000000
  master      = Stellar::KeyPair.from_raw_seed("allmylifemyhearthasbeensearching") 
else
  #Stellar.default_network = Stellar::Networks::TESTNET
  Stellar.default_network = eval(@configs["default_network"])
  rs = Stellar.current_network
  puts "current_network = #{rs}"
  starting_balance = @configs["start_balance"]
  master  = eval( @configs["master_keypair"])
end

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
    if 1==1
      #fund the multi sign account we will use in the steps bellow 
      puts "create_account multi_sig_account_keypair"
      result = create_account(multi_sig_account_keypair, master, starting_balance)
      puts "#{result}"
      sleep 11
      result = create_account(signerA_keypair, master, starting_balance)
      puts "#{result}"
      sleep 11
      result = create_account(signerB_keypair, master, starting_balance)
      puts "#{result}"
      sleep 11
    end
  end
end

puts "fee = #{@configs["fee"]}"
puts "starting_balance = #{starting_balance}"

if 1==0
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

puts "multi_sig_account #{multi_sig_account_keypair.address}"
puts "keypairA:  #{signerA_keypair.address}"
puts "keypairB:  #{signerB_keypair.address}"

if 1==0
#this works now if I have at least 30 native balance in multi_sig..
envelope = add_signer(multi_sig_account_keypair,signerA_keypair,1) 
b64 = envelope_to_b64(envelope)
puts "send_tx"
result = send_tx(b64)
puts "result send_tx #{result}"
sleep 12
end


if 1==0
# affected account should be GAARXW4ZLTLC5FDP24I7QSCWO4DWUHOC6AJHQEGYMOFSTBFRGXVYRJK2 for multi_sig_account_keypair
envelope = add_signer(multi_sig_account_keypair,signerA_keypair,1) 
envelope2 = add_signer(multi_sig_account_keypair,signerB_keypair,1) 

puts "sigs: #{envelope.signatures}"
puts "tx fee: #{envelope.tx.fee}"
tx1 = envelope.tx
puts "tx1 seq_num:  #{tx1.seq_num}"

tx2 = envelope2.tx
tx2.seq_num = tx2.seq_num + 1
puts "tx2 seq_num:  #{tx2.seq_num}"

puts "tx1.fee: #{tx1.fee}"
#tx1.fee = 20
#tx2.fee = 20
#hex = tx1.merge(tx2).to_envelope(master).to_xdr(:base64)
# Stellar::TransactionResultCode.tx_bad_seq(-5)  if both tx1 and tx2 have the same seqnum
tx3 = tx1.merge(tx2)
#Stellar::TransactionResultCode.tx_insufficient_fee(-9)   if not set to 20 default is 10
tx3.fee = 20
puts "tx3.fee: #{tx3.fee}"
envelope = tx3.to_envelope(multi_sig_account_keypair)
b64 = envelope_to_b64(envelope)

puts "send_tx"
result = send_tx(b64)
puts "result send_tx #{result}"

sleep 12
end

if 1==0
# this works
rnd = rand(1000...9999) 
rndstring = "test#{rnd}"
puts "#{rndstring}"
tx = set_options_tx(multi_sig_account_keypair,home_domain: rndstring)
#b64 = tx.to_envelope(multi_sig_account_keypair).to_xdr(:base64)
envelope = tx.to_envelope(multi_sig_account_keypair)
b64 = envelope_to_b64(envelope)
result = send_tx(b64)
exit -1
end



b64 = envelope_to_b64(envelope)
puts "send_tx"
result = send_tx(b64)
puts "result send_tx #{result}"
#sleep 11 


if 1==0
envelope = set_thresholds(multi_sig_account_keypair, master_weight: 1, low: 0, medium: 2, high: 2)
b64 = envelope_to_b64(envelope)
puts "send_tx"
result = send_tx(b64)
puts "result send_tx #{result}"
end

