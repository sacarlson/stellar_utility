#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
#this will demonstrate how a client would use the multi-sign-server to setup and publish a multi-sign-account
# to a multi-sign-server or as we will sometimes now call it an mss-server. 
# The multi-sign-server is used to distribute tx envelopes to the signers and acumulate the needed signatures and submit them
# to the stellar network when the mss-server finds that it has collected what is needed to validate the transaction.
# you must have a multi-sign-server entity running and you must have the @configs["multi_sign_server_url"] pointing at it
# for this to work.  This program will also create 1 active account with funding needed for this test.
# it will also setup the multi_sig_keypairs and save them as files as signerA_keypair and signerB_keypair for
# a total of 3 keypairs that will be used here and in the next example programs:
# submit_transaction_to_mss.rb and sign_transaction_mss.rb were the other functions of the mss server are demonstrated.
# each signer keypair and the mss_account pair itself is by default assigned a signing weight of 1
# the thresholds are set as master_weight: 1, low: 0, medium: 3, high: 3.
# This means that all 3 signers will need to sign this transaction to be validated and processed to be seen
# on the stellar network.
# after you run this program see  submit_transaction_to_mss.rb and then sign_transaction_mss.rb  that shows how this account and key sets are used to make a transaction that requires this account and these keys to transact.

# you will have to privide a master_keypair account in ./stellar_utility.cfg that has the funds needed to do this operation
# you will need 31 lunes minimum that will be used to activate and fund the multi_sig_account_keypair 
require '../lib/stellar_utility/stellar_utility.rb'
require 'em-websocket-client'

#Utils = Stellar_utility::Utils.new("horizon")
Utils = Stellar_utility::Utils.new()
puts "Utils version: #{Utils.version}"
puts "configs: #{Utils.configs}"
puts ""
#master  = eval( @configs["master_keypair"])
master  = Stellar::KeyPair.master
funder = master

puts "url: #{Utils.configs["url_mss_server"]}"


# the bigginning of this program just sets up the needed accounts and keypair files that will be used here and in the 
# next steps in other programs that demonstrate other parts. it will create 3 yaml files with the acount and keys.
# if the files are present it will do nothing but load them.

Utils.create_key_testset_and_account(start_balance = 100)
multi_sig_account_keypair = YAML.load(File.open("./multi_sig_account_keypair.yml"))
signerA_keypair = YAML.load(File.open("./signerA_keypair.yml"))
signerB_keypair = YAML.load(File.open("./signerB_keypair.yml"))

# so the real program bellow is just three function calls to create the acc_hash and optionaly modify it.
# the next step creates a new account a modifies an existing account to be a multi sign account
# the third step sends the multi sign account info to the mss-server to be used in the signing process.

#this next function will create the acc_hash used in send_to_multi_sign_server function that will setup needed
# account settings and signer preperation.
# you can optionaly setup as many as 20 signers for a single account. This example only has 2 additional signers
# note at this stage the signer keypairs don't need to have the secreet seed
# only the multi_sig_account_keypair needs a secreet key for the transaction at this point

acc_hash = Utils.setup_multi_sig_acc_hash(multi_sig_account_keypair,signerA_keypair,signerB_keypair)
puts "acc_hash: #{acc_hash}"

#example out:
#{"action"=>"create_acc", "tx_title"=>"TP5NV7WN53", "master_address"=>"GDKQJNX4DQRHVE76ZOIGQSYZR2PDX4XSDT3CAKM7F6NSZBOQ6D5QDLBD", "master_seed"=>"SDEH6BEVCMLFGAO5SAOQOWVDIFT5XS466OJQ3CZEU6OSYOXJPQQ66CYR", "start_balance"=>41, "signers_total"=>3, "thresholds"=>{"master_weight"=>1, "low"=>"0", "med"=>3, "high"=>3}, "signer_weights"=>{"GA2F3NNTSJEX2L7QJHPS4GMSQKGUMKZESTUIRXUZLHZXSQGBNBIJCMET"=>1, "GBCGQWBATTLZW6PWX7H4TNRDDWDFCZAWCGTXWYPHRHRS534HMC5HXWUY"=>1}}

#puts""
#this is what the JSON format of the acc_hash looks like that is sent to the mss-server
#puts "acc_hash in json format:  #{ActiveSupport::JSON.encode(acc_hash)}"
#exit -1

# at this point you could customize the acc_hash to modify how you want the account thresholds and signer weights to be
# examples:
# acc_hash["signer_weights"]["GDZ4AF..."] = 2
# acc_hash["thresholds"]["high"] = 4
# acc_hash["thresholds"]["med"] = 1
# the default output acc_hash template is to require all signers to sign the transaction to allow validation and 
# submition to the stellar network.
# default for med is the same as high threshold and low is set to zero
# default for signers is all equal with a signing weight of 1

# we could now optionaly  create the multi sign account on the stellar network with the acc_hash with the
# create_account_from_acc_hash func
# this function could also be setup on the server side if the client provides a funder that could be a funded
# master_seed account to pay the transaction fee's
# this function only creates the b64 formated transaction that still requires sending to the stellar network 
#b64 = Utils.create_account_from_acc_hash(acc_hash,funder)
b64 = Utils.create_account_from_acc_hash(acc_hash)
puts "res: #{b64}"
#Utils.view_envelope(b64)
# we send the b64 formated transaction here with the send_tx function
result = Utils.send_tx(b64) 
puts "res: #{result}"
exit -1
#optionaly we should remove the master_seed from the acc_hash here if we created the funded master account in the function above.
#before we send it to the mss-server
acc_hash["master_seed"] = "none_provided"

#send the above created and optionaly edited acc_hash to the mss-server for processing
#result = Utils.send_to_multi_sign_server(acc_hash)
#puts "send results:  #{result}"
puts " sending json: #{acc_hash.to_json}"

#here we are using the websocket method instead of restclient interface to the mss-server
# with the websocket method we can get realtime feedback of the state of the multi sign transaction
# and using the EM eventmachine lib we can triger an action after knowing the signing is complete 

EM.run do
  conn = EventMachine::WebSocketClient.connect(Utils.configs["url_mss_server"])
  puts "url: #{Utils.configs["url_mss_server"]}"
  conn.callback do
    conn.send_msg acc_hash.to_json
    #conn.send_msg "done"
  end

  conn.errback do |e|
    puts "Got error: #{e}"
    EM::stop_event_loop
  end

  conn.stream do |msg|
    puts "#{msg}"
    if msg.data == "done"
      conn.close_connection
    end
  end

  conn.disconnect do
    puts "disconnected or can't make connection , stoping event loop"
    EM::stop_event_loop
  end
end




