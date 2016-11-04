require '../lib/stellar_utility/stellar_utility.rb'
#require "mysql"
#require 'pg'
#bundler exec ruby ./pg_horizon_add.rb
#PGconn.new(host, port, options, tty, dbname, login, password) ->  PGconn
# worked ok

#pg_hostaddr: 127.0.0.1
#pg_port: 5432
#pg_dbname: horizon
#pg_user: sacarlson
#pg_password: 'password'
Utils = Stellar_utility::Utils.new("./livenet_read_ticker.cfg")

#puts "tx_env decoded: #{Utils.decode_txbody_b64(row["tx_envelope"])}"
#Utils.configs["pg_password"]
def open_pg()
  return PGconn.connect("localhost", 5432, '', '', "horizon", Utils.configs["pg_user"], Utils.configs["pg_password"])
end

#{"action":"get_ticker","status":"success","data":[{"id"
def get_order_hist(limit)
 #data = {"price"=>"435.2295525", "amount"=>"10.1326000", "price_r"=>{"d"=>2548380, "n"=>1109130287}, "offer_id"=>0, "buying_asset_type"=>"native", "selling_asset_code"=>"USD", "selling_asset_type"=>"credit_alphanum4", "selling_asset_issuer"=>"GBUYUAI75XXWDZEKLY66CFYKQPET5JR4EENXZBUZ3YXZ7DS56Z4OKOFU", "datetime"=>"2016-10-23 03:04:15.357016", "account"=>"GBURK32BMC7XORYES62HDKY7VTA5MO7JYBDH7KTML4EPN4BV2MIRQOVR"}

  conn = open_pg()
  #res  = conn.exec('SELECT * FROM history_operations ORDER BY id DESC;')
  res  = conn.exec('SELECT * FROM history_operations WHERE type = 3 ORDER BY transaction_id DESC LIMIT ' + limit.to_s + ";")
  data = []
  res.each do |row|
    #puts "row: #{row}"
    r = JSON.parse(row["details"])
    puts "details: #{r}"
    puts "tx_id: #{row["transaction_id"]}"
    tx_info = tx_id_info(row["transaction_id"])
    puts "tx_info: #{tx_info}"
    r["datetime"] = tx_info["updated_at"]
    r["account"] = tx_info["account"]
    puts "r: #{r}"
    puts ""   
    data.push(r)
  end
  conn.close if conn

  hash = {}
  hash["data"] = data
  hash["action"] = "get_ticker"
  hash["status"] = "success"
  return hash

end

# {"action":"get_ticker_list","status":"success","asset_pairs":{"THB_USD":
# ["THB","GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF","USD","GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF","34.80315"],"USD_THB"


#tx_info (plus more)
#, "memo_type"=>"none", "memo"=>nil, "time_bounds"=>nil}
#tx_info: {"transaction_hash"=>"fef0ce3146fc4513e86b6579de336797907ac913197dbe38b8c7c41332287381", "ledger_sequence"=>"7006185", "application_order"=>"1", #"account"=>"GBURK32BMC7XORYES62HDKY7VTA5MO7JYBDH7KTML4EPN4BV2MIRQOVR", "account_sequence"=>"25631492944166927", "fee_paid"=>"200", "operation_count"=>"2", #"created_at"=>"2016-10-20 06:01:41.506581", "updated_at"=>"2016-10-20 06:01:41.506581", "id"=>"30091335444729856",

# r: {"price"=>"0.0251250", "amount"=>"402.0000000", "price_r"=>{"d"=>8000, "n"=>201}, "offer_id"=>0, "buying_asset_code"=>"FUNT", "buying_asset_type"=>"credit_alphanum4", "selling_asset_code"=>"THB", "selling_asset_type"=>"credit_alphanum4", "buying_asset_issuer"=>"GBUYUAI75XXWDZEKLY66CFYKQPET5JR4EENXZBUZ3YXZ7DS56Z4OKOFU", "selling_asset_issuer"=>"GBUYUAI75XXWDZEKLY66CFYKQPET5JR4EENXZBUZ3YXZ7DS56Z4OKOFU"}

