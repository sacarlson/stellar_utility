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



acc_hash = {"action"=>"create_acc", "tx_title"=>"HHHM7L2GSH", "master_address"=>"GCUVO6WE54N7RUZSKW246BE76P4AQHF4RQJ2HA5LFWHPZMY2OHDBI3S2", "master_seed"=>"SDXRQELU2NXBPJRPDZEAWMNWHXCJUCLLPSCF6ID6U7ZSTHD4KXAGVHH5", "signers_total"=>3, "thesholds"=>{"master_weight"=>1, "low"=>"0", "med"=>1, "high"=>1}, "signer_weights"=>{"GAUKOWGRSXVQVGYXQZ5EWXIHKW3V6LUGUUSERUCPIGDRB6F244XMW5KY"=>1, "GABH7PJKTMTZMO7NJ4TD7KCOV5FC3OK4EDU2DRRZSJ4LO433NNXZR3OC"=>1}}


b64 = Utils.create_account_from_acc_hash(acc_hash,funder)
puts "res: #{b64}"
result = Utils.send_tx(b64) 
puts "res: #{result}"
