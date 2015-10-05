#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
# this will demonstrate how a client would use the multi-sign-server to get an unsigned transaction envelope
# from the mss-server, sign it and return the signature to the mss-server that will continue to collect the remaining
# needed signatures from other signers until the threshold is met so the transaction can be submited to the stellar
# network to be validated and processed.
 
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
# load the keypairs needed to sign the pregenerated transaction submited with submit_transaction_to_mss.rb
#multi_sig_account_keypair = YAML.load(File.open("./multi_sig_account_keypair.yml"))
signerA_keypair = YAML.load(File.open("./signerA_keypair.yml"))
signerB_keypair = YAML.load(File.open("./signerB_keypair.yml"))

puts "signerA_keypair address #{signerA_keypair.address}"
puts "signerB_keypair address #{signerB_keypair.address}"

keypair = signerB_keypair


#this code must be changed to the tx_code created when submit_transaction created it.
#tx_code = "T_A54WFQAz"
#tx_code = "T_A54WFQAF"
tx_code = "last"


#example of what was returned in sign_hash:
#sign_hash:  {"action"=>"sign_tx", "tx_title"=>"ODEDFG4QER", "tx_code"=>"ODEDFG4QER", "signer_address"=>"GB2HYLGOZLUSSKEP47EY2GQE66KMEYT4AMFBV6NCBJGEKYONG6S5BMBO", "signer_weight"=>"1", "tx_envelope_b64"=>"AAAAAFiNI2HQ5glD03WWMluyTdaN531sZBGTiCWjxhduGzxIAAAACgAAAAAAAAABAAAAAAAAAAAAAAABAAAAAAAAAAUAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAACHRlc3Q4ODE0AAAAAAAAAAAAAAACzTel0AAAAEAL/QFdoLkWub9Q+hjjYMQtSUdvVilDcRpKHGVDq6HQfpshiDIU9v7UexU6J1Bn/LDAw8MeLCxF98LFB3rJgHcBbhs8SAAAAECnAXIm6tt8WUcATFpM5R4rWS9YVw2oRSyN9omRLDjCvz3HW6EToDCCUAp4Nnl9dChwN88Mf3ohTUm7gWFP8q0L", "signer_sig"=>"JIDYR..."}

#puts""
#this is what the JSON format of the acc_hash looks like that is sent to the mss-server
#puts "acc_hash in json format:  #{ActiveSupport::JSON.encode(sign_hash)}"
#exit -1


#we could again modify this sign_hash before we send it to the mss-server example:
#sign_hash["tx_title"] = "change the tx title"
# we could later send the signer_sig instead of the signed tx_envelope_b64 if desired, but I haven't writen that part yet.
# also the singers signer_weight is assumed to be 1 here but the writer of the tx could have modified that and the signer can change that here.
# the signer must know his weight to submit any changes here or the mss-server will attempt to transact the tx with the wrong number of weighted signers.
#sign_hash["signer_weight"] = 2
# in most cases the default signer_weight is good.
# we could also later pull the signer weights from the stellar-core network db instead of tracking it at the mss-server, but again I haven't writen that yet.
# but the way it is presently writen the mss-server can now run on a system without any local stellar-core running by using horizion to do final submitions.


signed = 0

EM.run do
  trap(:INT) { EM::stop_event_loop }
  trap(:TERM){ EM::stop_event_loop }

  conn = EventMachine::WebSocketClient.connect(Utils.configs["url_mss_server"])
  puts "url: #{Utils.configs["url_mss_server"]}"
  conn.callback do
    get_tx = {"action"=>"get_tx","tx_code"=>"7ZZUMOSZ26"}
    get_tx["tx_code"] = tx_code    
    conn.send_msg get_tx.to_json
    #conn.send_msg "done"
  end

  conn.errback do |e|
    puts "Got error: #{e}"
    EM::stop_event_loop
  end

  conn.stream do |msg|
    puts "msg: #{msg.to_s}"
    if !(msg.to_s == "null")
      mss_get_tx_hash = JSON.parse(msg.to_s)
      if (mss_get_tx_hash["tx_code"] == tx_code and signed == 0) or (tx_code == "last" and signed == 0)
        if (tx_code == "last") and (mss_get_tx_hash["signer"]==1)
          tx_code = mss_get_tx_hash["tx_code"]
          get_tx = {"action"=>"get_tx","tx_code"=>"7ZZUMOSZ26"}
          get_tx["tx_code"] = tx_code    
          conn.send_msg get_tx.to_json
        else
          puts "mss: #{mss_get_tx_hash}" 
          sign_hash = Utils.sign_mss_hash(keypair,mss_get_tx_hash,sigmode=0)
          sign_hash["action"] = "sign_tx"
          puts "sign_hash: #{sign_hash}"
          conn.send_msg sign_hash.to_json
          signed = 1
        end
      end
    end
  end

  conn.disconnect do
    puts "disconnected or can't make connection , stoping event loop"
    EM::stop_event_loop
  end
end