def fill_history_offers(limit=3000)
  #buying_asset_code = base_code, selling_asset_code = asset_code  asset_code_base_code = THB_USD
  last_id = last_update_id() 
  conn = open_pg()
  if last_id.to_i > 0
    puts "last_id > 0"
    res  = conn.exec('SELECT * FROM history_operations WHERE type = 3 AND transaction_id > ' + last_id.to_s + ' ORDER BY transaction_id DESC LIMIT ' + limit.to_s + ";")
  else
    res  = conn.exec('SELECT * FROM history_operations WHERE type = 3 ORDER BY transaction_id DESC LIMIT ' + limit.to_s + ";")
  end
  asset_pairs = {}
  res.each do |row|
    #puts "row: #{row}"
    r = JSON.parse(row["details"])
    #puts "details: #{r}"
    tx_info = tx_id_info(row["transaction_id"])
    #puts "tx_info: #{tx_info}"
    #puts "tx_info[tx_result]:  #{tx_info["tx_result"]}"
    #tx_result =  Utils.decode_txresult_b64(tx_info["tx_result"])
    #puts "tx_result: #{tx_result.inspect}"
    #puts ""
    #puts "pre inspect: #{tx_result}"
    #puts ""
    if r["buying_asset_type"] == "native"
      r["buying_asset_code"] = "XLM"
    end
    if r["selling_asset_type"] == "native"
      r["selling_asset_code"] = "XLM"
    end
    asset_pair = r["selling_asset_code"] + "_" + r["buying_asset_code"]
    r.delete("price_r")
    r.delete("offer_id")
    r["account"] = tx_info["account"]
    r["created_at"] = tx_info["created_at"]
    r["updated_at"] = tx_info["updated_at"]
    r["ledger_sequence"] = tx_info["ledger_sequence"]
    r["tx_result"] = tx_info["tx_result"]
    r["transaction_id"] = row["transaction_id"]
    r["operation_id"] = row["id"]
    r["asset_pair"] = asset_pair
    dec_res = decode_tx_result(r["tx_result"])
    op_offset = (r["operation_id"]).to_i - (r["transaction_id"]).to_i - 1
    puts "op_offset: #{op_offset}"
    r["offer_id"] = dec_res[op_offset]["offer_id"]
    r["sold_amount"] = dec_res[op_offset]["amount_sold"]
    r["bought_amount"] = dec_res[op_offset]["amount_bought"]
    #puts "r: #{r}"
    write_pg_history_offers(r)
  end
  conn.close if conn
  
end

def fill_history_sold(limit=3000)
  #row: {"history_account_id"=>"66", "history_operation_id"=>"30366849006833665", "order"=>"2", "type"=>"33", "details"=>"{\"seller\": \"GANDNZWKK6DA3224M4QG5I3GN444H6CWHENIKPETLJ2XJJ6KEK2WQH53\", \"offer_id\": 810, \"sold_amount\": \"43.6012923\", \"bought_amount\": \"0.1000000\", \"sold_asset_type\": \"native\", \"bought_asset_code\": \"FUNT\", \"bought_asset_type\": \"credit_alphanum4\", \"bought_asset_issuer\": \"GBUYUAI75XXWDZEKLY66CFYKQPET5JR4EENXZBUZ3YXZ7DS56Z4OKOFU\"}"}

#details: {"seller"=>"GANDNZWKK6DA3224M4QG5I3GN444H6CWHENIKPETLJ2XJJ6KEK2WQH53", "offer_id"=>810, "sold_amount"=>"43.6012923", "bought_amount"=>"0.1000000", "sold_asset_type"=>"native", "bought_asset_code"=>"FUNT", "bought_asset_type"=>"credit_alphanum4", "bought_asset_issuer"=>"GBUYUAI75XXWDZEKLY66CFYKQPET5JR4EENXZBUZ3YXZ7DS56Z4OKOFU"}

#op_info: {"id"=>"30366849006833665", "transaction_id"=>"30366849006833664", "application_order"=>"1", "type"=>"3", "details"=>"{\"price\": \"0.0020803\", \"amount\": \"0.1000000\", \"price_r\": {\"d\": 10000000, \"n\": 20803}, \"offer_id\": 0, \"buying_asset_type\": \"native\", \"selling_asset_code\": \"FUNT\", \"selling_asset_type\": \"credit_alphanum4\", \"selling_asset_issuer\": \"GBUYUAI75XXWDZEKLY66CFYKQPET5JR4EENXZBUZ3YXZ7DS56Z4OKOFU\"}", "source_account"=>"GANDNZWKK6DA3224M4QG5I3GN444H6CWHENIKPETLJ2XJJ6KEK2WQH53"}

