require 'thin'
require 'em-websocket'
require 'sinatra/base'

#require 'sinatra'
#require '../lib/stellar_utility/stellar_utility.rb'
require './multi_sign_lib.rb'

if File.file?("./stellar_utilities.cfg")
  configs = YAML.load(File.open("./stellar_utilities.cfg"))
  configs["mss_port2"] = configs["mss_port"].to_i + 1
else 
  puts "config file ./stellar_utilities.cfg not found, can't run without configs, will exit now"
  exit -1
end

witness_keypair = YAML.load(File.open("./secret_keypair_GCYSIZB4Q6ISTHFDXQMBBUPI4BVY7KW6QKCIZKTXAQBDXQYGRRIUTYSX.yml"))
 puts "witness account: #{witness_keypair.address}"

EM.run {
  
  class Server < Sinatra::Base
    configs = YAML.load(File.open("./stellar_utilities.cfg"))
    puts "configs_:  #{configs}"
    puts "sever started"
    mult_sig = Multi_sign.new(configs)

    post '/?' do 
      request.body.rewind
      #puts "request.body.read:  #{request.body.read}"
      s = request.body.read.to_s
      #puts "class: #{s.class}"
      s = s.delete("'")  
      puts "length: #{s.length}"
      #puts "hex: #{s.unpack('U'*s.length).collect {|x| x.to_s 16}.join}"
      #request_payload = JSON.parse(s)
      request_payload = ActiveSupport::JSON.decode(s)  
      puts "payload: #{request_payload}"
 
      case request_payload["action"]
      when "create_acc"
        result = mult_sig.add_acc(request_payload)
        string = result["acc_num"].to_s
        stat = '{"status"=>"success", "acc_num"=>"' + string + '"}'
        sendback = eval(stat)
        #puts "sendback: #{sendback}"
        sendback.to_json
      when "submit_tx"
        results = mult_sig.add_tx(request_payload)
        results.to_json
      when "get_tx"
        #puts "get_tx"
        results = mult_sig.get_Tx(request_payload["tx_code"])
        results.to_json
      when "sign_tx"
        #puts "payload: {#{request_payload}"
        results = mult_sig.sign_tx(request_payload)
        #puts "sign_tx results: #{results}"
        results.to_json
      when "status_tx"
        results = mult_sig.check_tx_status(request_payload["tx_code"])
        results.to_json
      when "send_tx"
        results = mult_sig.send_multi_sig_tx(request_payload["tx_code"])
        results.to_json
      when "send_native"
        begin
          results =  mult_sig.Utils.send_native(Stellar::KeyPair.from_seed(request_payload["from_seed"]), request_payload["to_account"], request_payload["amount"])
        rescue
          results = {"action"=>"send_native","status"=>"error" ,"error"=>"bad input"}
        end
        results.to_json
      when "send_asset"
        begin
          results =  mult_sig.Utils.send_currency(Stellar::KeyPair.from_seed(request_payload["from_seed"]), request_payload["to_account"],request_payload["issuer"], request_payload["amount"],request_payload["assetcode"])
        rescue
          results = {"action"=>"send_native","status"=>"error" ,"error"=>"bad input"}
        end
        results.to_json
      when "get_account_info"
        results = mult_sig.Utils.get_accounts_local(request_payload["account"])
        results.to_json
      when "get_lines_balance"
        results = mult_sig.Utils.get_trustlines_local(request_payload["account"],request_payload["issuer"],request_payload["asset"])
        #'{"issuer":"'+request_payload["issuer"]+'", "asset":"'+request_payload["asset"]+'", "balance":'+results.to_s+'}'
        puts "results: #{results}"
        results.to_json
      when "get_sell_offers"
        results = mult_sig.Utils.get_sell_offers(request_payload["asset"],request_payload["issuer"],request_payload["sort"], 10, request_payload["offset"])
        results.to_json
      when "get_buy_offers"
        results = mult_sig.Utils.get_buy_offers(request_payload["asset"],request_payload["issuer"],request_payload["sort"], 10, request_payload["offset"])
        results.to_json
      when "get_issuer_debt"
        results = mult_sig.Utils.issuer_debt_total(request_payload)
        results.to_json
      when "send_b64"
        results = mult_sig.Utils.send_tx(request_payload["envelope_b64"])
        results.to_json
      when "get_acc_mss"
        results = mult_sig.get_acc_mss(request_payload["account"])
        results.to_json
      when "get_sequence"
        sequence = mult_sig.Utils.get_sequence(request_payload["account"])
        results = {"status"=>"success", "account"=>request_payload["account"], "sequence"=>sequence}
        if sequence == 0
          results["status"] = "not_found"
        end
        results.to_json
      when "version"
        puts "got to version #{mult_sig.version}"
        '{"status":"success", "version":"'+mult_sig.version+'"}'
      else
        #'error bad action code in json: #{request_payload["action"]}'
        '{"error":"bad_action_code", "action":"'+request_payload["action"]+'"}'
      end #end case
    end #end post

    get '/help/?' do   
      "see https://github.com/sacarlson/stellar_utility/tree/master/multi-sign-websocket for more info"
    end

    get '/example/?' do   
      erb :example
    end

    get '/submit_tx/?' do
      erb :submit_tx
    end

    get '/transactions/?' do
      #can't get this to work yet
      #it was suposed to work the same as horizon
      request.body.rewind
      s = request.body.read.to_s
      puts "s: #{s}"
      s = s.delete("'")   
      puts "length_tx: #{s.length}"
      #puts "hex: #{s.unpack('U'*s.length).collect {|x| x.to_s 16}.join}"
      request_payload = ActiveSupport::JSON.decode(s)  
      puts "payload: #{request_payload}"
      results = mult_sig.Utils.send_tx(request_payload["tx"])
      results.to_json
    end

  end #end class Server


  trap(:INT) { EM::stop_event_loop }
  trap(:TERM){ EM::stop_event_loop }
  mult_sig = Multi_sign.new(configs)
  mult_sig.create_db
  clients = []

 EM::WebSocket.run(:host => configs["mss_bind"], :port => configs["mss_port"]) do |ws|
    ws.onopen { |handshake|
      clients.push(ws)
      #puts "clients:  #{clients}"
      puts "WebSocket connection open"

      # Access properties on the EM::WebSocket::Handshake object, e.g.
      # path, query_string, origin, headers

      # Publish message to the client
      ws.send '{"status":"success", "version":"'+mult_sig.version+'"}'
    }

    ws.onclose {
      clients.delete ws
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
        result = mult_sig.add_acc(request_payload)
        string = result["acc_num"].to_s
        stat = '{"status"=>"success", "acc_num"=>"' + string + '"}'
        sendback = eval(stat)
        #puts "sendback: #{sendback}"
        ws.send sendback.to_json
      when "submit_tx"
        results = mult_sig.add_tx(request_payload)
        ws.send results.to_json
        clients.each do |socket|
          if socket != ws
            socket.send results.to_json
          end
        end
      when "get_tx"
        #puts "get_tx"
        results = mult_sig.get_Tx(request_payload["tx_code"])
        ws.send results.to_json
      when "sign_tx"
        results = mult_sig.sign_tx(request_payload)
        ws.send results.to_json
        clients.each do |socket|
          if socket != ws
            socket.send results.to_json
          end
        end        
      when "status_tx"
        results = mult_sig.check_tx_status(request_payload["tx_code"])
        ws.send results.to_json
      when "send_tx"
        results = mult_sig.send_multi_sig_tx(request_payload["tx_code"])
        ws.send results.to_json
      when "send_native"
        begin
          results =  mult_sig.Utils.send_native(Stellar::KeyPair.from_seed(request_payload["from_seed"]), request_payload["to_account"], request_payload["amount"])
        rescue
          results = {"action"=>"send_native","status"=>"error" ,"error"=>"bad input"}
        end
        ws.send results.to_json
      when "send_asset"
        begin
          results =  mult_sig.Utils.send_currency(Stellar::KeyPair.from_seed(request_payload["from_seed"]), request_payload["to_account"],request_payload["issuer"], request_payload["amount"],request_payload["assetcode"])
        rescue
          results = {"action"=>"send_native","status"=>"error" ,"error"=>"bad input"}
        end
        ws.send results.to_json
      when "get_sorted_holdings"
        results = mult_sig.Utils.get_sorted_holdings(request_payload)
        ws.send results.to_json
      when "get_account_info"
        #results = mult_sig.get_account_info(request_payload["account"])
        results = mult_sig.Utils.get_accounts_local(request_payload["account"])
        #results["action"]= "get_account_info"
        ws.send results.to_json
      when "get_lines_balance"
        results = mult_sig.Utils.get_trustlines_local(request_payload["account"],request_payload["issuer"],request_payload["asset"])
        #'{"issuer":"'+request_payload["issuer"]+'", "asset":"'+request_payload["asset"]+'", "balance":'+results.to_s+'}'
        puts "results: #{results}"
        ws.send results.to_json
      when "get_offerid"      
        results = mult_sig.Utils.get_offers(nil, nil, nil, nil, nil, nil, nil, request_payload["offerid"])
        if results.nil?
          results = {"status"=>"no record found"}
        end
        ws.send results.to_json
      when "get_sell_offers"
        results = mult_sig.Utils.get_sell_offers(request_payload["asset"],request_payload["issuer"],request_payload["sort"], 10, request_payload["offset"])
        if results.nil?
          results = {"status"=>"no record found"}
        end
        ws.send results.to_json
      when "get_buy_offers"
        results = mult_sig.Utils.get_buy_offers(request_payload["asset"],request_payload["issuer"],request_payload["sort"], 10, request_payload["offset"])
        if results.nil?
          results = {"status"=>"no record found"}
        end
        ws.send results.to_json
      when "send_b64"
        results = mult_sig.Utils.send_tx(request_payload["envelope_b64"])
        ws.send results.to_json
      when "get_acc_mss"
        results = mult_sig.get_acc_mss(request_payload["account"])
        ws.send results.to_json
      when "version"
        ws.send '{"status":"success", "version":"'+mult_sig.version+'"}'
      when "broadcast"
        request_payload.delete("action")
        request_payload.delete("tx_code")
        results = request_payload
        puts "bc: #{results}"
        ws.send results.to_json
        clients.each do |socket|
          #socket.send results.to_json
          if socket != ws
            socket.send results.to_json
          end
        end
      when "get_signer_info"
        results = mult_sig.Utils.get_signer_info(request_payload["account"],signer_address="")
        ws.send results.to_json
      when "get_thresholds_info"
        results = mult_sig.Utils.get_thresholds_local(request_payload["account"])
        ws.send results.to_json
      when "get_issuer_debt"
        results = mult_sig.Utils.issuer_debt_total(request_payload)
        ws.send results.to_json
      when "get_tx_hist"
        results = mult_sig.Utils.get_tx_hist(request_payload)
        ws.send results.to_json 
      when "get_tx_history"
        results = mult_sig.Utils.get_txhistory(request_payload["txid"],1)
        ws.send results.to_json
      when "get_account_tx_history"
        results = mult_sig.Utils.get_account_txhistory(request_payload["account"],request_payload["offset"])
        ws.send results.to_json
      when "make_witness"
        results = mult_sig.Utils.make_witness_hash(witness_keypair,request_payload["account"],request_payload["asset"],request_payload["issuer"])
        ws.send results.to_json
      when "make_witness_unlock"
        results = mult_sig.make_witness_unlock(witness_keypair,request_payload["account"],request_payload["timebound"],request_payload["asset"],request_payload["issuer"])
        ws.send results.to_json
      when "core_status"
        results = mult_sig.Utils.get_stellar_core_status(true)
        ws.send results.to_json
      when "get_sequence"
        sequence = mult_sig.Utils.get_sequence(request_payload["account"])
        results = {"status"=>"success", "action"=>"get_sequence", "account"=>request_payload["account"], "sequence"=>sequence}
        if sequence == 0
          results["status"] = "not_found"
        end   
        ws.send results.to_json
      when "search_signable_tx"
        results  = mult_sig.search_signable_tx(request_payload["account"])
        ws.send results.to_json
      when "noop"
        puts "noop nothing done"
      when "stop"
        ws.send '{"status":"stoping_event_loop"}'
        EM::stop_event_loop
      else
        #'error bad action code in json: #{request_payload["action"]}'
        ws.send '{"error":"bad_action_code", "action":"'+request_payload["action"]+'"}'
      end #end case
    }#end ws.onmessage
  end #end EM::WebSocket.run

 Server.run! :port => configs["mss_port2"] ,:bind => configs["mss_bind"] 

} #end EM.run
