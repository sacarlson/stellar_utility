require 'json'
require 'rest-client'
require 'active_support'
#require 'active_support/all'
#mockup test to send planed format for multi-sig-tx and multi-sig-account
    create_acc = {"action"=>"create_acc","tx_title"=>"first multi-sig tx","master_address"=>"GDZ4AF...","master_seed"=>"SDRES6...","signers_total"=>"2", "thresholds"=>{"master_weight"=>"1","low"=>"0","med"=>"2","high"=>"2"},"signer_weights"=>{"GDZ4AF..."=>"1","GDOJM..."=>"1","zzz"=>"1"}}
    status_tx = {"action"=>"status_tx","tx_code"=>"RQJXT3BNBU"}
    status_acc = {"action"=>"status_acc","acc_num"=>"GDZ4AF..."}
    submit_tx = {"action"=>"submit_tx","tx_title"=>"test multi sig tx","acc_num"=>"123", "tx_envelope_b64"=>"AAAA..."}
    return_submit_tx = {"status"=>"success","tx_code"=>"URWOTGHR"}
    get_tx = {"action"=>"get_tx","tx_code"=>"RQJXT3BNBU"}
    return_get_tx = {"status"=>"pending","tx_num"=>"123","tx_envelope_b64"=>"AAAA..."}
    sign_tx = {"action"=>"sign_tx","tx_title"=>"test tx","tx_code"=>"JIEWFJYE", "signer_address"=>"GAJYGYI...", "signer_weight"=>"1", "tx_envelope_b64"=>"AAAA..."}
    return_sign_tx = {"status"=>"pending","tx_code"=>"URWOTGHR"}
    send_tx = {"action"=>"send_tx","tx_code"=>"T_RQHKC7XD"}
    get_account_info = {"action"=>"get_account_info", "account"=>"GCYFPRSLBKMREKY4GF6Z6WDTNRUYFQW4URL2JL3GUAXSG33DMGZF2NKF"}
    get_lines_balance = {"action"=>"get_lines_balance", "account"=>"GAJYGYI...", "issuer"=>"GDZ4AF...", "asset"=>"USD"} 
    get_sell_offers = {"action"=>"get_sell_offers", "issuer"=>"GDZ4AF...","asset"=>"USD","limit"=>"10"}
    get_buy_offers = {"action"=>"get_buy_offers", "issuer"=>"GDZ4AF...","asset"=>"USD","limit"=>"1"}
    get_buy_offers = {"action"=>"get_buy_offers", "issuer"=>"any","asset"=>"any"}
    version = {"action"=>"version"}
    return_version = {"status"=>"success", "version"=>"0.1.0"}
    send_b64 = {"action"=>"send_b64", "envelope_b64"=>"AAAA..."}

    create_account = {"action"=>"create_acc", "tx_title"=>"A_M7U2T7A", "master_address"=>"GDM6RBPBTDY3YE35I7LLU53LP4IZH26PIFE5IFPITGCEOZBX66IFZIDH", "master_seed"=>"none_provided", "start_balance"=>100, "signers_total"=>3, "thresholds"=>{"master_weight"=>1, "low"=>"0", "med"=>3, "high"=>3}, "signer_weights"=>{"GCHOUZUXO2CKBJJICJ6R4EHRLSKCANGD3QTACE5QZJ27T7TSGMD4JP5U"=>1, "GCFZMOSTNINJB65VOSXY3RKATANT7DQJJVUMJGSXMCAOBUUENSQME4ZZ"=>1}}

    create_account2 = {"action"=>"create_acc", "tx_title"=>"A_M7U2T7Z", "master_address"=>"GDM6RBPBTDY3YE35I7LLU53LP4IZH26PIFE5IFPITGCEOZBX66IFZIDZ", "master_seed"=>"none_provided", "start_balance"=>100, "signers_total"=>3, "thresholds"=>{"master_weight"=>1, "low"=>"0", "med"=>3, "high"=>3}, "signer_weights"=>{"GCHOUZUXO2CKBJJICJ6R4EHRLSKCANGD3QTACE5QZJ27T7TSGMD4JP5U"=>1, "GCFZMOSTNINJB65VOSXY3RKATANT7DQJJVUMJGSXMCAOBUUENSQME4ZZ"=>1}}

    
    return_status_tx = {"status"=>"sent","tx_num"=>"123","sign_count"=>"2","signed"=>["GDZ4AF...","GDOJM..."]}
    #status pending means that the transaction hasn't got all the needed signers yet, sent means we got the signers and it was transacted
    return_status_tx_not_sent = {"status"=>"pending","tx_num"=>"123","sign_count"=>"1","signed"=>["GDZ4AF..."]}
    #dataout = {"signed"=>[xyz,zyx]}
    #data = get_tx
    #data = get_account_info
    data = send_tx
    url = "localhost:9494"
    s = data.to_json
    puts "sent: #{data.to_json}"
    puts "will recieve: #{JSON.parse(data.to_json)}"
    puts "Active::JSON.encode: #{ActiveSupport::JSON.encode(data)}"
    puts "Active::JSON.decode: #{ActiveSupport::JSON.decode(data.to_json)}"
    puts "length:  #{data.to_json.length}"
    puts "hex: #{s.unpack('U'*s.length).collect {|x| x.to_s 16}.join}"
    #postdat = RestClient.post url, data.to_json 
    postdat = RestClient.post url, ActiveSupport::JSON.encode(data)
    #postdat = RestClient::Resource.new(url).post(data).to_json 
    puts ""
    puts "#{postdat}"
    #data = JSON.parse(postdat)   
    #puts "data: #{data}"   