#tx_info: {"transaction_hash"=>"f32a7c2fd1f0e504cab434989d0d24a87d27f0e11238df242cf1793631fab279", "ledger_sequence"=>"7070333", "application_order"=>"1", "account"=>"GANDNZWKK6DA3224M4QG5I3GN444H6CWHENIKPETLJ2XJJ6KEK2WQH53", "account_sequence"=>"25759169436975108", "fee_paid"=>"100", "operation_count"=>"1", "created_at"=>"2016-10-22 03:12:58.355849", "updated_at"=>"2016-10-22 03:12:58.355849", "id"=>"30366849006833664", "tx_envelope"=>"AAAAABo25spXhg3rXGcgbqNmbznD+FY5GoU8k1p1dKfKIrVoAAAAZABbg9QAAAAEAAAAAAAAAAEAAAAAAAAAAQAAAAAAAAADAAAAAUZVTlQAAAAAaYoBH+3vYeSKXj3hFwqDyT6mPCEbfIaZ3i+fjl32eOUAAAAAAAAAAAAPQkAAAFFDAJiWgAAAAAAAAAAAAAAAAAAAAAHKIrVoAAAAQB9UfDJnIK3UeSjRhNF+baC9SDoWHB8pnCCzcAZfXfFIwhi4GGBMSSbZYe2aZyQf+3LqAN15xgsYYOShHNA+KAY=", "tx_result"=>"AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAADAAAAAAAAAAEAAAAAaRVvQWC/d0cEl7Rxqx+swdY76cBGf6psXwj28DXTERgAAAAAAAADKgAAAAAAAAAAGf0HewAAAAFGVU5UAAAAAGmKAR/t72Hkil494RcKg8k+pjwhG3yGmd4vn45d9njlAAAAAAAPQkAAAAACAAAAAA==", "tx_meta"=>"AAAAAAAAAAEAAAAJAAAAAQBr4n0AAAAAAAAAABo25spXhg3rXGcgbqNmbznD+FY5GoU8k1p1dKfKIrVoAAAAAD5Y4msAW4PUAAAABAAAAAEAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAwBr4CMAAAAAAAAAAGkVb0Fgv3dHBJe0casfrMHWO+nARn+qbF8I9vA10xEYAAAAF1kIaDgAWw+1AAABSgAAAAsAAAAAAAAAAAAAAA9mdW50cmFja2VyLnNpdGUAAQAAAAAAAAAAAAAAAAAAAAAAAAEAa+J9AAAAAAAAAABpFW9BYL93RwSXtHGrH6zB1jvpwEZ/qmxfCPbwNdMRGAAAABc/C2C9AFsPtQAAAUoAAAALAAAAAAAAAAAAAAAPZnVudHJhY2tlci5zaXRlAAEAAAAAAAAAAAAAAAAAAAAAAAADAFwNhgAAAAEAAAAAGjbmyleGDetcZyBuo2ZvOcP4VjkahTyTWnV0p8oitWgAAAABRlVOVAAAAABpigEf7e9h5IpePeEXCoPJPqY8IRt8hpneL5+OXfZ45QAAAAABycOAf/////////8AAAABAAAAAAAAAAAAAAABAGvifQAAAAEAAAAAGjbmyleGDetcZyBuo2ZvOcP4VjkahTyTWnV0p8oitWgAAAABRlVOVAAAAABpigEf7e9h5IpePeEXCoPJPqY8IRt8hpneL5+OXfZ45QAAAAABuoFAf/////////8AAAABAAAAAAAAAAAAAAADAGrh7AAAAAEAAAAAaRVvQWC/d0cEl7Rxqx+swdY76cBGf6psXwj28DXTERgAAAABRlVOVAAAAABpigEf7e9h5IpePeEXCoPJPqY8IRt8hpneL5+OXfZ45QAAAAAO9fTAf/////////8AAAABAAAAAAAAAAAAAAABAGvifQAAAAEAAAAAaRVvQWC/d0cEl7Rxqx+swdY76cBGf6psXwj28DXTERgAAAABRlVOVAAAAABpigEf7e9h5IpePeEXCoPJPqY8IRt8hpneL5+OXfZ45QAAAAAPBTcAf/////////8AAAABAAAAAAAAAAAAAAADAGvgHAAAAAIAAAAAaRVvQWC/d0cEl7Rxqx+swdY76cBGf6psXwj28DXTERgAAAAAAAADKgAAAAAAAAABRlVOVAAAAABpigEf7e9h5IpePeEXCoPJPqY8IRt8hpneL5+OXfZ45QAAAAsxN5CJADEHZlOBO+0AAAAAAAAAAAAAAAAAAAABAGvifQAAAAIAAAAAaRVvQWC/d0cEl7Rxqx+swdY76cBGf6psXwj28DXTERgAAAAAAAADKgAAAAAAAAABRlVOVAAAAABpigEf7e9h5IpePeEXCoPJPqY8IRt8hpneL5+OXfZ45QAAAAsXOokOADEHZlOBO+0AAAAAAAAAAAAAAAA=", "tx_fee_meta"=>"AAAAAgAAAAMAY53DAAAAAAAAAAAaNubKV4YN61xnIG6jZm85w/hWORqFPJNadXSnyiK1aAAAAAAkW9tUAFuD1AAAAAMAAAABAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAEAa+J9AAAAAAAAAAAaNubKV4YN61xnIG6jZm85w/hWORqFPJNadXSnyiK1aAAAAAAkW9rwAFuD1AAAAAQAAAABAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAA==", "signatures"=>"{H1R8MmcgrdR5KNGE0X5toL1IOhYcHymcILNwBl9d8UjCGLgYYExJJtlh7ZpnJB/7cuoA3XnGCxhg5KEc0D4oBg==}", "memo_type"=>"text", "memo"=>"", "time_bounds"=>nil}


  #last_id = last_update_id()
  last_id = last_sold_op_id()
  puts "last_id: #{last_id}"
  conn = open_pg()
  if last_id.to_i > 0
    puts "last_id > 0"
    res  = conn.exec('SELECT * FROM history_effects WHERE type = 33 AND history_operation_id > ' + last_id.to_s + ' ORDER BY history_operation_id DESC LIMIT ' + limit.to_s + ";")
  else
    res  = conn.exec('SELECT * FROM history_effects WHERE type = 33 ORDER BY history_operation_id DESC LIMIT ' + limit.to_s + ";")
  end
  asset_pairs = {}
  res.each do |row|
    puts "row: #{row}"
    if last_id.to_i >= row["history_operation_id"].to_i
      puts "last_id >= history_operation_id, will return now"
      return
    end
    r = JSON.parse(row["details"])
    puts "details: #{r}"
    #tx_info = tx_id_info(row["history_operation_id"])
    op_info = op_id_info(row["history_operation_id"])
    puts "op_info: #{op_info}"
    tx_info = tx_id_info(op_info["transaction_id"])
    puts "tx_info: #{tx_info}"
    #puts "tx_info[tx_result]:  #{tx_info["tx_result"]}"
    #tx_result =  Utils.decode_txresult_b64(tx_info["tx_result"])
    #puts "tx_result: #{tx_result.inspect}"
    #puts ""
    #puts "pre inspect: #{tx_result}"
    #puts ""
    if r["bought_asset_type"] == "native"
      r["bought_asset_code"] = "XLM"
    end
    puts "sold_asset_type: #{r["sold_asset_type"]}"
    if r["sold_asset_type"] == "native"
      r["sold_asset_code"] = "XLM"
    end
    asset_pair = r["sold_asset_code"] + "_" + r["bought_asset_code"]
    #r["buyer"] = tx_info["account"]
    r["price"] = r["sold_amount"].to_f / r["bought_amount"].to_f
    r["created_at"] = tx_info["created_at"]
    r["updated_at"] = tx_info["updated_at"]
    r["transaction_id"] = op_info["transaction_id"]
    r["ledger_sequence"] = tx_info["ledger_sequence"]
    r["tx_result"] = tx_info["tx_result"]
    r["operation_id"] = row["history_operation_id"]
    r["asset_pair"] = asset_pair
    #puts "r: #{r}"
    #write_pg_history_offers(r)
    write_pg("history_sold", r)
  end
  conn.close if conn  
