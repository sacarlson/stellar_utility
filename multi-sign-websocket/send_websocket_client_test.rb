require 'json'
require 'active_support'
require 'em-websocket-client'

#mockup test to send planed format for multi-sign-tx and multi-sign-account
    create_acc = {"action"=>"create_acc","tx_title"=>"first multi-sig tx","master_address"=>"GDZ4AF...","master_seed"=>"SDRES6...","signers_total"=>"2", "thresholds"=>{"master_weight"=>"1","low"=>"0","med"=>"2","high"=>"2"},"signer_weights"=>{"GDZ4AF..."=>"1","GDOJM..."=>"1","zzz"=>"1"}}
    status_tx = {"action"=>"status_tx","tx_code"=>"T_RQHKC7XD"}
    status_acc = {"action"=>"status_acc","acc_num"=>"GDZ4AF..."}
    submit_tx = {"action"=>"submit_tx","tx_title"=>"test multi sig tx","acc_num"=>"123", "tx_envelope_b64"=>"AAAA..."}
    return_submit_tx = {"status"=>"success","tx_code"=>"URWOTGHR"}
    get_tx = {"action"=>"get_tx","tx_code"=>"T_RQHKC7XD"}
    return_get_tx = {"status"=>"pending","tx_num"=>"123","tx_envelope_b64"=>"AAAA..."}
    sign_tx = {"action"=>"sign_tx","tx_title"=>"test tx","tx_code"=>"JIEWFJYE", "signer_address"=>"GAJYGYI...", "signer_weight"=>"1", "tx_envelope_b64"=>"AAAA..."}
    return_sign_tx = {"status"=>"pending","tx_code"=>"URWOTGHR"}
    send_tx = {"action"=>"send_tx","tx_code"=>"T_RQHKC7XD"}
    get_account_info = {"action"=>"get_account_info", "account"=>"GDM6RBPBTDY3YE35I7LLU53LP4IZH26PIFE5IFPITGCEOZBX66IFZIDH"}
    get_lines_balance = {"action"=>"get_lines_balance", "account"=>"GDGH5R4YPMN3HKQ6GEAEW2GPA5FJSS23LSAAD7CU22BHPZAMM7BHR634", "issuer"=>"GC3IIU5Q2WLRC4B7T4GYBJ2UKOQ67RITKTVHCKC6UPECI6RT6JMDUPJO", "asset"=>"CHP"} 
    get_sell_offers = {"action"=>"get_sell_offers", "issuer"=>"GDZ4AF...","asset"=>"USD","limit"=>"10"}
    get_buy_offers = {"action"=>"get_buy_offers", "issuer"=>"GDZ4AF...","asset"=>"USD","limit"=>"1"}
    get_buy_offers = {"action"=>"get_buy_offers", "issuer"=>"any","asset"=>"any"}
    get_acc_mss = {"action"=>"get_acc_mss", "account"=>"GDM6RBPBTDY3YE35I7LLU53LP4IZH26PIFE5IFPITGCEOZBX66IFZIDH"}
    version = {"action"=>"version"}
    return_version = {"status"=>"success", "version"=>"0.1.0"}
    send_b64 = {"action"=>"send_b64", "envelope_b64"=>"AAAAAOo1QK/3upA74NLkdq4Io3DQAQZPi4TVhuDnvCYQTKIVAAAACgAAH8AAAAABAAAAAAAAAAAAAAABAAAAAQAAAADqNUCv97qQO+DS5HauCKNw0AEGT4uE1Ybg57wmEEyiFQAAAAEAAAAAZc2EuuEa2W1PAKmaqVquHuzUMHaEiRs//+ODOfgWiz8AAAAAAAAAAAAAA+gAAAAAAAAAARBMohUAAABAPnnZL8uPlS+c/AM02r4EbxnZuXmP6pQHvSGmxdOb0SzyfDB2jUKjDtL+NC7zcMIyw4NjTa9Ebp4lvONEf4yDBA=="}

    send_b64 = {"action"=>"send_b64", "envelope_b64"=>"AAAAAOo1QK/3upA74NLkdq4Io3DQAQZPi4TVhuDnvCYQTKIVAAAACgAAH8AAAAABAAAAAAAAAAAAAAABAAAAAQAAAADqNUCv97qQO+DS5HauCKNw0AEGT4uE1Ybg57wmEEyiFQAAAAEAAAAAZc2EuuEa2W1PAKmaqVquHuzUMHaEiRs//+ODOfgWiz8AAAAAAAAAAAAAA+gAAAAAAAAAARBMohUAAABAPnnZL8uPlS+c/AM02r4EbxnZuXmP6pQHvSGmxdOb0SzyfDB2jUKjDtL+NC7zcMIyw4NjTa9Ebp4lvONEf4yDBA=="}

    create_account = {"action"=>"create_acc", "tx_title"=>"A_M7U2T7A", "master_address"=>"GDM6RBPBTDY3YE35I7LLU53LP4IZH26PIFE5IFPITGCEOZBX66IFZIDH", "master_seed"=>"none_provided", "start_balance"=>100, "signers_total"=>3, "thresholds"=>{"master_weight"=>1, "low"=>"0", "med"=>3, "high"=>3}, "signer_weights"=>{"GCHOUZUXO2CKBJJICJ6R4EHRLSKCANGD3QTACE5QZJ27T7TSGMD4JP5U"=>1, "GCFZMOSTNINJB65VOSXY3RKATANT7DQJJVUMJGSXMCAOBUUENSQME4ZZ"=>1}}

    create_account2 = {"action"=>"create_acc", "tx_title"=>"A_M7U2T7Z", "master_address"=>"GDM6RBPBTDY3YE35I7LLU53LP4IZH26PIFE5IFPITGCEOZBX66IFZIDZ", "master_seed"=>"none_provided", "start_balance"=>100, "signers_total"=>3, "thresholds"=>{"master_weight"=>1, "low"=>"0", "med"=>3, "high"=>3}, "signer_weights"=>{"GCHOUZUXO2CKBJJICJ6R4EHRLSKCANGD3QTACE5QZJ27T7TSGMD4JP5U"=>1, "GCFZMOSTNINJB65VOSXY3RKATANT7DQJJVUMJGSXMCAOBUUENSQME4ZZ"=>1}}


    submit_tx = '{"action":"submit_tx","tx_title":"T_JD7NBZPV","signer_address":"GDM6RBPBTDY3YE35I7LLU53LP4IZH26PIFE5IFPITGCEOZBX66IFZIDH","signer_weight":"1","master_address":"GDM6RBPBTDY3YE35I7LLU53LP4IZH26PIFE5IFPITGCEOZBX66IFZIDH","tx_envelope_b64":"AAAAANnoheGY8bwTfUfWundrfxGT689BSdQV6JmER2Q395BcAAAACgABh04AAAADAAAAAAAAAAAAAAABAAAAAAAAAAUAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAACHRlc3Q1NjkyAAAAAAAAAAAAAAABN/eQXAAAAEBaa64v1Pvh3g0eM1w5g9tlli/O6J0T4FPu9ifle3xGDyOLvGo7W2bpZ+uS9q31se2UMbd5gr0HFPivvuZyanYL","signer_sig_b64":""}'

    sign_tx = '{"action":"sign_tx","tx_title":"T_RQHKC7XD","tx_code":"T_RQHKC7XD","signer_address":"GCHOUZUXO2CKBJJICJ6R4EHRLSKCANGD3QTACE5QZJ27T7TSGMD4JP5U","signer_weight":"1","tx_envelope_b64":"AAAAANnoheGY8bwTfUfWundrfxGT689BSdQV6JmER2Q395BcAAAACgABh04AAAACAAAAAAAAAAAAAAABAAAAAAAAAAUAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAACHRlc3Q3NDM2AAAAAAAAAAAAAAACcjMHxAAAAEApyJ3gfjYOZaAzY4ZLnt7uJCPrLlR1cPAos4fMRyrBrF2yrfz6U3dsAbv8tpmCMISiS9vZtKExaDZnsqdB1jcEN/eQXAAAAEB2xFD4v6goEazu9UeLY0naWENxGwDKktFquSF0MJN6MPYrucRuRFzYK/xRofZzl8EIljizva+XBEk/SRioh6QL","signer_sig_b64":"cjMHxAAAAEApyJ3gfjYOZaAzY4ZLnt7uJCPrLlR1cPAos4fMRyrBrF2yrfz6U3dsAbv8tpmCMISiS9vZtKExaDZnsqdB1jcE"}'

    get_signer_info = {"action"=>"get_signer_info", "account"=>"GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO"} 
    #returns: {"signers"=>[{"accountid"=>"GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO", "publickey"=>"GBT6G2KZI4ON3LTVRWEPT3GH66TTBTN77SIHRGNQ4KAU7N3GTFLYXYOM", "weight"=>1}]}

    get_thresholds_info = {"action"=>"get_thresholds_info", "account"=>"GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO"}
    #return: {"master_weight"=>1, "low"=>0, "medium"=>0, "high"=>0}    

    get_tx_history = {"action"=>"get_tx_history", "txid"=>"258fbbfb105a99d63665c31ef46cf721446835985103f37de934842fbd68cff6"}
    #return: {"txid"=>"258fbbfb105a99d63665c31ef46cf721446835985103f37de934842fbd68cff6", "ledgerseq"=>4417, "txresult"=>"JY+7+xBamdY2ZcMe9Gz3IURoNZhRA/N96TSEL71oz/YAAAAAAAAAZAAAAAAAAAABAAAAAAAAAAUAAAAAAAAAAA=="}   

    make_witness = {"action"=>"make_witness", "account"=>"GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO"}
    #return:{"acc_info":{"accountid":"GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO","balance":1219999700,"seqnum":11901354377218,"numsubentries":1,"inflationdest":null,"homedomain":"test.timebonds2","thresholds":"AQAAAA==","flags":0,"lastmodified":7867},"balance":0,"thresholds":{"master_weight":1,"low":0,"medium":0,"high":0},"signer_info":{"signers":[{"accountid":"GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO","publickey":"GBT6G2KZI4ON3LTVRWEPT3GH66TTBTN77SIHRGNQ4KAU7N3GTFLYXYOM","weight":1}]},"timestamp":"1444389446","witness_account":"GCYSIZB4Q6ISTHFDXQMBBUPI4BVY7KW6QKCIZKTXAQBDXQYGRRIUTYSX","signed_json":"{\"acc_info\":{\"accountid\":\"GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO\",\"balance\":1219999700,\"seqnum\":11901354377218,\"numsubentries\":1,\"inflationdest\":null,\"homedomain\":\"test.timebonds2\",\"thresholds\":\"AQAAAA==\",\"flags\":0,\"lastmodified\":7867},\"balance\":0,\"thresholds\":{\"master_weight\":1,\"low\":0,\"medium\":0,\"high\":0},\"signer_info\":{\"signers\":[{\"accountid\":\"GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO\",\"publickey\":\"GBT6G2KZI4ON3LTVRWEPT3GH66TTBTN77SIHRGNQ4KAU7N3GTFLYXYOM\",\"weight\":1}]},\"timestamp\":\"1444389446\",\"witness_account\":\"GCYSIZB4Q6ISTHFDXQMBBUPI4BVY7KW6QKCIZKTXAQBDXQYGRRIUTYSX\"}","signature":"URuAwVWLE621J/jI2GdIKZgS/iiMb3efOuFN6m/IGD39pzhpJ+THzC2yW4K0\nA1OTwaU9vsRB7ooT+zXf/a02CQ==\n"}
