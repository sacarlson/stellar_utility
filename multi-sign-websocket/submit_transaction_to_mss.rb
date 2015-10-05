#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
# this is now setup to submit or publish a transaction to the mss-server 
#this will attempt to create a multi signed transaction that will change the home_domain of the multi_sig_account_keypair account to 
# a random string of testXXXX to verify that the transaction worked or not.
# the accounts and keys including multi_sig_account_keypair is setup in create_account_for_mss.rb that must be run before you run this
# this account was originaly created to be set with thresholds of master_weight: 1, low: 0, medium: 3, high: 3.
# this means tx should work with all 3 of the total 3 signers keys with each having a weight of 1
# so later we will sign the tx envelope with signerA_keypair and signerB_keypair and verify that the tx submit for multi_sig_account_keypair account will work.

require '../lib/stellar_utility/stellar_utility.rb'
require 'em-websocket-client'

#Utils = Stellar_utility::Utils.new("horizon")
Utils = Stellar_utility::Utils.new()
puts "Utils version: #{Utils.version}"
puts "configs: #{Utils.configs}"


if !File.file?("./multi_sig_account_keypair.yml")
  puts "you must run create_account_for_mss.rb before you run this to create needed keys and accounts used here, will exit now"
  exit -1
end
multi_sig_account_keypair = YAML.load(File.open("./multi_sig_account_keypair.yml"))
#signerA_keypair = YAML.load(File.open("./signerA_keypair.yml"))
#signerB_keypair = YAML.load(File.open("./signerB_keypair.yml"))

puts "multi_sig address #{multi_sig_account_keypair.address}"

#create random string that will be the changed home_domain for multi_sig account
rnd = rand(1000...9999) 
rndstring = "test#{rnd}"
puts "#{rndstring}"

# this is a simple transaction created to test the MSS
# to prove it worked we will detect the change of home_domain of the multi_sig_account when all sigs are collected the mss-server sends the tx to the network
# this is a set_options transaction so it will require level high authority threshold to be validated
tx = Utils.set_options_tx(multi_sig_account_keypair,home_domain: rndstring)

#create tx_hash that will be used to setup what's needed to send to send_to_multi_sign_server(tx_hash)
tx_hash = Utils.setup_multi_sig_tx_hash(tx, multi_sig_account_keypair)

#puts""
#this is what the JSON format of the acc_hash looks like that is sent to the mss-server
#puts "acc_hash in json format:  #{ActiveSupport::JSON.encode(tx_hash)}"
#exit -1

#at this point we could make some modifications to the final tx_hash before we publish or send it to the MSS server
#example:
#tx_hash["tx_title"]="first test of the multi-sign-server"
puts "tx_hash: #{tx_hash}"

#send the above created tx_hash to publish to mss-server that will continue to collect more sigs until enuf are collected to process
#Utils.send_to_multi_sign_server(tx_hash)

EM.run do
  conn = EventMachine::WebSocketClient.connect(Utils.configs["url_mss_server"])
  puts "url: #{Utils.configs["url_mss_server"]}"
  conn.callback do
    conn.send_msg tx_hash.to_json
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