end

def last_sold_info(asset_pair = nil)
  begin
    conn = open_pg()
    if asset_pair.nil?
      res  = conn.exec('SELECT * FROM history_sold  ORDER BY operation_id DESC LIMIT 1;')
    else
      res  = conn.exec("SELECT * FROM history_sold WHERE asset_pair = '" + asset_pair + "' ORDER BY operation_id DESC LIMIT 1;")
    end
  rescue
    conn.close if conn
    puts "asset_pair not found, return 0"
    return 0
  end
  conn.close if conn
  if asset_pair.nil?
    return res[0]["operation_id"]
  else
    return res[0]
  end
end

def last_sold_op_id()
   return last_sold_info() 
end


def last_update_id()
  begin
    conn = open_pg()
    res  = conn.exec('SELECT * FROM history_offers  ORDER BY transaction_id DESC LIMIT 1;')
    puts "res: #{res[0]["transaction_id"]}"
  rescue
    puts "no history yet or error so return 0"
    conn.close if conn
    return 0
  end
  conn.close if conn
  return res[0]["transaction_id"]
end

def decode_txresult(b64)
  # decode to the raw byte stream
  bytes = Stellar::Convert.from_base64 b64

  # decode to the in-memory TransactionResult
  tr = Stellar::TransactionResult.from_xdr bytes
  
  # the actual tx success code is embedded in the "result" field of the 
  # TransactionResult.
  puts "#{tr.result.code}"

  puts ""
  puts "tr_full: #{tr.result.to_yaml}"
