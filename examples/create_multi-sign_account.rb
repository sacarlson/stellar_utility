#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
#example using stellar_utilities.rb to recreate parts of what was seen in hackday-stellar-vault
#this will create 3 accounts (may only one of them needs to be an active account but we are still learning at this stage)
#it will setup the multi_sig_account_keypair account with 2 added signatures that include  signerA_keypair and signerB_keypair for a total of 3 keypairs
# each signer keypair and the account pair itself is assigned a weight of 1
# the thresholds are set as master_weight: 1, low: 0, medium: 2, high: 2.  This means that 2 of any of the 3 keypairs can sign a transaction for it to work
# see also sign_multi_sign_transaction.rb to see how this account key set can be used to make a transaction that requires these account keys to transact.
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


if 1==0
puts "create_account multi_sig_account_keypair"
result = Utils.create_account(multi_sig_account_keypair, master)
puts "#{result}"
sleep 11

#puts "create_account signerA"
#result = Utils.create_account(signerA_keypair, master)
#puts "#{result}"


#puts "create_account signerB"
#result = Utils.create_account(signerB_keypair, master)
#puts "#{result}"

end

puts "multi_sig_account #{multi_sig_account_keypair.address}"
puts "keypairA:  #{signerA_keypair.address}"
puts "keypairB:  #{signerB_keypair.address}"
thresholds = Utils.get_thresholds_local(multi_sig_account_keypair)
puts "thresholds: #{thresholds}"

if 1==0
#this works now if I have at least 30 native balance in multi_sig.. 10 additional for each signer
# this only adds one of the two signers A
#envelope = Utils.add_signer(multi_sig_account_keypair,signerA_keypair,1) 
envelope = Utils.add_signer(multi_sig_account_keypair,signerA_keypair,0) 
b64 = Utils.envelope_to_b64(envelope)
puts "send_tx"
result = Utils.send_tx(b64)
puts "result send_tx #{result}"
end


if 1==1
# affected account should be on mutli_sig... from multi_sig_account_keypair
# this should add both signers A and B
envelope = Utils.add_signer(multi_sig_account_keypair,signerA_keypair,1) 
envelope2 = Utils.add_signer(multi_sig_account_keypair,signerB_keypair,1) 


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
b64 = Utils.envelope_to_b64(envelope)

puts "send_tx"
result = Utils.send_tx(b64)
puts "result send_tx:  #{result}"

end

if 1==1
#setup weight thresholds on multi_sig.. that requires 2 of the 3 signers to sign a tx before the stellar network will validate them
envelope = Utils.set_thresholds(multi_sig_account_keypair, master_weight: 1, low: 0, medium: 3, high: 0)
#AQAAAg==  ; 1,0,0,2  I can still perform homedomain change with a single signer
# but I can't change thresholds to 1,0,1,1 now with a single signer now with 1,0,0,2
#AQABAQ==  ; 2,0,1,1
b64 = Utils.envelope_to_b64(envelope)
puts "send_tx"
result = Utils.send_tx(b64)
puts "result send_tx:  #{result}"
end
thresholds = Utils.get_thresholds_local(multi_sig_account_keypair)
puts "thresholds: #{thresholds}"

if 1==1
# this works before we change thresholds
#here we will create a simple transaction to change homedomain to a random value on the multi_sig account
#we try to send it but with only with a single signer of the master mulit_sig account
# after the thresholds set above to 1,0,2,2 we will now see results from not enuf sigs:
#{"hash"=>"9bb20309c0a6613bf0af89a42b580794d7a6f4028a48c1833dde3d50c1c7cbdf", "result"=>"failed", "error"=>"AAAAAAAAAAr/////AAAAAf////8AAAAA"}
#Stellar::TransactionResultCode.tx_failed(-1)
rnd = rand(1000...9999) 
rndstring = "test#{rnd}"
puts "will change home_domain to: #{rndstring}"
tx = Utils.set_options_tx(multi_sig_account_keypair,home_domain: rndstring)
#b64 = tx.to_envelope(multi_sig_account_keypair).to_xdr(:base64)
envelope = tx.to_envelope(multi_sig_account_keypair)
b64 = Utils.envelope_to_b64(envelope)
result = Utils.send_tx(b64)
puts "result send_tx:  #{result}"
end
result = Utils.get_accounts_local(multi_sig_account_keypair)
puts "home_domain: #{result["homedomain"]}"

__END__

Low Security:

    AllowTrustTx
    Used to allowing other signers to allow people to hold credit from this account but not issue it.

Medium Secruity:

    All else including authorized to make payments of native or non native assets

High Security:

    SetOptions for Signer and threshold
    Used to change the Set of signers and the thresholds.




