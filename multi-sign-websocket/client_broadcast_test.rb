#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
# this will demonstrate the broadcast action in multi-sign-websocket
# it will allow users to send messages to all the group that is presently connected to the server
# we will also add message authentication so that messages can be verified as comeing from someone holding
# the seed of account that the messaged is said to originate from
# when sending authenticated messages there will be 3 standard key value sets
# including "message", "signer_address", "sig_b64"
# the sig_b64 is a b64 encoded signature derived from the function sign_msg(string_msg, keypair) with the signature identified with "signer_address"
# the recieve side uses the function verify_signed_msg(string_msg, address, sig_b64) to verify authenticity 
 
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

keypair = signerA_keypair


#this code must be changed to the tx_code created when submit_transaction created it.
#if tx_code is set to "last" then a request for get_tx last will be sent and the first tx_code string seen will be signed 1 time
#tx_code = "T_A54WFQAz"
#tx_code = "T_A54WFQAF"
#tx_code = "last"
tx_code = "none"


#example of what was returned in sign_hash:
#sign_hash:  {"action"=>"sign_tx", "tx_title"=>"ODEDFG4QER", "tx_code"=>"ODEDFG4QER", "signer_address"=>"GB2HYLGOZLUSSKEP47EY2GQE66KMEYT4AMFBV6NCBJGEKYONG6S5BMBO", "signer_weight"=>"1", "tx_envelope_b64"=>"AAAAAFiNI2HQ5glD03WWMluyTdaN531sZBGTiCWjxhduGzxIAAAACgAAAAAAAAABAAAAAAAAAAAAAAABAAAAAAAAAAUAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAACHRlc3Q4ODE0AAAAAAAAAAAAAAACzTel0AAAAEAL/QFdoLkWub9Q+hjjYMQtSUdvVilDcRpKHGVDq6HQfpshiDIU9v7UexU6J1Bn/LDAw8MeLCxF98LFB3rJgHcBbhs8SAAAAECnAXIm6tt8WUcATFpM5R4rWS9YVw2oRSyN9omRLDjCvz3HW6EToDCCUAp4Nnl9dChwN88Mf3ohTUm7gWFP8q0L", "signer_sig"=>"JIDYR..."}



signed = 0

EM.run do
  trap(:INT) { EM::stop_event_loop }
  trap(:TERM){ EM::stop_event_loop }

  conn = EventMachine::WebSocketClient.connect(Utils.configs["url_mss_server"])
  puts "url: #{Utils.configs["url_mss_server"]}"
  conn.callback do
    #get_tx = {"action"=>"get_tx","tx_code"=>"7ZZUMOSZ26"}
    #get_tx["tx_code"] = tx_code 
    action = {"action"=>"broadcast","message"=>"hello world"}
    time = Time.now.to_i.to_s
    action["message"] = action["message"] + ":" + time
    sig_b64 = Utils.sign_msg(action["message"], signerA_keypair)
    #sig_b64 = Utils.sign_msg("bad boy", signerA_keypair)
    action["sig_b64"] = sig_b64
    action["signer_address"] = signerA_keypair.address
    action["time_stamp"] = time
    conn.send_msg action.to_json
    #conn.send_msg "done"
  end

  conn.errback do |e|
    puts "Got error: #{e}"
    EM::stop_event_loop
  end

  conn.stream do |msg|
    puts "raw msg: #{msg.to_s}"
    if !(msg.to_s == "null")
      mss_get_tx_hash = JSON.parse(msg.to_s)
      if (mss_get_tx_hash["tx_code"] == tx_code and signed == 0) or (tx_code == "last" and signed == 0)
        if (tx_code == "last") and ((mss_get_tx_hash["signer"]==1) or (mss_get_tx_hash["tx_envelope_b64"].nil?))
          tx_code = mss_get_tx_hash["tx_code"]
          get_tx = {"action"=>"get_tx","tx_code"=>"7ZZUMOSZ26"}
          get_tx["tx_code"] = tx_code    
          conn.send_msg get_tx.to_json
        else
          sign_hash = Utils.sign_mss_hash(keypair,mss_get_tx_hash,sigmode=0)
          sign_hash["action"] = "sign_tx"
          puts "sign_hash: #{sign_hash}"
          conn.send_msg sign_hash.to_json
          signed = 1
        end
      end
      if !mss_get_tx_hash["message"].nil?
        puts "got a message will authenticate"
        if Utils.verify_signed_msg(mss_get_tx_hash["message"], mss_get_tx_hash["signer_address"], mss_get_tx_hash["sig_b64"])
          puts "messages is authenticated as GOOD"
          if Utils.check_timestamp(mss_get_tx_hash["message"],mss_get_tx_hash["time_stamp"])
            puts "time_stamp is within tolerence"
            puts "message:  #{mss_get_tx_hash["message"]}"
          else
            puts "time_stamp is out of tolerence, will igonore"
          end          
        else
          puts "message had bad signature, will ignore"
        end
      end
    end
  end

  conn.disconnect do
    puts "disconnected or can't make connection , stoping event loop"
    EM::stop_event_loop
  end
end