end


def get_ticker_list(ask_asset_pair = nil,limit=3500)
  #buying_asset_code = base_code, selling_asset_code = asset_code  asset_code_base_code = THB_USD 
  conn = open_pg()
  #res  = conn.exec('SELECT * FROM history_operations ORDER BY id DESC;')
  #res  = conn.exec('SELECT * FROM history_operations WHERE type = 3 ORDER BY transaction_id DESC LIMIT ' + limit.to_s + ";")
  res  = conn.exec('SELECT * FROM history_operations WHERE type = 3 ORDER BY transaction_id ASC LIMIT ' + limit.to_s + ";")
  asset_pairs = {}
  res.each do |row|
    #puts "row: #{row}"
    a = []
    r = JSON.parse(row["details"])
    #puts "details: #{r}"
    tx_info = tx_id_info(row["transaction_id"])
    #puts "tx_info: #{tx_info}"
    if r["buying_asset_type"] == "native"
      r["buying_asset_code"] = "XLM"
    end
    if r["selling_asset_type"] == "native"
      r["selling_asset_code"] = "XLM"
    end
    asset_pair = r["selling_asset_code"] + "_" + r["buying_asset_code"]
    
    a[0] = r["selling_asset_code"]
    a[1] = r["selling_asset_issuer"]
    a[2] = r["buying_asset_code"]
    a[3] = r["buying_asset_issuer"]
    a[4] = r["price"]  
    a[5] = row["transaction_id"]
    a[6] = tx_info["updated_at"]
    a[7] = tx_info["account"]
    asset_pairs[asset_pair] = a
    #puts "asset_pair: #{asset_pair}"
    #puts "count: #{count = count+1}"
    #sleep 0.1
  end
  conn.close if conn
  hash = {}
  if ask_asset_pair.nil?
    hash["asset_pairs"] = asset_pairs    
  else
    hash["asset_pairs"] = asset_pairs[ask_asset_pair]
    hash["asset_pair"] = ask_asset_pair
  end
  hash["action"] = "get_ticker_list"
  hash["status"] = "success"
  return hash
end

def tx_id_to_datetime(tx_id)
  conn = open_pg()
  query = 'SELECT * FROM history_transactions WHERE id = ' + tx_id.to_s + ' LIMIT 1;'
  res  = conn.exec(query)
  if res.cmd_tuples == 0
    puts "tx_id not found"
    return 0
  else
    #puts "res: #{res[0]["updated_at"]}"
    return res[0]["updated_at"]
  end  
  conn.close if conn
end

def tx_id_info(tx_id)
  conn = open_pg()
  query = 'SELECT * FROM history_transactions WHERE id = ' + tx_id.to_s + ' LIMIT 1;'
  res  = conn.exec(query)
  if res.cmd_tuples == 0
    puts "tx_id not found"
    hash = nil
  else
    #puts "res: #{res[0]["updated_at"]}"
    hash = res[0]
  end  
  conn.close if conn
  return hash
