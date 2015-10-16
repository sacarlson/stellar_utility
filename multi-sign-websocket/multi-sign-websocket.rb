#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
require 'em-websocket'
require './multi_sign_lib.rb'


    if File.file?("./stellar_utilities.cfg")
      @configs = YAML.load(File.open("./stellar_utilities.cfg"))
      #puts "configs:  #{@configs}"
      puts ""
     
    else
      puts "no config file found at ./stellar_utilities.cfg, will exit"
      exit -1
    end
    
 witness_keypair = YAML.load(File.open("./secret_keypair_GCYSIZB4Q6ISTHFDXQMBBUPI4BVY7KW6QKCIZKTXAQBDXQYGRRIUTYSX.yml"))
 puts "witness account: #{witness_keypair.address}"
  
 puts "multi sign websocket server starting"
 puts ""

EM.run {
  trap(:INT) { EM::stop_event_loop }
  trap(:TERM){ EM::stop_event_loop }

  @mult_sig = Multi_sign.new(@configs)
  @mult_sig.create_db
  @clients = []

  EM::WebSocket.run(:host => @configs["mss_bind"], :port => @configs["mss_port"]) do |ws|
    ws.onopen { |handshake|
      @clients.push(ws)
      #puts "clients:  #{@clients}"
      puts "WebSocket connection open"

      # Access properties on the EM::WebSocket::Handshake object, e.g.
      # path, query_string, origin, headers

      # Publish message to the client
      ws.send '{"status":"success", "version":"'+@mult_sig.version+'"}'
    }

    ws.onclose {
      @clients.delete ws
      puts "Connection closed" }

    ws.onmessage { |msg|      
      puts "msg.length: #{msg.length}"
      msg = msg.delete("'")     
      puts "raw msg:  #{msg}"
      begin
       request_payload = ActiveSupport::JSON.decode(msg)
       #request_payload = JSON.parse(msg)
      rescue JSON::ParserError => e
        result = '{"status":"bad_JSON.parse","error":"'+ e.to_s + '", "raw_msg":"'+msg.to_s+'"}'
        puts "result: #{result}"
        ws.send(result)
        request_payload = {"action"=>"noop"}
      end  
      puts "payload: #{request_payload}"
 
      case request_payload["action"]
      when "create_acc"
        result = @mult_sig.add_acc(request_payload)
        string = result["acc_num"].to_s
        stat = '{"status"=>"success", "acc_num"=>"' + string + '"}'
        sendback = eval(stat)
        #puts "sendback: #{sendback}"
        ws.send sendback.to_json
      when "submit_tx"
        results = @mult_sig.add_tx(request_payload)
        ws.send results.to_json
        @clients.each do |socket|
          if socket != ws
            socket.send results.to_json
          end
        end
      when "get_tx"
        #puts "get_tx"
        results = @mult_sig.get_Tx(request_payload["tx_code"])
        ws.send results.to_json
      when "sign_tx"
        results = @mult_sig.sign_tx(request_payload)
        ws.send results.to_json
        @clients.each do |socket|
          if socket != ws
            socket.send results.to_json
          end
        end        
      when "status_tx"
        results = @mult_sig.check_tx_status(request_payload["tx_code"])
        ws.send results.to_json
      when "send_tx"
        results = @mult_sig.send_multi_sig_tx(request_payload["tx_code"])
        ws.send results.to_json
      when "get_account_info"
        results = @mult_sig.get_account_info(request_payload["account"])
        ws.send results.to_json
      when "get_lines_balance"
        value = @mult_sig.Utils.get_lines_balance_local(request_payload["account"],request_payload["issuer"],request_payload["asset"])
    '{"issuer":"'+request_payload["issuer"]+'", "asset":"'+request_payload["asset"]+'", "balance":'+results.to_s+'}'
        puts "result.class: #{value.class}"
        results = {"status"=>"success"}
        if value.nil?
          results["status"]="no record found"
          results["balance"] = 0
        else
           results["balance"] = value
        end
        puts "result: #{result}"
        ws.send results.to_json
      when "get_sell_offers"
        results = @mult_sig.Utils.get_sell_offers(request_payload["asset"],request_payload["issuer"], limit = 5)
        if results.nil?
          results = {"status"=>"no record found"}
        end
        ws.send results.to_json
      when "get_buy_offers"
        results = @mult_sig.Utils.get_buy_offers(request_payload["asset"],request_payload["issuer"], limit = 5)
        if results.nil?
          results = {"status"=>"no record found"}
        end
        ws.send results.to_json
      when "send_b64"
        results = @mult_sig.Utils.send_tx(request_payload["envelope_b64"])
        ws.send results.to_json
      when "get_acc_mss"
        results = @mult_sig.get_acc_mss(request_payload["account"])
        ws.send results.to_json
      when "version"
        ws.send '{"status":"success", "version":"'+@mult_sig.version+'"}'
      when "broadcast"
        request_payload.delete("action")
        request_payload.delete("tx_code")
        results = request_payload
        puts "bc: #{results}"
        ws.send results.to_json
        @clients.each do |socket|
          #socket.send results.to_json
          if socket != ws
            socket.send results.to_json
          end
        end
      when "get_signer_info"
        results = @mult_sig.Utils.get_signer_info(request_payload["account"],signer_address="")
        ws.send results.to_json
      when "get_thresholds_info"
        results = @mult_sig.Utils.get_thresholds_local(request_payload["account"])
        ws.send results.to_json 
      when "get_tx_history"
        results = @mult_sig.Utils.get_txhistory(request_payload["txid"])
        ws.send results.to_json
      when "make_witness"
        results = @mult_sig.Utils.make_witness_hash(witness_keypair,request_payload["account"],request_payload["asset"],request_payload["issuer"])
        ws.send results.to_json
      when "make_witness_unlock"
        results = @mult_sig.make_witness_unlock(witness_keypair,request_payload["account"],request_payload["timebound"],request_payload["asset"],request_payload["issuer"])
        ws.send results.to_json
      when "noop"
        puts "noop nothing done"
      when "stop"
        ws.send '{"status":"stoping_event_loop"}'
        EM::stop_event_loop
      else
        #'error bad action code in json: #{request_payload["action"]}'
      ws.send '{"error":"bad_action_code", "action":"'+request_payload["action"]+'"}'
    end
    }
  end
}


