require 'sinatra'
#require '../lib/stellar_utility/stellar_utility.rb'
require './multi_sign_lib.rb'

if File.file?("./stellar_utilities.cfg")
  configs = YAML.load(File.open("./stellar_utilities.cfg"))
else 
  configs = {}
  configs["mss_db_file_path"] = "./multisign.db"
  configs["mss_db_mode"] = "sqlite"
  configs["mss_bind"] = '0.0.0.0'
  configs["mss_port"] = 9494
end

set :bind, configs["mss_bind"]
set :port, configs["mss_port"]

puts "configs:  #{configs}"
puts "sever started"


post '/' do
  #status 204 #successful request with no body content
  #configs = {}
  #configs["mss_db_file_path"] = "/home/sacarlson/github/stellar/stellar_utility/multi-sign-server/multisign.db"
  #configs["mss_db_mode"] = "sqlite"
  @mult_sig = Multi_sign.new(configs)
  @mult_sig.create_db

  request.body.rewind
  #puts "request.body.read:  #{request.body.read}"
  s = request.body.read.to_s
  #puts "class: #{s.class}"
  puts "length: #{s.length}"
  #puts "hex: #{s.unpack('U'*s.length).collect {|x| x.to_s 16}.join}"
  #request_payload = JSON.parse(s)
  request_payload = ActiveSupport::JSON.decode(s)  
  puts "payload: #{request_payload}"
 
  case request_payload["action"]
  when "create_acc"
    result = @mult_sig.add_acc(request_payload)
    string = result["acc_num"].to_s
    stat = '{"status"=>"success", "acc_num"=>"' + string + '"}'
    sendback = eval(stat)
    #puts "sendback: #{sendback}"
    sendback.to_json
  when "submit_tx"
    results = @mult_sig.add_tx(request_payload)
    results.to_json
  when "get_tx"
    #puts "get_tx"
    results = @mult_sig.get_Tx(request_payload["tx_code"])
    results.to_json
  when "sign_tx"
    #puts "payload: {#{request_payload}"
    results = @mult_sig.sign_tx(request_payload)
    #puts "sign_tx results: #{results}"
    results.to_json
  when "status_tx"
    results = @mult_sig.check_tx_status(request_payload["tx_code"])
    results.to_json
  when "send_tx"
    results = @mult_sig.send_multi_sig_tx(request_payload["tx_code"])
    results.to_json
  when "get_account_info"
    results = @mult_sig.get_account_info(request_payload["account"])
    results.to_json
  when "get_lines_balance"
    results = @mult_sig.Utils.get_lines_balance_local(request_payload["account"],request_payload["issuer"],request_payload["asset"])
    '{"issuer":"'+request_payload["issuer"]+'", "asset":"'+request_payload["asset"]+'", "balance":'+results.to_s+'}'
  when "get_sell_offers"
    results = @mult_sig.Utils.get_sell_offers(request_payload["asset"],request_payload["issuer"], limit = 5)
    results.to_json
  when "get_buy_offers"
    results = @mult_sig.Utils.get_buy_offers(request_payload["asset"],request_payload["issuer"], limit = 5)
    results.to_json
  when "send_b64"
    results = @mult_sig.Utils.send_tx(request_payload["envelope_b64"])
    results.to_json
  when "get_acc_mss"
    results = @mult_sig.get_acc_mss(request_payload["account"])
    results.to_json
  when "version"
    '{"status":"success", "version":"'+@mult_sig.version+'"}'
  else
    #'error bad action code in json: #{request_payload["action"]}'
    '{"error":"bad_action_code", "action":"'+request_payload["action"]+'"}'
  end
end

get '/help/?' do   
  "add help here later"
end