end

def op_id_info(tx_id)
  conn = open_pg()
  query = 'SELECT * FROM history_operations WHERE id = ' + tx_id.to_s + ' LIMIT 1;'
  res  = conn.exec(query)
  if res.cmd_tuples == 0
    puts "tx_id not found"
    hash = nil
  else
    #puts "res: #{res[0]["updated_at"]}"
    hash = res[0]
  end  
  conn.close if conn
  return hash
end

def write_pg2()
  conn = open_pg() 
  conn.exec "INSERT INTO ticker (ask_price, bid_price) VALUES(1.1,2.2)"
  #con.exec "INSERT INTO films SELECT * FROM tmp_films WHERE date_prod < '2004-05-07';"
  #con.exec "INSERT INTO films (code, title, did, date_prod, kind) VALUES ('T_601', 'Yojimbo', 106, '1961-06-16', 'Drama');"
  conn.close if conn
end

def write_pg_history_offers(hash)
  hash.each do |key, value|
    if value.nil?
      hash[key] = "0"
    end
  end
  #puts "hash: #{hash}"
  keys = hash.keys.join(",")
  #puts "hash_values: #{hash.values}"
  values = hash.values.join(",")
  #puts "values: #{values}"
  
  query = 'INSERT INTO history_offers (' + hash.keys.join(',') + ") VALUES( '" + hash.values.join("','") + "');"
  #puts "query: #{query}"
  conn = open_pg() 
  conn.exec(query)
  conn.close if conn
end

def write_pg(table, hash)
  hash.each do |key, value|
    if value.nil?
      hash[key] = "0"
    end
  end
  #puts "hash: #{hash}"
  keys = hash.keys.join(",")
  #puts "hash_values: #{hash.values}"
  values = hash.values.join(",")
  #puts "values: #{values}"
  
  query = 'INSERT INTO ' + table + " (" + hash.keys.join(',') + ") VALUES( '" + hash.values.join("','") + "');"
  #puts "query: #{query}"
  conn = open_pg() 
  conn.exec(query)
  conn.close if conn
end

