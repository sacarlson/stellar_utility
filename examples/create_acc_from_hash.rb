#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
# almost works last I got was {"hash":"cd0de84bf30039ac8cec2021cabee7716e8921d5289a24782002ea3d5d058ed3","result":"failed","error":"AAAAAAAAAAD////6AAAAAA=="}
# bad authorization not enuf sigs
require '../lib/stellar_utility/stellar_utility.rb'

Utils = Stellar_utility::Utils.new("horizon")
puts "Utils version: #{Utils.version}"
puts "configs: #{Utils.configs}"

master  = Stellar::KeyPair.master
funder = master



acc_hash = {"action"=>"create_acc", "tx_title"=>"TP5NV7WN53", "master_address"=>"GDKQJNX4DQRHVE76ZOIGQSYZR2PDX4XSDT3CAKM7F6NSZBOQ6D5QDLBD", "master_seed"=>"SDEH6BEVCMLFGAO5SAOQOWVDIFT5XS466OJQ3CZEU6OSYOXJPQQ66CYR", "start_balance"=>41, "signers_total"=>3, "thresholds"=>{"master_weight"=>1, "low"=>"0", "med"=>3, "high"=>3}, "signer_weights"=>{"GA2F3NNTSJEX2L7QJHPS4GMSQKGUMKZESTUIRXUZLHZXSQGBNBIJCMET"=>1, "GBCGQWBATTLZW6PWX7H4TNRDDWDFCZAWCGTXWYPHRHRS534HMC5HXWUY"=>1}}


b64 = Utils.create_account_from_acc_hash(acc_hash,funder)
#b64 = Utils.create_account_from_acc_hash(acc_hash)
puts "res: #{b64}"
#result = Utils.send_tx(b64) 
#puts "res: #{result}"