#JSON.parse hash: {"acc_info"=>{"accountid"=>"GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO", "balance"=>1219999700, "seqnum"=>11901354377218, "numsubentries"=>1, "inflationdest"=>nil, "homedomain"=>"test.timebonds2", "thresholds"=>"AQAAAA==", "flags"=>0, "lastmodified"=>7867}, "balance"=>0, "thresholds"=>{"master_weight"=>1, "low"=>0, "medium"=>0, "high"=>0}, "signer_info"=>{"signers"=>[{"accountid"=>"GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO", "publickey"=>"GBT6G2KZI4ON3LTVRWEPT3GH66TTBTN77SIHRGNQ4KAU7N3GTFLYXYOM", "weight"=>1}]}, "timestamp"=>"1444389446", "witness_account"=>"GCYSIZB4Q6ISTHFDXQMBBUPI4BVY7KW6QKCIZKTXAQBDXQYGRRIUTYSX", "signed_json"=>"{\"acc_info\":{\"accountid\":\"GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO\",\"balance\":1219999700,\"seqnum\":11901354377218,\"numsubentries\":1,\"inflationdest\":null,\"homedomain\":\"test.timebonds2\",\"thresholds\":\"AQAAAA==\",\"flags\":0,\"lastmodified\":7867},\"balance\":0,\"thresholds\":{\"master_weight\":1,\"low\":0,\"medium\":0,\"high\":0},\"signer_info\":{\"signers\":[{\"accountid\":\"GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO\",\"publickey\":\"GBT6G2KZI4ON3LTVRWEPT3GH66TTBTN77SIHRGNQ4KAU7N3GTFLYXYOM\",\"weight\":1}]},\"timestamp\":\"1444389446\",\"witness_account\":\"GCYSIZB4Q6ISTHFDXQMBBUPI4BVY7KW6QKCIZKTXAQBDXQYGRRIUTYSX\"}", "signature"=>"URuAwVWLE621J/jI2GdIKZgS/iiMb3efOuFN6m/IGD39pzhpJ+THzC2yW4K0\nA1OTwaU9vsRB7ooT+zXf/a02CQ==\n"}

    make_unlock_transaction = {"action"=>"make_unlock_transaction", "account"=>"GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO"}

    return_status_tx = {"status"=>"sent","tx_num"=>"123","sign_count"=>"2","signed"=>["GDZ4AF...","GDOJM..."]}
    #status pending means that the transaction hasn't got all the needed signers yet, sent means we got the signers and it was transacted
    return_status_tx_not_sent = {"status"=>"pending","tx_num"=>"123","sign_count"=>"1","signed"=>["GDZ4AF..."]}
    #dataout = {"signed"=>[xyz,zyx]}
    #data = get_tx
    #data = get_account_info
    data = make_unlock_transaction

    url = "ws://localhost:9494"
    if data.class != String         
      puts "sending: #{data.to_json}"
      puts "will recieve: #{JSON.parse(data.to_json)}"
      puts "length:  #{data.to_json.length}"
      s = data.to_json
      puts "hex: #{s.unpack('U'*s.length).collect {|x| x.to_s 16}.join}"
      data = ActiveSupport::JSON.encode(data)
    else
      puts "data:   #{data}"
    end
   
    
EM.run do
  conn = EventMachine::WebSocketClient.connect(url)
  puts "url: #{url}"
  conn.callback do
    conn.send_msg data
    #conn.send_msg "done"
  end

  conn.errback do |e|
    puts "Got error: #{e}"
    EM::stop_event_loop
  end

  conn.stream do |msg|
    puts "rec raw #{msg}"
    puts "JSON.parse hash: #{JSON.parse(msg.to_s)}"
    if msg.data == "done"
      conn.close_connection
    end
  end

  conn.disconnect do
    puts "disconnected or can't make connection , stoping event loop"
    EM::stop_event_loop
  end
end