def find_within(input, marker_start, marker_leader,marker_end="\n")
  #out = input[/#{marker_start}(.*?)#{marker_lead}/m, 1]
  out = input.split(marker_start)[-1]
  out2 = out[/#{marker_leader}(.*?)#{marker_end}/m, 1]
  puts "out: #{out2}"
  return out
end

def split_line(input,marker_start,marker_end="\n")
  return input[/#{marker_start}(.*?)#{marker_end}/m, 1]
end

def split_operations(tr) 
 # we had to use this method until we figure out the right way to parse tr_result data
 # some day we should have all the data available to use when done correctly
 # output is an array of hashs that contain broken out tr_results of each transaction (only parts at this point)
 yml = tr.result.to_yaml
 hash = []
 marker = "- !ruby/object:Stellar::OperationResult"
 array = yml.split(marker)
 #puts "array1: #{array[1]}"
 first = true
 position = 0
 array.each do |op|
   if first
     #skip first element in array that is not an operation
     first = false
   else
     hash[position] = {}    
     #offers_claimed = split_line(op,":offers_claimed: ")
     hash[position]["offer_id"] = split_line(op,":offer_id: ")
     hash[position]["amount_sold"] = (split_line(op,":amount_sold: ")).to_f/10000000.0
     hash[position]["amount_bought"] = (split_line(op,":amount_bought: ")).to_f/10000000.0
     hash[position]["amount"] = (split_line(op,":amount: ")).to_f/10000000.0
     #hash["price_n"] = find_within(op, ":price: !ruby/object:Stellar::Price", ":n: ")
     #hash["price_d"] = find_within(op, ":price: !ruby/object:Stellar::Price", ":d: ")
     position = position + 1
   end
 end
 puts "op results: #{hash}"
 return hash
end

def decode_tx_result(b64)
  # decode to the raw byte stream
  bytes = Stellar::Convert.from_base64 b64
  # decode to the in-memory TransactionResult
  tr = Stellar::TransactionResult.from_xdr bytes
  #input = tr.result.to_yaml
  return split_operations(tr)
end



def create_table_history_offers()
  conn = open_pg()
  conn.exec 'CREATE TABLE IF NOT EXISTS history_offers(
  idx SERIAL,
  timestamp				timestamp	NOT NULL DEFAULT now(),
  asset_pair			TEXT	DEFAULT NULL,
  price					TEXT	DEFAULT NULL,
  amount				TEXT	DEFAULT NULL,
  sold_amount			TEXT	DEFAULT NULL,
  bought_amount			TEXT	DEFAULT NULL,  
  account				TEXT	DEFAULT NULL,
  buyer					TEXT	DEFAULT NULL,
  ledger_sequence		TEXT	DEFAULT NULL,
  offer_id				TEXT	DEFAULT NULL,
  transaction_id		TEXT	DEFAULT NULL,
  operation_id			TEXT	DEFAULT NULL,
  tx_result				TEXT	DEFAULT NULL,  
  selling_asset_code	TEXT	DEFAULT NULL,
  selling_asset_type	TEXT	DEFAULT NULL,
  selling_asset_issuer	TEXT	DEFAULT NULL,    
  buying_asset_code		TEXT	DEFAULT NULL,
  buying_asset_type		TEXT	DEFAULT NULL,
  buying_asset_issuer	TEXT	DEFAULT NULL,
  updated_at			TEXT	DEFAULT NULL,
  created_at			TEXT	DEFAULT NULL
  );'
end

def create_table_history_sold()
  conn = open_pg()
  conn.exec 'CREATE TABLE IF NOT EXISTS history_sold(
  idx SERIAL,
  timestamp				timestamp	NOT NULL DEFAULT now(),
  asset_pair			TEXT	DEFAULT NULL,
  price					TEXT	DEFAULT NULL,
  sold_amount			TEXT	DEFAULT NULL,
  bought_amount			TEXT	DEFAULT NULL,  
  seller				TEXT	DEFAULT NULL,
  buyer					TEXT	DEFAULT NULL,
  ledger_sequence		TEXT	DEFAULT NULL,
  offer_id				TEXT	DEFAULT NULL,
  transaction_id		TEXT	DEFAULT NULL,
  operation_id			TEXT	DEFAULT NULL,
  tx_result				TEXT	DEFAULT NULL,  
  sold_asset_code		TEXT	DEFAULT NULL,
  sold_asset_type		TEXT	DEFAULT NULL,
  sold_asset_issuer		TEXT	DEFAULT NULL,    
  bought_asset_code		TEXT	DEFAULT NULL,
  bought_asset_type		TEXT	DEFAULT NULL,
  bought_asset_issuer	TEXT	DEFAULT NULL,
  updated_at			TEXT	DEFAULT NULL,
  created_at			TEXT	DEFAULT NULL
  );'
end

def create_table()
  conn = open_pg()
  conn.exec 'CREATE TABLE ticker(
   id SERIAL ,
   updated_at	TEXT	DEFAULT NULL,
   created_at	TEXT	DEFAULT NULL,
   timestamp      timestamp     NOT NULL DEFAULT now(),
   price      real DEFAULT 0.0,
   ask_volume     real DEFAULT 0.0,
   bid_price      real DEFAULT 0.0,
   bid_volume	  real DEFAULT 0.0,
   base_asset_code  TEXT DEFAULT NULL,
   base_asset_type  TEXT DEFAULT NULL,
   base_asset_issuer TEXT DEFAULT NULL,
   counter_asset_code TEXT DEFAULT NULL,
   counter_asset_type TEXT DEFAULT NULL,
   counter_asset_issuer TEXT DEFAULT NULL,
   account				TEXT DEFAULT NULL  
  );'

   conn.close if conn
end

#create_table()
#write_pg()
#write_pg_history_offers({"test"=>"this","one"=>"two"})
#read_pg()
#tx_id_to_datetime(29972111447560192)
#res = get_order_hist(1)
#res = get_ticker_list("FUNT_XLM")
#puts "res: #{res}"
#last_update_id()
create_table_history_offers()

fill_history_offers()

#create_table_history_sold()
#fill_history_sold()
#puts "lsi: #{last_sold_info("XLM_FUNT")}"
#puts "lsi2: #{last_sold_info()}"
