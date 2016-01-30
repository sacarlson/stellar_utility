#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
# this is a helper utility lib used to help make interfaceing ruby with ruby-stellar-base easier
# this package also comes with examples of how this can be used to setup transactions on the Stellar.org network or open-core
# this setup no longer requires haveing a local stellar-core running on your system if configured to horizon mode and pointed at a horizon url entity
# you can also modify @configs["db_file_path"] or edit stellar_utilities.cfg file to point to the location you now have the stellar-core sqlite db file
# there is also support to get results from https://horizon-testnet.stellar.org and you can now also
# send base64 transactions to horizon to get results
# some functions are duplicated just to be plug and play compatible with the old stellar network class_payment.rb lib that's used in pokerth_accounting.
# also see docs directory that contains text information on how to setup dependancies and other useful info to know if using stellar.org on Linux Mint or Ubuntu.
# much of the functions seen here were simply copy pasted from what was found and seen useful in stellar_core_commander

require 'stellar-base'
require 'faraday'
require 'faraday_middleware'
require 'json'
require 'rest-client'
require 'sqlite3'
require 'pg'
require 'yaml'

module Stellar_utility

class Utils
  
attr_accessor :configs

def initialize(load="default")

  if load == "default"
    #load default config file    
    @configs = YAML.load(File.open("./stellar_utilities.cfg"))
    if @configs["default_network"] == "auto"
      get_set_stellar_core_network()
    else
      Stellar.default_network = eval(@configs["default_network"])
    end
    
  elsif load == "db2"
    #localcore mode
    @configs = {"db_file_path"=>"/home/sacarlson/github/stellar/stellar_utility/stellar-db2/stellar.db", "url_horizon"=>"https://horizon-testnet.stellar.org", "url_stellar_core"=>"http://localhost:8080", "url_mss_server"=>"localhost:9494", "mode"=>"localcore", "fee"=>100, "start_balance"=>100, "default_network"=>"Stellar::Networks::TESTNET", "master_keypair"=>"Stellar::KeyPair.master"}
    if @configs["default_network"] == "auto"
      get_set_stellar_core_network()
    else
      Stellar.default_network = eval(@configs["default_network"])
    end
  elsif load == "horizon"
    #horizon mode, if nothing entered for load this is default
    @configs = {"db_file_path"=>"/home/sacarlson/github/stellar/stellar_utility/stellar-db2/stellar.db", "url_horizon"=>"https://horizon-testnet.stellar.org", "url_stellar_core"=>"http://localhost:8080", "url_mss_server"=>"localhost:9494", "mode"=>"horizon", "fee"=>100, "start_balance"=>100, "default_network"=>"Stellar::Networks::TESTNET", "master_keypair"=>"Stellar::KeyPair.master"}
    Stellar.default_network = eval(@configs["default_network"])
  elsif load == "mss"
    @configs = { "url_mss_server"=>"localhost", "mss_port"=>"9494","mode"=>"mss", "fee"=>100, "start_balance"=>100, "default_network"=>"Stellar::Networks::TESTNET", "master_keypair"=>"Stellar::KeyPair.master"}
  else
    #load custom config file
    @configs = YAML.load(File.open(load)) 
    if @configs["default_network"] == "auto"
      get_set_stellar_core_network()
    else
      Stellar.default_network = eval(@configs["default_network"])
    end
  end
end #end initalize

def version
  get_set_stellar_core_network()
  hash = {}
  puts "mode: #{@configs["mode"]}"
  #hash["stellar_base_version"] =  CGI.escape(Stellar::Base::VERSION)
  hash["sqlite_version"] =  CGI.escape(SQLite3::VERSION)
  hash["ruby_version"] =  CGI.escape("#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}")
  hash["default_network"] =  CGI.escape(Stellar.current_network)
  begin
    stellar_core_status = get_stellar_core_status(detail=true)
    #hash["stellar_core_version"] =  CGI.escape(stellar_core_status["info"]["build"].to_json)
  rescue
    hash["stellar_core_version"] = "error"
  end 
  #puts hash.to_json
  return hash.to_json
end

def get_db(query,full=0)
  #returns query hash from database that is dependent on mode
  if @configs["mode"] == "localcore"
    
    if @configs["default_network"] == "auto"
      puts "current_network: #{Stellar.current_network}"
      if (Stellar.current_network == "Public Global Stellar Network ; September 2015")
        puts" get_db detects LIVE!"
        puts "db file #{@configs["db_file_path_live"]}"
        db_file_path = @configs["db_file_path_live"]
      else 
        puts " get_db detects testnet"
        puts "db file #{@configs["db_file_path"]}"
        db_file_path = @configs["db_file_path"]
      end
    else
      db_file_path = @configs["db_file_path"]
    end
    puts "db_file_path: #{db_file_path}"
    db = SQLite3::Database.open db_file_path
    db.execute "PRAGMA journal_mode = WAL"
    db.results_as_hash=true
    stm = db.prepare query 
    result= stm.execute
    if full == 1
      return result
    else
      return result.next
    end
  elsif @configs["mode"] == "local_postgres"
    conn=PGconn.connect( :hostaddr=>@configs["pg_hostaddr"], :port=>@configs["pg_port"], :dbname=>@configs["pg_dbname"], :user=>@configs["pg_user"], :password=>@configs["pg_password"])
    result = conn.exec(query)
    conn.close
    #puts "rusult class #{result.class}"
    if result.cmd_tuples == 0
      return nil
    else
      return result[0]
    end
  elsif @configs["mode"] == "horizon"
    puts "no db query for horizon mode error"
    exit -1
  else
    puts "no such mode #{@configs["mode"]} for db query error"
    exit -1
  end
end

def get_accounts_local(account)
    # this is to get all info on table account on Stellar.db from localy running Stellar-core db
    # returns a hash of all account info example result["seqnum"]
    # database used and config info needed is dependant on @config["mode"] setting
    account = convert_keypair_to_address(account)
    #puts "account #{account}"
    query = "SELECT * FROM accounts WHERE accountid='#{account}'"
    result = get_db(query)
    if result.nil?
      result = {}
      result["balance"] = 0
      result["status"] = "account not found"
      result["accountid"] = account
    else
      result["balance"] = (result["balance"].to_f/10000000)
    end
    result["action"] = "get_account_info"
    return result
end

def reverse_federation_lookup(account)
  info = get_accounts_local(account)
  homedomain = info["homedomain"]
  #https://api.stellar.org/federation?q=GD6WU64OEP5C4LRBH6NK3MHYIA2ADN6K6II6EXPNVUR3ERBXT4AN4ACD&type=id
  if !(homedomain.nil?)
    send = homedomain + "/federation?q=" + account + "&type=id"
    puts "sending:  #{send}"
    begin
    postdata = RestClient.get send
    rescue => e
      return  {"status"=>"error", "error"=>e.response}
    end
    data = JSON.parse(postdata)
    return data
  else
    return {"status"=>"error","error"=>"no_homedomain"}
  end
end

def federation_lookup(fed_id) 
  #https://api.stellar.org/federation?q=jed*stellar.org&type=name  
  if !(fed_id.nil?)
    fed_id.gsub!('@', "*")
    url = fed_id.split("*")
    puts "url: #{url}"
    url = url[1]
    puts "url1: #{url}"
    send = url + "/federation?q=" + fed_id + "&type=name"
    puts "sending:  #{send}"
    begin
    postdata = RestClient.get send
    rescue => e
      return  {"status"=>"error", "error"=>e.response}
    end
    data = JSON.parse(postdata)
    return data
  else
    return {"status"=>"error","error"=>"no_fed_id"}
  end
end

def issuer_debt_total(params)
  #input {"issuer":"GXSTT..."}
  if params["issuer"].nil?
    return {"status"=>"fail no issuer in request"}
  end
  issuer = params["issuer"]
  query = "SELECT * FROM trustlines WHERE issuer='#{issuer}'"
  result = get_db(query,1)
  debt = {"status"=>"success","issuer"=>issuer,"debt"=>{}}
  result.each do |row|
    puts "issuer: #{row["issuer"]}  asset: #{row["assetcode"]}  bal: #{row["balance"]}"
    issuer = row["issuer"]
    asset = row["assetcode"]   
    if debt["debt"][asset].nil?
      debt["debt"][asset] = (row["balance"].to_f/10000000).to_f
    else
      debt["debt"][asset] = debt["debt"][asset] + (row["balance"].to_f/10000000).to_f
    end    
  end  
  return debt
end

def get_tx_offer_hist(params) 
  offset = params["offset"]
  if params["sell_asset"].nil?
    params["sell_asset"] = ""
  end
  if params["buy_asset"].nil?
    params["buy_asset"] = ""
  end
  puts "sell_asset: #{params["sell_asset"]}"
  puts "sell_issuer: #{params["sell_issuer"]}"
  puts "buy_asset: #{params["buy_asset"]}"
  puts "buy_issuer: #{params["buy_issuer"]}"
  if offset.nil?
    offset = 0
  end  
  query = "SELECT * FROM txhistory ORDER BY ledgerseq DESC LIMIT 400 OFFSET #{offset}"  
  result = get_db(query,1)
  hash = {"txhistory"=>[]}
  index = offset
  add_to_list = false
  result.each do |row|
    #puts "index: #{index}"
    txbody = envelope_to_hash(row["txbody"]) 
    operation = txbody["operations"][0]["operation"]
    #puts ":operation: #{operation}  class: #{operation.class}"
    if operation == :manage_offer_op
      offer = txbody["operations"][0]
      puts "selling.asset: #{offer["selling.asset"]}  class: #{offer["selling.asset"].class}  lenght: #{offer["selling.asset"].length} "
      puts "offer: #{offer}"
      if params["sell_asset"].nil?
        puts "sell_asset is nil"
      elsif  params["sell_asset"].length > 0 and offer["selling.asset"].include?(params["sell_asset"])
        puts "selling match"
        if offer["selling.issuer"] == params["sell_issuer"] or params["sell_issuer"].nil? or (params["sell_issuer"].length == 0)
          puts "selling issuer match"
          add_to_list = true
        end
      end
      if params["buy_asset"].nil?
        puts "buy_asset is nil"
      elsif params["buy_asset"].length > 0 and offer["buying.asset"].include?(params["buy_asset"])
        if offer["buying.issuer"] == params["buy_issuer"] or params["buy_issuer"].nil? or (params["buy_issuer"].length == 0)
          add_to_list = true
        end
      end
      if params["buy_asset"].length == 0 and params["sell_asset"].length == 0
        add_to_list = true
      end
      if !(params["closed"].nil?) 
        if params["closed"] == "true"
          if offer["offer_id"].to_i > 0
            add_to_list = false
          end
        else
          if offer["offer_id"].to_i == 0
            add_to_list = false
          end
        end
      end
    end
    
    if add_to_list
      txr = txresult_resultcode(row["txresult"])
      txbody["txresults"] = txr.name
      txbody["index"] = index
      txbody["txid"] = row["txid"]
      txbody["ledgerseq"] = row["ledgerseq"]
      txbody.delete("txmeta")
      txbody.delete("txindex")
      hash["txhistory"].push(txbody)
      puts "hash: #{hash}"
      index = index + 1
    end
    if (index - offset) > 30
      return hash
    end
    add_to_list = false
  end
  return hash
end

def get_tx_hist(params)
  if !(params["txid"].nil?) and (params["txid"] != "all")
    puts "txid2: #{params["txid"]}"
    return get_txhistory(params["txid"],params["detail"])
  end
  offset = params["offset"]
  if offset.nil?
    offset = 0
  end  
  query = "SELECT * FROM txhistory ORDER BY ledgerseq DESC LIMIT 400 OFFSET #{offset}"
  
  #txhistory = get_db(query)
  result = get_db(query,1)
  hash = {"txhistory"=>[]}
  index = offset
  add_to_list = false
  result.each do |row|
    puts "index: #{index}"
    txbody = envelope_to_hash(row["txbody"])    
    
    if (params["destination_address"].nil?) and params["source_address"].nil?
      if  (txbody["memo_text"].to_s == params["memo_text"].to_s) and !(params["memo_text"].nil?)
        add_to_list = true
      end
      if  (txbody["memo_id"].to_i == params["memo_id"].to_i) and !(params["memo_id"].nil?)
        add_to_list = true
      end
      if  (txbody["memo_value"].to_s == params["memo"].to_s) and !(params["memo"].nil?)
        add_to_list = true
      end
      if (txbody["memo_type"] == params["memo_type"]) and !(params["memo_type"].nil?)
        add_to_list = true
      end
      if "all" == params["txid"]
        add_to_list = true
      end
    else
      if txbody["operations"][0]["destination_address"] == params["destination_address"] and !(txbody["operations"][0]["destination_address"].nil?)
        if txbody["memo_value"].to_s == params["memo"].to_s or txbody["memo_id"].to_i == params["memo_id"].to_i or (params["memo"].nil? and params["memo_id"].nil?)
          add_to_list = true
        end
      end
      if txbody["source_address"] == params["source_address"] and !(txbody["source_address"].nil?)
        if txbody["memo_value"].to_s == params["memo"].to_s or txbody["memo_id"].to_i == params["memo_id"].to_i or (params["memo"].nil? and params["memo_id"].nil?)
          add_to_list = true
        end
      end
    end
    if add_to_list
      txr = txresult_resultcode(row["txresult"])
      txbody["txresults"] = txr.name
      txbody["index"] = index
      txbody["txid"] = row["txid"]
      txbody["ledgerseq"] = row["ledgerseq"]
      txbody.delete("txmeta")
      txbody.delete("txindex")
      hash["txhistory"].push(txbody)
      puts "hash: #{hash}"
      index = index + 1
    end
    if (index - offset) > 30
      return hash
    end
    add_to_list = false
  end
  return hash
end


def get_txhistory(txid,detail = 0)
  #return line of txhistory table with this txid
  puts "txid: #{txid}  detail.class: #{detail.class}"
  if detail.nil?
    detail = 1
  end
  query = "SELECT * FROM txhistory WHERE txid='#{txid}'"
  txhistory = get_db(query)
  if !txhistory.nil?
    if detail == 1
      txhistory["txbody"] = envelope_to_hash(txhistory["txbody"])
      txhistory["txresult"] = txresult_resultcode(txhistory["txresult"])
    else
      txhistory.delete("txbody")
    end
    txhistory.delete("txmeta")
    txhistory.delete("txindex")
  end
  return txhistory 
end

def get_sorted_holdings(params)  
  #this will return a sorted DESC list of accounts sorted on the balance of the asset issuer holdings
  # if asset = native then issuer will be ignored, offset allows paging down deeper into the list as default is only 
  # 30 max account will be returns
  # params is hash example {"asset"=>"USD","issuer"=>"GEWG...","offset"=>0}
  asset = params["asset"]
  issuer = params["issuer"]
  offset = params["offset"]
  hash = {"accounts"=>[]}  
  if offset.nil?
    offset = 0
  end
  if asset.nil?
    query = "SELECT * FROM trustlines ORDER BY balance DESC LIMIT 30 OFFSET #{offset}"
  elsif asset == "native"
    query = "SELECT * FROM accounts ORDER BY balance DESC LIMIT 30 OFFSET #{offset}"
  elsif !(issuer.nil?)
    query = "SELECT * FROM trustlines WHERE assetcode = '#{asset}' AND issuer = #{issuer} ORDER BY balance DESC LIMIT 30 OFFSET #{offset}"
  else
    query = "SELECT * FROM trustlines WHERE assetcode = '#{asset}' ORDER BY balance DESC LIMIT 30 OFFSET #{offset}"
  end
  #txhistory = get_db(query)
  result = get_db(query,1)  
  index = offset
  result.each do |row|
    puts "index: #{index}"
    row["index"] = index
    if asset == "native"
      row["balance"] = row["balance"].to_f/10000000
    else
      row["balance"] = row["balance"].to_f/10000000
    end
    hash["accounts"].push(row)
    index = index + 1
  end
  hash["action"] = "get_sorted_holdings"
  hash["status"] = "success"
  return hash
end

def get_pool_members(params)  
  # this will return a list of the stellar inflation destination pool members and there account details
  # it will later be modified to return a sorted list from top lumens balance pool members on top of list
  # later we will need to add max account returns that will later default to 30 max
  # standard offset will also later be added to page beyond 30 members
  # param inf_dest = inflation_destination accountID used in the pool
  # total_inflation = what the pool has that they are going to be paying out to all it's members on this round  
  # params is hash example {"inf_dest"=>"GEWG...", "offset"=>0, "total_inflation"=>"18000000"}
  # example output:
  #{"accounts":[{"accountid":"GDRFRGR2FDUFF2RI6PQE5KFSCJHGSEIOGET22R66XSATP3BYHZ46BPLO","balance":2096.91552,"index":0,"to_receive":17768140.824134596,"multiplier":0.9871189346741442},{"accountid":"GDTHJDFZOENIOR5TITSW46KMSDQQN7WUULBJXO5EDOAOVDAAGEEB7LQQ","balance":27.36297,"index":1,"to_receive":231859.17586540172,"multiplier":0.01288106532585565}],"total_pool":2124.27849,"total_inflation":18000000.0,"action":"get_pool_members","status":"success"}
  inf_dest = params["inf_dest"]
  if inf_dest.length != 56
    return {"status"=>"error", "error"=>"inf_dest contains invalid accountID "}
  end 
  
  total_inflation = params["total_inflation"]
  if total_inflation.nil?
    total_inflation=0
  end
  total_inflation = total_inflation.to_f
       
  offset = params["offset"] 
  if offset.nil?
    offset = 0
  end

  query = "SELECT accountid, balance, lastmodified FROM accounts WHERE inflationdest = '#{inf_dest}'"
  if params["lastmodified"].nil?
    lastmodified = 0
  else
    lastmodified = params["lastmodified"].to_f
    query = "SELECT accountid, balance, lastmodified FROM accounts WHERE inflationdest = '#{inf_dest}' AND lastmodified < '#{lastmodified}'"
  end
  puts "query: " + query
  hash = {"accounts"=>[]} 

  #query = "SELECT accountid, balance FROM accounts WHERE inflationdest= '#{inf_dest}'"

  #txhistory = get_db(query)
  result = get_db(query,1)  
  index = offset
  total = 0

  result.each do |row|
    puts "index: #{index}"
    row["index"] = index   
    row["balance"] = row["balance"].to_f/10000000
    total = total + row["balance"]   
    hash["accounts"].push(row)
    index = index + 1
  end
  index2 = 0
  if total_inflation == 0 
    total_inflation = (total * 0.01)/52
  end
  hash["accounts"].each do |row|
    puts "index2: #{index2}"
    #row["index"] = index
    #row["balance"] = row["balance"].to_f/10000000   
    #multiplier = total / row["balance"]
    multiplier = row["balance"] / total 
    hash["accounts"][index2]["to_receive"] = total_inflation * multiplier 
    hash["accounts"][index2]["multiplier"] = multiplier
    hash["accounts"][index2]["lastmodified"] = row["lastmodified"]
    puts "mult: #{multiplier}"
    puts "bal: #{row["balance"]}"
    puts "index: #{row["index"]}"
    #hash["accounts"].push(row)
    index2 = index2 + 1
  end
  hash["member_count"] = hash["accounts"].length
  hash["total_pool"] = total
  hash["total_inflation"] = total_inflation
  hash["action"] = "get_pool_members"
  hash["status"] = "success"
  # convert the inf_dest to a no signature pair, it's not used for signing at this time
  from_key_pair = account = convert_address_to_keypair(inf_dest)
  b64_envelope_tx = generate_pool_tx(from_key_pair, hash)
  b64_tx_array = generate_pool_array_tx(from_key_pair, hash)  
  hash["b64_tx"] = b64_envelope_tx
  hash["b64_tx_array"] = b64_tx_array
  return hash
end

#SELECT accountid, balance FROM accounts WHERE inflationdest='GBL7AE2HGRNQSPWV56ZFLILXNT52QWSMOQGDBBXYOP7XKMQTCKVMX2ZL';


def get_account_txhistory(account,offset=0)
  if offset.nil?
    offset = 0
  end
  query = "SELECT * FROM txhistory ORDER BY ledgerseq DESC LIMIT 300 OFFSET #{offset}"
  #txhistory = get_db(query)
  result = get_db(query,1)
  hash = {"txhistory"=>[]}
  index = offset
  result.each do |row|
    puts "index: #{index}"
    puts "row[txbody]: #{row["txbody"]}"
    txbody = envelope_to_hash(row["txbody"])
    source_address = txbody["source_address"]
    puts "source_address: #{source_address}"
    puts "account: #{account}"
    if txbody["source_address"] == account
      txbody["txresults"] = txresult_resultcode(row["txresult"])
      txbody["index"] = index
      txbody.delete("txmeta")
      txbody.delete("txindex")
      hash["txhistory"].push(txbody)
      puts "hash: #{hash}"
      index = index + 1
    end
    if (index - offset) > 10
      return hash
    end
  end
  return hash
end

def get_market_price(params)
  #this will return the present market price seen on stellar order book for buy_asset when selling sell_amount
  #of sell_asset when trading it for buy_asset. the return price will be the quantity of buy_asset per sell_asset offered for this amount
  puts "start get_market_price"
  sell_asset = params["sell_asset"]
  sell_issuer = params["sell_issuer"]
  sell_amount = params["sell_amount"].to_f
  buy_asset = params["buy_asset"]
  buy_issuer = params["buy_issuer"]
  #sellerid = params["sellerid"]
  if sell_asset.nil?
    sell_asset = "XLM"
    params["sell_asset"] = "XLM"
  end
  if sell_amount == 0
    sell_amount = 1
    params["sell_amount"] = 1
  end
  begin
    results = get_offers(params)
    puts "results: #{results}" 
    orders = results["orders"]
    total_cost = 0.0
    averge_price = 0.0
    max_bid = 0.0
    price = 0.0
    total_amount = 0.0
    puts   "sell_amount: #{sell_amount}"
    orders.each do |row|
      puts "row: #{row}"   
      amount = row["amount"].to_f
      price = row["price"].to_f              
      if max_bid < price
        max_bid = price
      end
      total_amount = total_amount + amount      
      puts "total_amount: #{total_amount}"     
      puts "price: #{price}"
      total_cost = total_cost + (price * amount)
      puts "total_cost: #{total_cost}"
      if total_amount > 0
        averge_price = total_cost / total_amount
      else
        averge_price = price
      end
      puts "averge_price: #{averge_price}"
      sale_equiv = sell_amount / averge_price
      puts "sale_equiv: #{sale_equiv}"
      if  total_amount >=  sale_equiv
        puts "have liquidity"     
        return {"action"=>"get_market_price", "buy_asset"=>buy_asset, "sell_asset"=>sell_asset, "averge_price"=>averge_price, "max_bid"=>max_bid, "amount"=>sell_amount, "total_amount"=>results["total_amount"], "status"=>"success"}
      end            
    end

    max_sell_amount = averge_price * total_amount
    return {"action"=>"get_market_price", "buy_asset"=>buy_asset, "sell_asset"=>sell_asset, "averge_price"=>averge_price, "max_bid"=>max_bid, "amount"=>sell_amount, "amount_available"=>total_amount, "max_sell_amount"=>max_sell_amount, "status"=>"not_liquid"}
  rescue
    return {"action"=>"get_market_price", "status"=>"error", "error"=>"bad input or missing params"}
  end
end

def get_buy_offers(params)
  puts "asset: #{params["asset"]}"
  params["buy_asset"] = params["asset"]
  params["buy_issuer"] = params["issuer"] 
  return get_offers(params)
end

def get_sell_offers(params)
  puts "asset: #{params["asset"]}"
  params["sell_asset"] = params["asset"]
  params["sell_issuer"] = params["issuer"] 
  return get_offers(params)
end
    
def get_offers(params)
  buy_asset_type = params["buy_asset_type"]
  buy_asset = params["buy_asset"]
  buy_issuer = params["buy_issuer"]
  sell_asset_type = params["sell_asset_type"]
  sell_asset = params["sell_asset"]
  sell_issuer = params["sell_issuer"]
  sort = params["sort"]
  limit = params["limit"]
  offset = params["offset"]
  offerid = params["offerid"]
  sellerid = params["sellerid"]
  #sort = "DESC||ASC"
  hash = {"action"=>"get_offers","orders"=>[]}
  if sort != "DESC" and sort != "ASC"
    sort = "ASC"
  end
  if offset.nil?
    offset = 0
  end
  if limit.nil?
    limit = 30
  end
  if !(offerid.nil?)
    hash["action"] = "get_offerid"
    puts "offerid detected"
    query = "SELECT * FROM offers WHERE offerid='#{offerid}' "
    query2 = "SELECT Count(*) FROM offers WHERE offerid='#{offerid}'"
  else
    
    query = ""
    first = true
    if sell_asset == "XLM" and sell_asset_type != 1
      first = false
      query = query + " sellingassettype='0'"
    end
    
    if !(sell_asset.nil?)  and sell_asset != "XLM"
      if sell_asset.length > 0
        if !first
          query = query + " AND"
        end
        first = false
        query = query + " sellingassetcode='#{sell_asset}'"
      end
    end
    
    if !(sell_asset_type.nil?)
      if !first
        query = query + " AND"
      end
      first = false
      query = query + " sellingassettype='#{sell_asset_type}"
    end
    
    if !(sell_issuer.nil?)
      if sell_issuer.length > 0 
        if !first
          query = query + " AND"
        end
        first = false
        query = query + " sellingissuer='#{sell_issuer}'"
      end
    end

    if !(sellerid.nil?)
      if sellerid.length > 0
        if !first
          query = query + " AND"
        end
        first = false
        query = query + " sellerid!='#{sellerid}'"
      end
    end
    
    if buy_asset == "XLM" and buy_asset_type != 1
      if !first
        query = query + " AND"
      end 
      first = false
      query = query + " buyingassettype='0'"
    end
    
    if !(buy_asset.nil?)  and buy_asset != "XLM"
      if buy_asset.length > 0
        if !first
          query = query + " AND"
        end
        first = false
        query = query +  " buyingassetcode='#{buy_asset}'"
      end
    end
    
    if !(buy_asset_type.nil?)
      if !first
        query = query + " AND"
      end
      first = false
      query = query + " buyingassettype='#{buy_asset_type}'"
    end
    
    if !(buy_issuer.nil?) 
      if buy_issuer.length > 0
        if !first
          query = query + " AND"
        end
        first = false
        query = query + " buyingissuer='#{buy_issuer}'"
      end
    end 
    if !first
      query = " FROM offers WHERE" + query
    else
      query = " FROM offers "
    end
    query2 = "SELECT Count(*)" + query
    query = "SELECT *" + query
    query = query + " ORDER BY price #{sort} LIMIT '#{limit}' OFFSET '#{offset}'"
  end
  puts "query: #{query}"
  puts "query2: #{query2}"
  begin
    result = get_db(query,1)
    #hash = {"orders"=>[]}
    index = offset
    total_amount = 0.0
    result.each do |row|
      #puts "row: #{row}"
      row["index"]=index
      row["amount"] = row["amount"]/10000000.0
      total_amount = total_amount + row["amount"]
      row["inv_base_amount"] = 1.0/row["amount"]
      row["inv_base_price"] = 1.0/row["price"]
      hash["orders"].push(row)
      index = index + 1
    end
    hash["total_amount"] = total_amount
    result2 = get_db(query2)
    puts "result2: #{result2}"
    hash["count"]=result2["Count(*)"]
    return hash
  
  rescue
    hash["status"]="error2"
    return hash
  end 
end 


def get_trustlines_local(account,issuer,currency)
   # balance of trustlines on the Stellar account from localy running Stellar-core db
  # you must setup your local path to @stellar_db_file_path for this to work
  # also at this time this assumes you only have one gateway issuer for each currency
  account = convert_keypair_to_address(account) 
  issuer = convert_keypair_to_address(issuer) 
  puts "account: #{account}  issuer: #{issuer}   currency:  #{currency}"
  if currency == "XLM" and (issuer.length == 0 or issuer == "undefined")    
    result = {}
    result["balance"] = get_native_balance_local(account)
    result["status"] = "native balance"
    result["accountid"] = account
    result["issuer"] = issuer
    result["assetcode"] = currency
    result["action"] = "get_lines_balance"
    return result
  end
  query = "SELECT * FROM trustlines WHERE accountid='#{account}' AND assetcode='#{currency}' AND issuer='#{issuer}'"
  result = get_db(query)
  if result.nil?
    result = {}
    result["balance"] = 0
    result["status"] = "account not found"
    result["accountid"] = account
    result["issuer"] = issuer
    result["asset"] = currency
  else
    result["balance"] = result["balance"].to_f/10000000
  end
  result["action"] = "get_lines_balance"
  #puts "result: #{result}"
  return result
end

def get_lines_balance_local(account,issuer,currency)
  # balance of trustlines on the Stellar account from localy running Stellar-core db
  # you must setup your local path to @stellar_db_file_path for this to work
  # also at this time this assumes you only have one gateway issuer for each currency
  result = get_trustlines_local(account,issuer,currency)
  if result == nil
    puts "no record found"
    return nil
  else
    bal = result["balance"].to_f
    return 
  end
end

def get_lines_balance_mss(account,issuer,currency)
  send = { "action"=>"get_lines_balance", "account"=>account, "issuer"=>issuer, "asset"=>currency }
  result = send_action_mss(send)
  #puts "result_g: #{result}"
  bal = result["balance"].to_f
  return bal
end

def get_lines_balance(account,issuer,currency)
  issuer = convert_keypair_to_address(issuer) 
  account = convert_keypair_to_address(account) 
  if @configs["mode"] == "horizon"
    return get_lines_balance_horizon(account,issuer,currency)
  elsif @configs["mode"] == "mss"
    return get_lines_balance_mss(account,issuer,currency)
  else
    return get_lines_balance_local(account,issuer,currency)
  end
end

def bal_CHP(account)
  get_lines_balance(account,"CHP")
end

def get_sequence_local(account)
  result = get_accounts_local(account)
  if result["status"] == "account not found"
    puts "account #{account} not found, so will return sequence 0"
    return 0
  end
  return result["seqnum"].to_i
end

def get_thresholds_local(account)
  result = get_accounts_local(account)
  if result["status"] == "account not found"
    puts "account not found"
    return "nil"
  end
  thresholds_b64 = result["thresholds"]
  send = decode_thresholds_b64(thresholds_b64)
  puts "send:  #{send}"
  send["action"]= "get_thresholds_info"
  return send
end

def get_signer_info(target_address,signer_address="")
  #this will return the present state of this signer_address power on this target_address
  #as presently seen in the stellar network database
  #this will only work in localcore mode
  #the address can be keypairs or address strings
  target_address = convert_keypair_to_address(target_address)
  signer_address = convert_keypair_to_address(signer_address)
  if signer_address == ""
    query = "SELECT * FROM signers WHERE accountid='#{target_address}'"
  else
    query = "SELECT * FROM signers WHERE accountid='#{target_address}' AND publickey='#{signer_address}'"
  end
  if signer_address == ""
    result = get_db(query,1)
    hash = {"signers"=>[]}
    result.each do |row|
      hash["signers"].push(row)
    end
  else
    hash = get_db(query)    
  end
  hash["action"] = "get_signer_info"
  return hash  
end 


def get_account_info_horizon(account)
    account = convert_keypair_to_address(account)
    params = '/accounts/'
    url = @configs["url_horizon"]
    #puts "url_horizon:  #{url}"
    send = url + params + account
    #puts "sending:  #{send}"
    begin
    postdata = RestClient.get send
    rescue => e
      return  e.response
    end
    data = JSON.parse(postdata)
    return data
end

def get_stellar_core_status(detail=false)
    #return true if stellar-core status is synced false if other than synced
    #if detail is true then return a hash containing all that is seen in return from stellar-core responce
    params = '/info'
    url = @configs["url_stellar_core"]
    #url = "localhost:8080"
    puts "url_stellar_core:  #{url}"
    send = url + params
    #puts "sending:  #{send}"
    begin
    postdata = RestClient.get send
    rescue => e
      puts "error in core status"
      puts "e: #{e}"
      puts "e.class: #{e.class}"
      puts "e.to_s: #{e.to_s}"
      return e.to_s
      #return  e.response
    end
    puts "postdata: #{postdata}"
    data = JSON.parse(postdata)
    puts "data: #{data}"
    if detail == true
      return data
    end
    if data["state"] == "Synced!"
      return true
    else 
      return false
    end
end

def get_set_stellar_core_network()
  #auto mode only works with a local stellar-core 
  #this will get the present value of the network running and update current_network
  # with what is found
  #@configs["mode"] = "horizon"
  #@configs["default_network"] = "auto"
  if (@configs["default_network"] == "auto") and (@configs["mode"] != "horizon")
    puts "auto network mode active"
    info = get_stellar_core_status(true)
    network = info["info"]["network"]
    #puts "network now running: #{network}"
    Stellar.default_network = network
    puts "present network setting: #{Stellar.current_network}"
  else
    puts "default_network not set to auto or in horizon mode, so unchanged"
    puts "present set to: #{@configs["default_network"]}"
  end
end


def get_sequence(account)
  if @configs["mode"] == "horizon"
    #puts "horizon mode get seq"
    return get_sequence_horizon(account)
  elsif @configs["mode"] == "mss"
    return get_sequence_mss(account)
  else
    return get_sequence_local(account)
  end
end

def get_sequence_horizon(account)
  data = get_account_info_horizon(account)
  return data["sequence"]
end

def get_sequence_mss(account)
  account = convert_keypair_to_address(account)
  send = {"action"=>"get_sequence", "account"=>account}
  result = send_action_mss(send)
  return result["sequence"]
end

def next_sequence(account)
  # account here can be Stellar::KeyPair or String with Stellar address
  address = convert_keypair_to_address(account)
  #puts "address for next_seq #{address}"
  result =  get_sequence(address)
  puts "seqnum:  #{result}"
  return (result.to_i + 1)  
end

def bal_STR(account)
  get_native_balance(account)
end

def get_native_balance(account)
  if @configs["mode"] == "horizon"
    return get_native_balance_horizon(account)
  elsif @configs["mode"] == "mss"
    return get_native_balance_mss(account)
  else
    return get_native_balance_local(account)
  end
end

def get_native_balance_local(account)
  #puts "account #{account}"
  result = get_accounts_local(account)
  if result["status"] == "account not found"
    puts "account not found"
    return 0
  end
  bal = result["balance"].to_f
  return bal
end

def get_native_balance_mss(account)
  account = convert_keypair_to_address(account)
  send = {"action"=>"get_account_info", "account"=>account}
  result = send_action_mss(send)
  bal = result["balance"].to_f
  return bal
end


def get_native_balance_horizon(account)
  #compatable with old ruby horizon and go-horizon formats
  data = get_account_info_horizon(account)
  if data["balances"] == nil
    return 0
  end
  data["balances"].each{ |row|
    #puts "row = #{row}"
    #go-horizon format
    if row["asset_type"] == "native"
      return row["balance"]
    end
    #old ruby horizon format
    if !row["asset"].nil?
      if row["asset"]["type"] == "native"
        return row["balance"]
      end
    end
  }
  return 0
end

def get_lines_balance_horizon(account,issuer,currency)
  #will only work on go-horizon
  data = get_account_info_horizon(account)
  if data["balances"]==nil
    return 0
  end
  data["balances"].each{ |row|
    if row["asset_code"] == currency
      if row["issuer"] == issuer
        return row["balance"]
      end
    end
  }
  return 0
end

def create_random_pair
  return Stellar::KeyPair.random
end

def create_new_account()
  #this is created just to be compatible with old network function in payment_class.rb
  return Stellar::KeyPair.random
end

def send_tx_local(b64)
  # this assumes you have a stellar-core listening on this address
  # this sends the tx base64 transaction to the local running stellar-core
  puts "b64:  #{b64}"
  if (b64.nil?) or (b64 == false) or (b64 == "")
    puts "b64 was nil or false, nothing done in send_tx"
    return "nothing sent"
  end
  txid = envelope_to_txid(b64)
  $server = Faraday.new(url: @configs["url_stellar_core"]) do |conn|
    conn.response :json
    conn.adapter Faraday.default_adapter
  end
  result = $server.get('tx', blob: b64)
  if result.body["error"] != nil
    puts "#result.body: #{result.body}"
    puts "#result.body[error]: #{result.body["error"]}"
    b64 = result.body["error"]
    # decode to the raw byte stream
    bytes = Stellar::Convert.from_base64 b64
    # decode to the in-memory TransactionResult
    tr = Stellar::TransactionResult.from_xdr bytes
    # the actual code is embedded in the "result" field of the 
    # TransactionResult.
    status = {"status"=>"error","action"=>"send_b64"}
    status["error"] = tr.result.code      
    puts "#{status}"
    return status
  end
  puts "#result.body: #{result.body}" 
  txhistory = get_txhistory(txid) 
  count = 0
  while (txhistory.nil?) and (count < 15)
    puts "count:  #{count}"
    sleep 1
    txhistory = get_txhistory(txid)
    count = count + 1 
  end
  if count >= 15
    txhistory = {"status"=>"error","action"=>"send_b64","body"=>result.body,"error"=>"timeout from localcore get_tx_history, check sync"}
  else
    txhistory["body"] = result.body
    txhistory["resultcode"] = txresult_resultcode(txhistory["txresult"])
  end
  txhistory["action"] = "send_b64"
  txhistory["status"] = "success"
  puts "send_b64 status: #{txhistory}"
  return txhistory
end

def txresult_resultcode(b64)
  bytes = Stellar::Convert.from_base64 b64
  tranpair = Stellar::TransactionResultPair.from_xdr bytes
  x = tranpair.result.result
  hash = {}
  x.instance_variables.each {|var| 
  hash[var.to_s.delete("@")] = x.instance_variable_get(var) }
  #p hash["switch"]
  return hash["switch"]
end


def send_tx_horizon(b64)
  values = CGI::escape(b64)
  #puts "url:  #{@configs["url_horizon"]}"
  headers = {
    :content_type => 'application/x-www-form-urlencoded'
  }
  #puts "values: #{values}"
  #response = RestClient.post @configs["url_horizon"]+"/transactions", values, headers
  #response = RestClient.post @configs["url_horizon"]+"/transactions", b64, headers
  begin
    response = RestClient.post(@configs["url_horizon"]+"/transactions", {tx: b64}, headers)
  rescue => e
    puts "e.response: #{e.response}"
    puts  "json: #{JSON.parse(e.response)}"
    response = JSON.parse(e.response)
    response["decoded_error"] = decode_error(response["extras"]["result_xdr"])
    puts "decoded_error:  #{response["decoded_error"]}"    
    return response
  end
  puts response
  sleep 12
  return response
end

def send_tx_mss(b64)
  send = {"action"=>"send_b64", "envelope_b64"=>b64}
  return send_action_mss(send)
end

def send_action_mss(send)
  #puts "mss selected"
  port = @configs["mss_port"].to_i + 1
  port = port.to_s
  #puts "port: #{port}"
  #puts "send: #{send}"
  begin
    response = RestClient.post(@configs["url_mss_server"]+":"+port, send.to_json)
  rescue => e
    puts "e.response: #{e.response}"
    puts  "json: #{JSON.parse(e.response)}"
    response = JSON.parse(e.response)
    response["decoded_error"] = decode_error(response["extras"]["result_xdr"])
    puts "decoded_error:  #{response["decoded_error"]}"    
    return response
  end
  #puts response
  if send["action"]== "send_b64"
    sleep 9
  end
  return JSON.parse(response)
end

def send_tx(b64)
  if b64 == "no funds"
    return "no funds"
  end
  if @configs["mode"] == "horizon"
    result = send_tx_horizon(b64)
    return result
  elsif @configs["mode"] == "mss"
    result = send_tx_mss(b64)
    return result
  else
    result = send_tx_local(b64)
    return result
  end  
end

def create_account_tx(account, funder, starting_balance)
  #get_set_stellar_core_network()
  #puts "starting_balance #{starting_balance}"
  starting_balance = starting_balance.to_f
  account = convert_address_to_keypair(account)
  nxtseq = next_sequence(funder)
  #puts "create_account nxtseq #{nxtseq}"     
  tx = Stellar::Transaction.create_account({
    account:          funder,
    destination:      account,
    sequence:         next_sequence(funder),
    starting_balance: starting_balance,
    fee:        @configs["fee"].to_i
  })
  return tx
end


def create_account(account, funder, starting_balance = @configs["start_balance"]) 
  #this will create an activated account using funds from funder account
  # both account and funder are stellar account pairs, only the funder pair needs to have an active secrete key and needed funds
  # @configs["mode"] can point output to "horizon" api website or "local" to direct output to localy running stellar-core
  # this also includes the aprox delay needed before results can be seen on network 
  tx = create_account_tx(account, funder, starting_balance)
  b64 = tx.to_envelope(funder).to_xdr(:base64)
  #puts "b64: #{b64}"
  send_tx(b64)
end


def create_key_testset_and_account(start_balance = @configs["start_balance"])
  if !File.file?("./multi_sig_account_keypair.yml")
    #if the file didn't exist we will create the needed set of keypair files and fund the needed account.
    multi_sig_account_keypair = Stellar::KeyPair.random
    puts "my #{multi_sig_account_keypair.address}"
    puts "mys #{multi_sig_account_keypair.seed}"
    to_file = "./multi_sig_account_keypair.yml"
    puts "save to file #{to_file}"
    File.open(to_file, "w") {|f| f.write(multi_sig_account_keypair.to_yaml) }

    signerA_keypair = Stellar::KeyPair.random
    puts "A #{signerA_keypair.address}"
    puts "As #{signerA_keypair.seed}"
    to_file = "./signerA_keypair.yml"
    puts "save to file #{to_file}"
    File.open(to_file, "w") {|f| f.write(signerA_keypair.to_yaml) }

    signerB_keypair = Stellar::KeyPair.random
    puts "B #{signerB_keypair.address}"
    puts "Bs #{signerB_keypair.seed}"
    to_file = "./signerB_keypair.yml"
    puts "save to file #{to_file}"
    File.open(to_file, "w") {|f| f.write(signerB_keypair.to_yaml) }
    if start_balance != 0
      #activate and fund the  account 
      master  = eval( @configs["master_keypair"])
      puts "create_account #{multi_sig_account_keypair.address}"
      puts "funded by #{master.address} with start balance: #{start_balance}"
      result = create_account(multi_sig_account_keypair, master, start_balance)
      puts "#{result}"
    end
  end
end

def account_address_to_keypair(account_address)
  # return a keypair from an account number
  Stellar::KeyPair.from_address(account_address)
end

def generate_pool_tx(from_key_pair, to_hash)
  #example input to_hash is derived from the get_pool_members output format
  #{"accounts":[{"accountid":"GDRFRGR2FDUFF2RI6PQE5KFSCJHGSEIOGET22R66XSATP3BYHZ46BPLO","balance":2096.91552,"index":0,"to_receive":17768140.824134596,"multiplier":0.9871189346741442},{"accountid":"GDTHJDFZOENIOR5TITSW46KMSDQQN7WUULBJXO5EDOAOVDAAGEEB7LQQ","balance":27.36297,"index":1,"to_receive":231859.17586540172,"multiplier":0.01288106532585565}],"total_pool":2124.27849,"total_inflation":18000000.0,"action":"get_pool_members","status":"success"}
  # this function will return with b64 envelope with up to 98 transactions to send, you can then add more sigs to this envelope and send it
  to_array = []
  if to_hash["accounts"].length > 98
    puts "we can't handle more than 98 transactions at this time, will exit return error"
    return {"status"=>"error", "error"=>"over 98 transactions not supported yet"}
  end
  to_hash["accounts"].each do |account|
    puts "accountid: #{account["accountid"]}"
    puts "account_to_receive: #{account["to_receive"]}"
    new_set = {}
    new_set["accountid"] = account["accountid"]
    new_set["amount"] = account["to_receive"]
    to_array.push(new_set)
  end
  tx = send_native_to_many_tx(from_key_pair, to_array)
  if tx == "none"
    return "none"
  end
  env = Stellar::TransactionEnvelope.new({
    :signatures => [],
    :tx => tx
  })
  #b64 = tx.to_envelope(dumy_key_pair).to_xdr(:base64)
  b64 = tx.to_xdr(:base64)
  return b64 
end

def send_native_to_many_tx(from_pair, to_array)
  # send from one account to many accounts in a single transaction (max 99 transactions)
  # to_array is formated [{"accountid"=>"GDFRG...", "amount"=>"1.23"}, {"accountid"=>"GTRTB...", "amount"=>"3.24"}]
  # returns with a tx transaction that can later signed and converted to b64
  seq = next_sequence(from_pair)
  puts "from_pair: #{from_pair}"
  if to_array.length == 0 
    return "none"
  end
  to_pair = convert_address_to_keypair(to_array[0]["accountid"]) 
  puts "to_pair: #{to_pair}"
  puts "amount: #{to_array[0]["amount"].to_s}"
  puts "seq: #{seq}"
  tx = Stellar::Transaction.payment({
    account:     from_pair,
    destination: to_pair,
    sequence:    seq,
    amount:      [:native, to_array[0]["amount"].to_s ],
    fee: 0
  })
  to_array.drop(1).each do | hash |
    seq = seq + 1
    to_pair = convert_address_to_keypair(hash["accountid"])
    tx2 = Stellar::Transaction.payment({
      account:     from_pair,
      destination: to_pair,
      sequence:    seq,
      amount:      [:native, hash["amount"].to_s ],
      fee: 0
    })
    tx = tx.merge(tx2)
  end
  # should play with this number to be sure this is correct fee needed (might be less)
  tx.fee = to_array.length * 100
  return tx
end

def generate_pool_array_tx(from_key_pair, to_hash)
  #example input to_hash is derived from the get_pool_members output format
  #{"accounts":[{"accountid":"GDRFRGR2FDUFF2RI6PQE5KFSCJHGSEIOGET22R66XSATP3BYHZ46BPLO","balance":2096.91552,"index":0,"to_receive":17768140.824134596,"multiplier":0.9871189346741442},{"accountid":"GDTHJDFZOENIOR5TITSW46KMSDQQN7WUULBJXO5EDOAOVDAAGEEB7LQQ","balance":27.36297,"index":1,"to_receive":231859.17586540172,"multiplier":0.01288106532585565}],"total_pool":2124.27849,"total_inflation":18000000.0,"action":"get_pool_members","status":"success"}
  # this function will return with b64 envelope with up to 98 transactions to send, you can then add more sigs to this envelope and send it
  to_array = []
  if to_hash["accounts"].length > 98
    puts "we can't handle more than 98 transactions at this time, will exit return error"
    return {"status"=>"error", "error"=>"over 98 transactions not supported yet"}
  end
  to_hash["accounts"].each do |account|
    puts "accountid: #{account["accountid"]}"
    puts "account_to_receive: #{account["to_receive"]}"
    new_set = {}
    new_set["accountid"] = account["accountid"]
    new_set["amount"] = account["to_receive"]
    to_array.push(new_set)
  end
  tx_array = send_native_to_many_v2_tx(from_key_pair, to_array)  
  return tx_array 
end

def send_native_to_many_v2_tx(from_pair, to_array)
  # send by generating an array of tx from one account to many accounts in a array of transactions with each tx in the array having up to the limit
  # of 99 operations in each that is the limit stellar has per tx envelope
  # this is an improved version of send_native_to_many_tx that had a limitation of 98 max tx transactions,  this version has no real limits 
  # to_array is formated [{"accountid"=>"GDFRG...", "amount"=>"1.23"}, {"accountid"=>"GTRTB...", "amount"=>"3.24"}]
  # returns with an array of tx transaction in base 64 format that can later be signed 
  # note this generates unsigned tx base 64 envelopes that must each be later signed by one or all needed signers.
  seq = next_sequence(from_pair)
  puts "from_pair: #{from_pair}"
  if to_array.length == 0
    return "none"
  end
  to_pair = convert_address_to_keypair(to_array[0]["accountid"]) 
  puts "to_pair: #{to_pair}"
  puts "amount: #{to_array[0]["amount"].to_s}"
  puts "seq: #{seq}"
  tx = Stellar::Transaction.payment({
    account:     from_pair,
    destination: to_pair,
    sequence:    seq,
    amount:      [:native, to_array[0]["amount"].to_s ],
    fee: 0
  })
  # max_tx now set at 10 just for test, will set to 98 or 99 for production that is max stellar tx number per envelope
  max_tx = 98
  count = 0
  tx_array = []
  to_array.drop(1).each do | hash |
    seq = seq + 1
    to_pair = convert_address_to_keypair(hash["accountid"])
    tx2 = Stellar::Transaction.payment({
      account:     from_pair,
      destination: to_pair,
      sequence:    seq,
      amount:      [:native, hash["amount"].to_s ],
      fee: 0
    })
    
    count = count + 1
    if max_tx == count
      tx.fee = tx.operations.length * 100
      puts "tx.fee: #{tx.fee}"
      env = Stellar::TransactionEnvelope.new({
        :signatures => [],
        :tx => tx
      })
      b64 = tx.to_xdr(:base64)
      tx_array.push(b64)
      tx = tx2
      count = 0
    else
      tx = tx.merge(tx2)
    end
  end
  tx.fee = tx.operations.length * 100
  env = Stellar::TransactionEnvelope.new({
    :signatures => [],
    :tx => tx
  })
  #b64 = tx.to_envelope(dumy_key_pair).to_xdr(:base64)
  b64 = tx.to_xdr(:base64)
  tx_array.push(b64)
  return tx_array
end

def send_native_tx(from_pair, to_account, amount, seqadd=0)
  #get_set_stellar_core_network()
  #destination = Stellar::KeyPair.from_address(to_account)
  to_pair = convert_address_to_keypair(to_account)  
  tx = Stellar::Transaction.payment({
    account:     from_pair,
    destination: to_pair,
    sequence:    next_sequence(from_pair)+seqadd,
    #amount:      [:native, amount * Stellar::ONE],
    amount:      [:native, amount.to_s ],
    fee:        @configs["fee"].to_i
  })
  return tx   
end

def send_native(from_pair, to_account, amount, memo)
  # this will send native lunes from_pair account to_account
  # from_pair must be an active stellar key pair with the needed funds for amount
  # to_account can be an account address or an account pair with no need for secrete key.
  tx = send_native_tx(from_pair, to_account, amount)
  puts "memo: #{memo}"
  if !(memo.nil?)   
     puts "memo detected" 
    tx.memo = Stellar::Memo.new(:memo_text, memo)
  end 
  b64 = tx.to_envelope(from_pair).to_xdr(:base64)
  send_tx(b64)
end

def add_trust_tx(issuer_account,to_pair,currency,limit)
  #get_set_stellar_core_network()
  #issuer_pair = Stellar::KeyPair.from_address(issuer_account)
  issuer_pair = convert_address_to_keypair(issuer_account)
  tx = Stellar::Transaction.change_trust({
    account:    to_pair,
    sequence:   next_sequence(to_pair),
    line:       [:alphanum4, currency, issuer_pair],
    limit:      limit,
    fee:        @configs["fee"].to_i
  })
  #puts "fee = #{tx.fee}"
  return tx
end

def add_trust(issuer_account,to_pair,currency,limit=900000000000)
  tx = add_trust_tx(issuer_account,to_pair,currency,limit)
  b64 = tx.to_envelope(to_pair).to_xdr(:base64)
  send_tx(b64)
end

def allow_trust_tx(account, trustor, code, authorize=true)
  #get_set_stellar_core_network()
  # I guess code would be asset code in format of :native or like "USD, issuer"..  ? not sure not tested yet
  # also not sure what a trustor is ??
  asset = make_asset([code, account])      
  tx = Stellar::Transaction.allow_trust({
    account:  account,
    sequence: next_sequence(account),
    asset: asset,
    trustor:  trustor,
    fee:        @configs["fee"].to_i,
    authorize: authorize,
  }).to_envelope(account)
  b64 = tx.to_envelope(to_pair).to_xdr(:base64)
  return b64
end

def allow_trust(account, trustor, code, authorize=true)
  b64 = allow_trust_tx(account, trustor, code, authorize=true)
  send_tx(b64)
end

def make_asset(input)
  if input == :native
    return [:native]
  end
  code, issuer = *input      
  [:alphanum4, code, issuer]
end

def send_currency_tx(from_account_pair, to_account_pair, issuer_pair, amount, currency)
  #get_set_stellar_core_network()
  # to_account_pair and issuer_pair can be ether a pair or just account address
  # from_account_pair must have full pair with secreet key
  to_account_pair = convert_address_to_keypair(to_account_pair)
  issuer_pair = convert_address_to_keypair(issuer_pair)
  tx = Stellar::Transaction.payment({
    account:     from_account_pair,
    destination: to_account_pair,
    sequence:    next_sequence(from_account_pair),
    amount:      [:alphanum4, currency, issuer_pair, amount.to_s],
    fee:        @configs["fee"].to_i
  })  
  return tx
end

def send_currency(from_account_pair, to_account_pair, issuer_pair, amount, currency, memo=nil)
  # to_account_pair and issuer_pair can be ether a pair or just account address
  # from_account_pair must have full pair with secreet key
  tx = send_currency_tx(from_account_pair, to_account_pair, issuer_pair, amount, currency)
  if !(memo.nil?)    
    tx.memo = Stellar::Memo.new(:memo_text, memo)
  end 
  b64 = tx.to_envelope(from_account_pair).to_xdr(:base64)
  send_tx(b64)
end

def send_CHP(from_issuer_pair, to_account_pair, amount)
  send_currency(from_issuer_pair, to_account_pair, from_issuer_pair, amount, "CHP")
end

def create_new_account_with_CHP_trust(acc_issuer_pair)
  currency = "CHP"
  to_pair = Stellar::KeyPair.random
  create_account(to_pair, acc_issuer_pair, starting_balance=30)
  add_trust(issuer_account,to_pair,currency)
  return to_pair
end

def offer(account,sell_issuer,sell_currency, buy_issuer, buy_currency,amount,price)
  tx = offer_tx(account,sell_issuer,sell_currency, buy_issuer, buy_currency,amount,price)
  b64 = tx.to_envelope(account).to_xdr(:base64)
  return b64
end

def offer_tx(account,sell_issuer,sell_currency, buy_issuer, buy_currency,amount,price)
  #get_set_stellar_core_network()
  sell_issuer = convert_address_to_keypair(sell_issuer)
  buy_issuer = convert_address_to_keypair(buy_issuer)
  tx = Stellar::Transaction.manage_offer({
    account:    account,
    sequence:   next_sequence(account),
    selling:    [:alphanum4, sell_currency, sell_issuer],
    buying:     [:alphanum4, buy_currency, buy_issuer],
    amount:     amount.to_s,
    fee:        @configs["fee"].to_i,
    price:      price.to_s,
  })
  return tx
end

def tx_merge(*tx)
  #get_set_stellar_core_network()
  # this will merge an array of tx transactions and take care of seq_num and fee adjustments
  # I'm not totaly sure you need a fee = count * 10, not sure what the exact number is yet but it works so go with it
  puts ""
  #puts "tx.inspect:  #{tx.inspect}"
  if tx[0].class == Array
    tx = tx[0]
  end
  seq_num = tx[0].seq_num 
  tx0 = tx[0]
  count = tx.length
  #puts "count: #{count}"
  tx.drop(1).each do |row|
    seq_num = seq_num + 1
    row.seq_num = seq_num
    #puts "row.source_account: #{row.source_account}"
    tx0 = tx0.merge(row)
  end
  tx0.fee = count * @configs["fee"].to_i
  return tx0 
end


def tx_to_b64(from_pair,tx)
  # in the event we want to later convert tx to base64, don't need it yet but maybe someday?
  # not presently used, just here as a reference.
  b64 = tx.to_envelope(from_pair).to_xdr(:base64)
  return b64
end

def tx_to_envelope(from_pair,tx)
  envelope = tx.to_envelope(from_pair)
  return envelope
end

def envelope_to_b64(envelope)
  b64 = envelope.to_xdr(:base64)
  return b64
end

def b64_to_envelope(b64)
  #puts "b64 class: #{b64.class}"
  #puts "b64: #{b64}"
  if b64.nil?
    return nil
  end
  if b64.class == String
    begin
      bytes = Stellar::Convert.from_base64 b64
    rescue
      return "bad_from_base64"
    end
    begin
      envelope = Stellar::TransactionEnvelope.from_xdr bytes
    rescue
      return "bad_from_xdr"
    end
    return envelope
  else
    return b64
  end
end

def convert_keypair_to_address(account)
  if (account == "") or (account.nil?)
    return ""
  end
  if account.is_a?(Stellar::KeyPair)
    address = account.address
  else
    address = account
  end
  return address
end

def convert_address_to_keypair(account)
  if account.is_a?(String)
    keypair = Stellar::KeyPair.from_address(account)
  else
    keypair = account
  end
  #puts "#{keypair}"
  return keypair
end

#Contract(Symbol, Thresholds => Any)
def set_thresholds(account, thresholds)
  set_options account, thresholds: thresholds
end

def set_options(account, args)
  tx = set_options_tx(account, args)
  tx.to_envelope(account)
end

#Contract Symbol, SetOptionsArgs => Any
def set_options_tx(account, args)
  #get_set_stellar_core_network()
  #account = get_account account
  #puts "#{account}  #{args}"
  params = {
    account:  account,
    sequence: next_sequence(account),
  }

  if args[:inflation_dest].present?
    puts "inf: #{args[:inflation_dest]}"
    params[:inflation_dest] = convert_address_to_keypair(args[:inflation_dest])
  end

  if args[:set_flags].present?
    params[:set] = make_account_flags(args[:set_flags])
  end

  if args[:clear_flags].present?
    params[:clear] = make_account_flags(args[:clear_flags])
  end

  if args[:master_weight].present?
    params[:master_weight] = args[:master_weight]
  end

  if args[:thresholds].present?
    params[:low_threshold] = args[:thresholds][:low]
    params[:med_threshold] = args[:thresholds][:medium]
    params[:high_threshold] = args[:thresholds][:high]
  end

  if args[:home_domain].present?
    params[:home_domain] = args[:home_domain]
  end

  if args[:signer].present?
    params[:signer] = args[:signer]
  end

  tx = Stellar::Transaction.set_options(params)
  #tx.to_envelope(account)
end


#Contract Symbol, Stellar::KeyPair, Num => Any
def add_signer(account, key, weight)
  #note to add signers you must have +10 min ballance per signer example 20 normal account 30 min to add one signer
  key = convert_address_to_keypair(key)
  set_options account, signer: Stellar::Signer.new({
    pub_key: key.public_key,
    weight: weight
  })
end

def add_signer_public_key(account, key, weight)
  set_options account, signer: Stellar::Signer.new({
    pub_key: key,
    weight: weight
  })
end

def add_signer_and_weight_manual(target_keypair,add_address,weight_signer,weight_med_high)
  #this will add a signer account with signing weight_signer to the target_keypair account  
  #this function also changes the signing thresholds needed to sign transactions 
  #this function combines both transactions add signer and change account thresholds into one transaction
  #to allow deleting or adding a signer on the fly with only one transaction envelope needing to be signed by the group
  #caution when running this it doesn't do any checks so you can lock up an account permanently
  target_keypair = convert_address_to_keypair(target_keypair)
  add_address = convert_keypair_to_address(add_address)
  signer_info = get_signer_info(target_keypair,add_address)  
  envelope1 = add_signer(target_keypair, add_address,weight_signer)
  envelope2 = set_options(target_keypair, master_weight: 1,thresholds: {low: 0, medium: weight_med_high, high: weight_med_high})
  tx = tx_merge(envelope1.tx,envelope2.tx)
  #puts "tx:  #{tx.inspect}"
  b64 = tx.to_envelope(target_keypair).to_xdr(:base64)
  #puts "b64: #{b64}"
  return b64
end

def delete_signer_weight_adjusted(target_keypair,add_address)
  addsigner_weight_adjusted(target_keypair,add_address,weight = 0)
end

def add_signer_weight_adjusted(target_keypair,add_address,weight = 1)
  #weight of 1 will add a signer and weight of 0 will delete a signer default is to add
  #this function also changes the signing weight needed to sign transactions by +-1 depending on add or delete
  #this function combines both transactions into one to allow deleting a signer on the fly with one transaction signed by the group
  target_keypair = convert_address_to_keypair(target_keypair)
  add_address = convert_keypair_to_address(add_address)
  signer_info = get_signer_info(target_keypair,add_address)
  if !(signer_info.nil?) and (weight == 1)
    puts "signer is already present on this account so can't add, will do nothing"
    return false
  end
  if (signer_info.nil?) and (weight == 0)
    puts "this signer is not presently found on this account so can't delete, will do nothing"
    return false
  end
  if (weight == 0) and signer_info["weight"]!= 1
    puts "added signer weight is not 1 so can't use addsigner_weight_adjusted, must do manualy, will exit nothing done"
    return false
  end
  thresholds = get_thresholds_local(target_keypair)
  puts "thr: #{thresholds}"
  puts "high:  #{thresholds[:high]}"
  if thresholds[:high]>17
    puts "thresholds high is over 17 so you will have to do any changes manualy, nothing will be done"
    return false
  end   
  if (thresholds[:high] != thresholds[:medium]) or (thresholds[:master_weight]!=1)
    puts "threshold high and medium are not presently equal or master not 1, must do add manually, will exit nothing done"
    return false
  end
  if weight > 1 
    weight = 1
  end
  if weight < 0
    weight = 0
  end
  if weight == 0
    if thresholds[:high] < 3
      weight_new = 0
    else
      weight_new = thresholds[:high] - 1
    end
  else
    if thresholds[:high] > 1
      weight_new = thresholds[:high] + 1
    else
      weight_new = 2
    end
  end
  #puts "weight_new:  #{weight_new}"
  return add_signer_and_weight_manual(target_keypair,add_address,weight,weight_new)
end

def get_public_key(keypair)
  keypair.public_key
end

def public_key_to_address(pk)
  Stellar::Util::StrKey.check_encode(:account_id, pk.ed25519!)
end

#Contract Symbol, Stellar::KeyPair => Any
def remove_signer(account, key)
  add_signer account, key, 0
end

#Contract(Symbol, MasterWeightByte => Any)
def set_master_signer_weight(account, weight)
  set_options account, master_weight: weight
end

def env_b64_addsigners(env_b64, *keypair)
  #env_b64 can be base64 envelope or Stellar::envelope structure
  env = b64_to_envelope(env_b64)
  b64 = env.tx.to_envelope(*keypair).to_xdr(:base64)
  return b64
end

def envelope_addsigners(env,tx,*keypair)
  #this is used to add needed keypair signitures to a transaction
  # and combine your added signed tx with someone elses envelope that has signed tx's in it
  # you can add one or more keypairs to the envelope
  #this now obsolete use env_b64_addsigners(env_b64, *keypair) instead or something like it
  # this will later be deleted
  sigs = env.signatures
  envnew = tx.to_envelope(*keypair)
  pos = envnew.signatures.length
  #puts "pos start #{pos}"
  sigs.each do |sig|
    #puts "sig #{sig}"
    envnew.signatures[pos] = sig
    pos = pos + 1
  end
  return envnew
end

def envelope_merge(*envs)
  return env_merge(*envs)
end

def env_merge(*envs)
  #this assumes all envelops have sigs for the same tx
  #this really only merges the signatures in each env not the contents of the envelopes
  #envs can be an arrays of envelops or env_merge(envA,envB,envC)
  #env_array = [envA, envB, envC] ;  newenv = env_merge(env_array)
  #this can be used to collect all the signers of a multi-sign transaction
  #this uses the first array elements envs[0].tx as the transaction to work from
  # the other envelopes we just take there signatures and sign the first elements tx to create a new envelope
  env = envs[0]
  if env.class == Array
    env = env[0]
    envs = envs[0]
  end
  tx = env.tx
  sigs = []
  envs.each do |env|
    s = env.signatures
    if s.length > 1
      s = s[0]
      s = [s]
    end
    sigs.concat(s)
  end 
  envnew = tx.to_envelope()
  pos = 0
  sigs.each do |sig|
    envnew.signatures[pos] = sig
    pos = pos + 1
  end
  return envnew	    
end

def merge_signatures_tx(tx,*sigs)
  #get_set_stellar_core_network()
  #merge an array of signing signatures onto a transaction
  #output is a signed envelope
  #envelope = merge_signatures(tx,sig1,sig2,sig3)
  #array = [sig1,sig2,sig3] ; envelope = merge_signatures(tx,array)
  # todo: make it so tx can be raw tx or envelope with sigs already in it.
  envnew = tx.to_envelope()
  #puts ""
  #puts "envnew.inspect:  #{envnew.inspect}"
  pos = 0
  #puts "sigs.inspect:   #{sigs.inspect}"
  if sigs[0].class == Array
    sigs = sigs[0]
  end
  sigs.each do |sig|
    #puts "sig.inspect:   #{sig.inspect}"
    envnew.signatures[pos] = sig
    pos = pos + 1
  end
  #puts "envnew.sig:   #{envnew.signatures}"
  return envnew	    
end


def hash32(string)
  #a shortened 8 letter base32 SHA256 hash, not likely to be duplicate with small numbers of tx
  # example output "7ZZUMOSZ26"
  Base32.encode(Digest::SHA256.digest(string))[0..7]
end

def send_to_multi_sign_server(hash)
  #this will send the hash created in setup_multi_sig_acc_hash() function to the stellar MSS-server to process
  #puts "hash class: #{hash.class}"
  if hash.nil?
    puts " send hash was nil returning nothingn done"
    return nil
  end
  url = @configs["url_mss_server"]
  puts "url #{url}"
  #puts "sent: #{hash.to_json}"
  result = RestClient.post url, hash.to_json
  #puts "send results: #{result}"
  if result == "null"
    return {"status"=>"return_nil"}
  end
  return JSON.parse(result) 
end

def setup_multi_sig_acc_hash(master_pair,*signers)
  #master_pair is an active funded account, signers is an array of all signers to be included in this multi-signed account that can be address or keypairs
  #the default master_weights will be the number low=0, med=number_of_signers_plus1 high= same_as_med, plus1 means all signers and master must sign before tx valid
  # all master and signer weights will default to 1
  #tx_title will default to the hash32 (8 leters) starting with "A" of hash created 
  #it will return a hash that can be submited to send_to_multi_sign_server function
  create_acc = {"action"=>"create_acc","tx_title"=>"none","master_address"=>"GDZ4AF...","master_seed"=>"SDRES6...", "start_balance"=>100, "signers_total"=>"2", "thresholds"=>{"master_weight"=>"1","low"=>"0","med"=>"2","high"=>"2"},"signers"=>{"GDZ4AF..."=>"1","GDOJM..."=>"1","zzz"=>"1"}}
  signer_count = signers.length
  #puts "sigs: #{signer_count}"
  signers = {}
  signers.each do |row|
    row = convert_keypair_to_address(row)
    signers[row] = 1
  end
  #puts "signers: #{signers}"  
  create_acc["master_address"] = master_pair.address
  create_acc["master_seed"] = master_pair.seed
  create_acc["signers"] = signers
  create_acc["signers_total"] = signer_count + 1
  create_acc["thresholds"]["med"] = signer_count + 1
  create_acc["thresholds"]["high"] = signer_count + 1
  create_acc["thresholds"]["master_weight"] = 1  
  create_acc["tx_title"] = "A_"+hash32(create_acc.to_json)
  return create_acc
end

def setup_multi_sig_tx_hash(tx, master_keypair, signer_keypair=master_keypair)
  #setup a tx_hash that will be sent to send_to_multi_sign_server(tx_hash) to publish a tx to the multi-sign server
  # you have the option to customize the hash after this creates a basic template
  # you can change tx_title, signer_weight, signer_sig_b64, if desired before sending it to the multi-sign-server
  signer_address = convert_keypair_to_address(signer_keypair)
  master_address = convert_keypair_to_address(master_keypair)
  tx_hash = {"action"=>"submit_tx","tx_title"=>"test tx", "signer_address"=>"RUTIWOPF", "signer_weight"=>"1", "master_address"=>"GAJYPMJ...","tx_envelope_b64"=>"AAAA...","signer_sig_b64"=>""}
  tx_hash["signer_address"] = signer_address
  tx_hash["master_address"] = master_address
  envelope = tx.to_envelope(master_keypair)
  puts ""
  puts "envelope: #{envelope.inspect}"
  b64 = envelope_to_b64(envelope)
  tx_hash["tx_title"] = "T_"+envelope_to_txid(b64)[0..7]
  #tx_hash["tx_title"] = "T_"+hash32(b64)
  tx_hash["tx_envelope_b64"] = b64
  return tx_hash
end

def sign_mss_hash(keypair,mss_get_tx_hash,sigmode=0)
  #this will accept a mss_get_tx_hash that was pulled from the  multi-sign-server
  #using the get_tx function to recover the published transaction with a matching tx_code.
  # it will take the b64 encoded transaction from the mss_get_tx_hash 
  #and sign it with this keypair that is assumed to be a valid signer for this transaction.
  #after it signs the transaction it will create a sign_tx action hash to be sent back to the mss-server
  # or it will just send back a b64 encoded decorated signature of the transaction (now default) depending on sigmode
  # after reiceved the server will continue to collect more signatures from other signers until the total signer weight threshold is met,
  #at witch point the multi-sign-server will send the fully signed transaction to the stellar network for validation
  # this function only returns the sig_hash to be sent to send_to_multi_sign_server(sig_hash) to publish a signing of tx_code
  # this sig_hash can be modified before it is sent 
  # example: 
  # sig_hash["tx_title"] = "some cool transaction"
  # sig_hash["signer_weight"] = 2
  # the other values should already be filled in by the function that for the most part should not be changed.
  # in sigmode=1 we disable publishing the tx_envelope_b64 since we no longer need it in V2
  # sigmode=1 will reduce the size of the send packet to the mss-server by a few 100 bytes.  faster? not sure.
  # sigmode=0 we still send both the signature and the signed envelope just for testing for now (and present default).
  puts "mss_get_tx_hash: #{mss_get_tx_hash}" 
  if mss_get_tx_hash["tx_envelope_b64"].nil?
    puts "no records tx_envelope_b64 seen so returning nil"
    return nil
  end
  env = b64_to_envelope(mss_get_tx_hash["tx_envelope_b64"])
  tx = env.tx
  signature = sign_transaction_env(env,keypair)
  envnew = envelope_addsigners(env, tx, keypair)
  tx_envelope_b64 = envelope_to_b64(envnew)
  submit_sig = {"action"=>"sign_tx","tx_title"=>"test tx","tx_code"=>"JIEWFJYE", "signer_address"=>"GAJYGYI...", "signer_weight"=>"1", "tx_envelope_b64"=>"none_provided","signer_sig_b64"=>"JIDYR..."}
  submit_sig["tx_code"] = mss_get_tx_hash["tx_code"]
  submit_sig["tx_title"] = mss_get_tx_hash["tx_code"]
  #sig_b64 = Stellar::Convert.to_base64 signature.to_yaml
  sig_b64 = signature[0].to_xdr(:base64)
  submit_sig["signer_sig_b64"] = sig_b64
  #sig_bytes = Stellar::Convert.from_base64 sig_b64
  #sig_b64 = Stellar::Convert.to_base64 sig_bytes
  if sigmode == 0
    submit_sig["tx_envelope_b64"] = tx_envelope_b64
  end
  submit_sig["signer_address"] = keypair.address
  return submit_sig
end 

def setup_multi_sig_sign_hash(tx_code,keypair,sigmode=0)
  get_tx = {"action"=>"get_tx","tx_code"=>"7ZZUMOSZ26"}
  get_tx["tx_code"] = tx_code
  mss_get_tx_hash = send_to_multi_sign_server(get_tx)
  return sign_mss_hash(keypair,mss_get_tx_hash,sigmode)
end

def setup_multi_sig_sign_hash2(tx_code,keypair,sigmode=0)
  #this is the old version, I had to break the function in half to support websocket. see sign_mss_hash(keypair,mss_get_tx_hash,sigmode=0)
  #this will later be deleted
  #this will search the multi-sign-server for the published transaction with a matching tx_code.
  #if the transaction is found it will get the b64 encoded transaction from the server 
  #and sign it with this keypair that is assumed to be a valid signer for this transaction.
  #after it signs the transaction it will send the signed b64 envelope of the transaction back to the multi-sign-server
  # or it will just send back a b64 encoded decorated signature of the transaction (now default) depending on sigmode
  #the server will continue to collect more signatures from other signers until the total signer weight threshold is met,
  #at witch point the multi-sign-server will send the fully signed transaction to the stellar network for validation
  # this function only returns the sig_hash to be sent to send_to_multi_sign_server(sig_hash) to publish signing of tx_code
  # this sig_hash can be modified before it is sent 
  # example: 
  # sig_hash["tx_title"] = "some cool transaction"
  # sig_hash["signer_weight"] = 2
  # the other values should already be filled in by the function that for the most part should not be changed.
  # in sigmode=1 we disable publishing the tx_envelope_b64 since we no longer need it in V2
  # sigmode=1 will reduce the size of the send packet to the mss-server by a few 100 bytes.  faster? not sure.
  # sigmode=0 we still send both the signature and the signed envelope just for testing for now (and present default).

  #this action get_tx when sent to the mss-server will returns the master created transaction with added info,  
  #{"tx_num"=>1, "signer"=>0, "tx_code"=>"7ZZUMOSZ26", "tx_title"=>"test multi sig tx", "signer_address"=>"", "signer_weight"=>"", "master_address"=>"GDZ4AFAB...", "tx_envelope_b64"=>"AAAA...","signer_sig_b64"=>"URYE..."}
  get_tx = {"action"=>"get_tx","tx_code"=>"7ZZUMOSZ26"}
  get_tx["tx_code"] = tx_code
  result = send_to_multi_sign_server(get_tx)
  puts "mss result: #{result}"
  puts "env_b64: #{result["tx_envelope_b64"]}"
  env = b64_to_envelope(result["tx_envelope_b64"])
  if result["signer_sig_b64"].nil?
    puts "records returned for txcode #{tx_code}"
    return nil
  end
  tx = env.tx
  signature = sign_transaction_env(env,keypair)
  envnew = envelope_addsigners(env, tx, keypair)
  tx_envelope_b64 = envelope_to_b64(envnew)
  submit_sig = {"action"=>"sign_tx","tx_title"=>"test tx","tx_code"=>"JIEWFJYE", "signer_address"=>"GAJYGYI...", "signer_weight"=>"1", "tx_envelope_b64"=>"none_provided","signer_sig_b64"=>"JIDYR..."}
  submit_sig["tx_code"] = tx_code
  submit_sig["tx_title"] = tx_code
  #sig_b64 = Stellar::Convert.to_base64 signature.to_yaml
  sig_b64 = signature[0].to_xdr(:base64)
  submit_sig["signer_sig_b64"] = sig_b64
  #sig_bytes = Stellar::Convert.from_base64 sig_b64
  #sig_b64 = Stellar::Convert.to_base64 sig_bytes
  if sigmode == 0
    submit_sig["tx_envelope_b64"] = tx_envelope_b64
  end
  submit_sig["signer_address"] = keypair.address
  return submit_sig
end 

def create_account_from_acc_hash(acc_hash, funder = nil)
  #note this is no longer fully tested to work with new added changes, I don't think it's needed
  #this will create a b64 formated transaction from the standard formated acc_hash 
  #see acc_hash = setup_multi_sig_acc_hash(master_pair,*signers) for more details
  # if funder keypair is provided we will fund the master_seed account in the acc_hash with it  
  if funder.nil?
    #no funder was provided so see if master_seed is valid seed length
    if acc_hash["master_seed"].nil?
      puts "no master_seed to do transaction from here"
      return "no funds"
    end
    if acc_hash["master_seed"].length == 56
      #it looks valid so we will assume here that the master_seed is a funded account
      # so we will use it to change the thresholds on the account
      to_pair = Stellar::KeyPair.from_seed(acc_hash["master_seed"])
      bal = get_native_balance(to_pair)
      # lets see if the master_seed is really funded
      if bal < 30        
        #nope not enuf funds so nothing we can do here but return and do nothing
        puts "not enuf funds provided to make changes to thresholds, will do nothing"
        return "no funds"
      end
    else
      #nope not a valid master_seed address so we will do nothing but add to mss db
      puts "master_seed not valid so assume account already created on stellar network"
      puts "will do nothing but add this account to the mss server db"
      return "no funds"
    end
  else
    #the funder keypair is present so will use it to create and fund a new to_pair account
    puts "have funder, will create new account with it starting bal: #{acc_hash["start_balance"]}" 
    to_pair = Stellar::KeyPair.from_seed(acc_hash["master_seed"])
    puts "funder.seed:  #{funder.seed}"
    puts "funder.address:  #{funder.address}"
    puts "to_pair.seed:  #{to_pair.seed}"
    puts "to_pair.address:  #{to_pair.address}"
    result = create_account(to_pair, funder, acc_hash["start_balance"])
    puts "res create_account:  #{result}"  
  end
  tx = [] 
  signers = acc_hash["signers"]
  puts "to_pair:  #{to_pair.address}"
  pos = 0
  signers.each do |ad, acc, wt|
    puts "acc:#{acc}  wt:#{wt}"
    keypair = Stellar::KeyPair.from_address(acc)
    public_key = keypair.public_key
    env = add_signer_public_key(to_pair, public_key, wt.to_i)
    tx[pos] = env.tx
    pos = pos + 1
  end
  #puts "tx: #{tx[0].inspect}"  
  th = acc_hash["thresholds"]
  env = set_thresholds(to_pair, master_weight: th[:master_weight].to_i, low: th[:low].to_i, medium: th[:medium].to_i, high: th[:high].to_i)
  tx[pos] = env.tx
  puts "tx.length:  #{tx.length}"
  tx_new = tx_merge(tx)
  env_new = tx_to_envelope(to_pair,tx_new)
  b64 = envelope_to_b64(env_new)
  #send_tx(b64) 
end

def sign_transaction_tx(tx,keypair)
  #return a signature for a transaction
  #signature = sign_transaction(tx,keypair)
  # todo: make it so tx can be a raw tx or an envelope that already has some sigs in it.
  # just depending on the class of tx
  envelope = tx.to_envelope(keypair)
  sig = envelope.signatures
  if sig.length > 1
    sig = sig[0]
    sig = [sig]
  end
  return sig
end

def sign_transaction_env(env,keypair)
  #return a signature for a transaction
  #signature = sign_transaction(tx,keypair)
  # todo: make it so tx can be a raw tx or an envelope that already has some sigs in it.
  # just depending on the class of tx
  tx = env.tx
  sign_transaction_tx(tx,keypair)
end

def decode_error(b64)
  bytes = Stellar::Convert.from_base64(b64)
  # decode to the in-memory TransactionResult
  tr = Stellar::TransactionResult.from_xdr bytes
  # the actual code is embedded in the "result" field of the 
  # TransactionResult.
  puts "#{tr.result.code}"
  return tr.result.code
end

def decode_thresholds_b64(b64)
  #convert threshold values found in stellar-core db accounts threshold example "AQADAw=="
  #to a more human readable format of: {:master_weight=>1, :low=>0, :medium=>3, :high=>3}
  begin
    bytes = Stellar::Convert.from_base64 b64
  rescue
    return {"error"=>"bad  decode_threshold_b64"}
  end
  result = Stellar::Thresholds.parse bytes
  #puts "res.inpsect:  #{result.inspect}"
end

def decode_txbody_b64(b64)
  #this can be used to view what is inside of a stellar db txhistory txbody in a more human readable format than b64
  #example data seen 
  #b64 = 'AAAAAGXNhLrhGtltTwCpmqlarh7s1DB2hIkbP//jgzn4Fos/AAAACgAAACEAAAGwAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAPsbtuH+tyUkMFS7Jglb5xLEpSxGGW0dn/Ryb1K60u4IAAAAXSHboAAAAAAAAAAAB+BaLPwAAAEDmsy29BbAv/oXdKMTYTKFiqPTKgMO0lpzBTJSaH5ZT2LFdpIT+fWnOjknlRlmXwazn0IaV8nlokS4ETTPPqgEK'

  #example output:
  #tx.inpect #<Stellar::Transaction:0x0000000317cb60 @attributes={:source_account=>#<Stellar::PublicKey:0x0000000317c110 @switch=Stellar::CryptoKeyType.key_type_ed25519(0), @arm=:ed25519, @value="e\xCD\x84\xBA\xE1\x1A\xD9mO\x00\xA9\x9A\xA9Z\xAE\x1E\xEC\xD40v\x84\x89\e?\xFF\xE3\x839\xF8\x16\x8B?">, :fee=>100, :seq_num=>141733921200, :time_bounds=>nil, :memo=>#<Stellar::Memo:0x00000003094fe0 @switch=Stellar::MemoType.memo_none(0), @arm=nil, @value=:void>, :operations=>[#<Stellar::Operation:0x00000003094950 @attributes={:source_account=>nil, :body=>#<Stellar::Operation::Body:0x00000003093a78 @switch=Stellar::OperationType.create_account(0), @arm=:create_account_op, @value=#<Stellar::CreateAccountOp:0x00000003094220 @attributes={:destination=>#<Stellar::PublicKey:0x00000003093cf8 @switch=Stellar::CryptoKeyType.key_type_ed25519(0), @arm=:ed25519, @value=">\xC6\xED\xB8\x7F\xAD\xC9I\f\x15.\xC9\x82V\xF9\xC4\xB1)K\x11\x86[Gg\xFD\x1C\x9B\xD4\xAE\xB4\xBB\x82">, :starting_balance=>100000000000}>>}>], :ext=>#<Stellar::Transaction::Ext:0x00000003093668 @switch=0, @arm=nil, @value=:void>}>

  env = b64_to_envelope(b64)
  tx = env.tx
  puts "tx class #{tx.class}"
  # inspect is what we wanted
  puts "tx.inpect #{tx.inspect}"
  return tx.inspect
end

def decode_txresult_b64(b64)
  #this can be used to view what is inside of a stellar db txhistory txresult in a more human readable format than b64
  #TransactionResultPair 
  #b64 = '3E2ToLG5246Hu+cyMqanBh0b0aCON/JPOHi8LW68gZYAAAAAAAAACgAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAA=='

  #example out:
  #tranPair.inspect:  #<Stellar::TransactionResultPair:0x00000001816ae0 @attributes={:transaction_hash=>"\xDCM\x93\xA0\xB1\xB9\xDB\x8E\x87\xBB\xE722\xA6\xA7\x06\x1D\e\xD1\xA0\x8E7\xF2O8x\xBC-n\xBC\x81\x96", :result=>#<Stellar::TransactionResult:0x00000001816180 @attributes={:fee_charged=>100, :result=>#<Stellar::TransactionResult::Result:0x0000000170fbb0 @switch=Stellar::TransactionResultCode.tx_success(0), @arm=:results, @value=[#<Stellar::OperationResult:0x0000000170fc00 @switch=Stellar::OperationResultCode.op_inner(0), @arm=:tr, @value=#<Stellar::OperationResult::Tr:0x0000000170fca0 @switch=Stellar::OperationType.create_account(0), @arm=:create_account_result, @value=#<Stellar::CreateAccountResult:0x0000000170fcf0 @switch=Stellar::CreateAccountResultCode.create_account_success(0), @arm=nil, @value=:void>>>]>, :ext=>#<Stellar::TransactionResult::Ext:0x0000000170f868 @switch=0, @arm=nil, @value=:void>}>}>
#<Stellar::TransactionResultPair:0x00000001816ae0 @attributes={:transaction_hash=>"\xDCM\x93\xA0\xB1\xB9\xDB\x8E\x87\xBB\xE722\xA6\xA7\x06\x1D\e\xD1\xA0\x8E7\xF2O8x\xBC-n\xBC\x81\x96", :result=>#<Stellar::TransactionResult:0x00000001816180 @attributes={:fee_charged=>100, :result=>#<Stellar::TransactionResult::Result:0x0000000170fbb0 @switch=Stellar::TransactionResultCode.tx_success(0), @arm=:results, @value=[#<Stellar::OperationResult:0x0000000170fc00 @switch=Stellar::OperationResultCode.op_inner(0), @arm=:tr, @value=#<Stellar::OperationResult::Tr:0x0000000170fca0 @switch=Stellar::OperationType.create_account(0), @arm=:create_account_result, @value=#<Stellar::CreateAccountResult:0x0000000170fcf0 @switch=Stellar::CreateAccountResultCode.create_account_success(0), @arm=nil, @value=:void>>>]>, :ext=>#<Stellar::TransactionResult::Ext:0x0000000170f868 @switch=0, @arm=nil, @value=:void>}>}>

  bytes = Stellar::Convert.from_base64 b64
  tranPair = Stellar::TransactionResultPair.from_xdr bytes
  puts "tranPair.inspect:  #{tranPair.inspect}"
  return tranPair.inspect
end

def decode_txmeta_b64(b64)
   #converts the data found in stellar-core db in txtransactions  txmeta colum into more human readable content
   #example output:  res:  #<Stellar::TransactionMeta:0x00000002c821f0 @switch=0, @arm=:v0, @value=#<Stellar::TransactionMeta::V0:0x00000002c74aa0 @attributes={:changes=>[#<Stellar::LedgerEntryChange:0x00000002c773e0 @switch=Stellar::LedgerEntryChangeType.ledger_entry_updated(1), @arm=:updated, @value=#<Stellar::LedgerEntry:0x00000002c74730 @attributes={:last_modified_ledger_seq=>164045, :data=>#<Stellar::LedgerEntry::Data:0x00000002c77638 @switch=Stellar::LedgerEntryType.account(0), @arm=:account, @value=#<Stellar::AccountEntry:0x00000002c74410 @attributes={:account_id=>#<Stellar::PublicKey:0x00000002c741e0 @switch=Stellar::CryptoKeyType.key_type_ed25519(0), @arm=:ed25519, @value="e\xCD\x84\xBA\xE1\x1A\xD9mO\x00\xA9\x9A\xA9Z\xAE\x1E\xEC\xD40v\x84\x89\e?\xFF\xE3\x839\xF8\x16\x8B?">, :balance=>82874009994550, :seq_num=>141733921313, :num_sub_entries=>0, :inflation_dest=>nil, :flags=>0, :home_domain=>"", :thresholds=>"\x01\x00\x00\x00", :signers=>[], :ext=>#<Stellar::AccountEntry::Ext:0x00000002c77700 @switch=0, @arm=nil, @value=:void>}>>, :ext=>#<Stellar::LedgerEntry::Ext:0x00000002c77408 @switch=0, @arm=nil, @value=:void>}>>], :operations=>[#<Stellar::OperationMeta:0x00000002c77200 @attributes={:changes=>[#<Stellar::LedgerEntryChange:0x00000002c7c890 @switch=Stellar::LedgerEntryChangeType.ledger_entry_created(0), @arm=:created, @value=#<Stellar::LedgerEntry:0x00000002c76f08 @attributes={:last_modified_ledger_seq=>164045, :data=>#<Stellar::LedgerEntry::Data:0x00000002c7cae8 @switch=Stellar::LedgerEntryType.account(0), @arm=:account, @value=#<Stellar::AccountEntry:0x00000002c7e8e8 @attributes={:account_id=>#<Stellar::PublicKey:0x00000002c7e398 @switch=Stellar::CryptoKeyType.key_type_ed25519(0), @arm=:ed25519, @value="B\xCF\x05Yy\x0Fl;d\xDE\x15\x12\r\xF0\xBB%\xCA\xAB}\xC2\xDBO\xB4\xA1\x8A5\xE8\x81\xBF2:\xF7">, :balance=>100000000000, :seq_num=>704567910072320, :num_sub_entries=>0, :inflation_dest=>nil, :flags=>0, :home_domain=>"", :thresholds=>"\x01\x00\x00\x00", :signers=>[], :ext=>#<Stellar::AccountEntry::Ext:0x00000002c7cb88 @switch=0, @arm=nil, @value=:void>}>>, :ext=>#<Stellar::LedgerEntry::Ext:0x00000002c7c8e0 @switch=0, @arm=nil, @value=:void>}>>, #<Stellar::LedgerEntryChange:0x00000002c82358 @switch=Stellar::LedgerEntryChangeType.ledger_entry_updated(1), @arm=:updated, @value=#<Stellar::LedgerEntry:0x00000002c7c6b0 @attributes={:last_modified_ledger_seq=>164045, :data=>#<Stellar::LedgerEntry::Data:0x00000002c82650 @switch=Stellar::LedgerEntryType.account(0), @arm=:account, @value=#<Stellar::AccountEntry:0x00000002c7c098 @attributes={:account_id=>#<Stellar::PublicKey:0x00000002c7bcd8 @switch=Stellar::CryptoKeyType.key_type_ed25519(0), @arm=:ed25519, @value="e\xCD\x84\xBA\xE1\x1A\xD9mO\x00\xA9\x9A\xA9Z\xAE\x1E\xEC\xD40v\x84\x89\e?\xFF\xE3\x839\xF8\x16\x8B?">, :balance=>82774009994550, :seq_num=>141733921313, :num_sub_entries=>0, :inflation_dest=>nil, :flags=>0, :home_domain=>"", :thresholds=>"\x01\x00\x00\x00", :signers=>[], :ext=>#<Stellar::AccountEntry::Ext:0x00000002c826a0 @switch=0, @arm=nil, @value=:void>}>>, :ext=>#<Stellar::LedgerEntry::Ext:0x00000002c823a8 @switch=0, @arm=nil, @value=:void>}>>]}>]}>>

  result = Stellar::TransactionMeta.from_xdr Stellar::Convert.from_base64 b64
  puts "res:  #{result.inspect}"
  return result
end


def compare_hash(hash1, hash2)
  if (hash2.size > hash1.size)
    difference = hash2.to_a - hash1.to_a
  else
    difference = hash1.to_a - hash2.to_a
  end
  Hash[*difference.flatten]
end

def compare_env_with_hash(envelope_b64,hash_template)
  #this will compare the values of a hash_template with an envelopes values
  #with it's values being in a base64 xdr encoded transaction envelope format.
  # the template can be created with the envelope_to_hash(envelope_b64) function using 
  # a similar transaction input to the function to create it
  # the hash can then be modified to have the desired changes that should match if correct and return 0.
  # a return of a positive integer indicates the number of differences found.
  #this function will also compensate for the difference in sequence number 
  # of the new transaction
  new_hash = envelope_to_hash(envelope_b64)
  hash_template["seq_num"] = next_sequence(new_hash["source_address"])
  diff = compare_hash(new_hash, hash_template)
  diff_len = diff.length
  if diff.length > 0
    puts "diff:  #{diff}"
  end
  return diff.length
end

def make_witness_hash(witness_keypair,account,timebound,asset="",issuer="")
  account = convert_keypair_to_address(account)
  witness_account = convert_keypair_to_address(witness_keypair)
  acc_info = get_accounts_local(account)
  if asset != "" or !(asset.nil?)
    lines = get_trustlines_local(account,issuer,asset)
  end
  thresholds = get_thresholds_local(account)
  signer_info = get_signer_info(account,signer_address="")
  timestamp = Time.now.to_i.to_s
  hash = {"acc_info"=>acc_info, "thresholds"=>thresholds, "signer_info"=>signer_info,"timebound"=>timebound,"timestamp"=>timestamp, "witness_account"=>witness_account}
  if !(lines.nil?) 
    hash["trustlines"] = [lines]
  end
  json_string = hash.to_json  
  sig = sign_msg(json_string, witness_keypair)
  hash["signature"] = sig
  return hash
end
#returns: 
#{"acc_info"=>{"accountid"=>"GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO", "balance"=>1219999700, "seqnum"=>11901354377218, "numsubentries"=>1, "inflationdest"=>nil, "homedomain"=>"test.timebonds2", "thresholds"=>"AQAAAA==", "flags"=>0, "lastmodified"=>7867}, "balance"=>0, "thresholds"=>{:master_weight=>1, :low=>0, :medium=>0, :high=>0}, "signer_info"=>{"signers"=>[{"accountid"=>"GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO", "publickey"=>"GBT6G2KZI4ON3LTVRWEPT3GH66TTBTN77SIHRGNQ4KAU7N3GTFLYXYOM", "weight"=>1}]}, "timestamp"=>"1444386782", "signed_json"=>"{\"acc_info\":{\"accountid\":\"GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO\",\"balance\":1219999700,\"seqnum\":11901354377218,\"numsubentries\":1,\"inflationdest\":null,\"homedomain\":\"test.timebonds2\",\"thresholds\":\"AQAAAA==\",\"flags\":0,\"lastmodified\":7867},\"balance\":0,\"thresholds\":{\"master_weight\":1,\"low\":0,\"medium\":0,\"high\":0},\"signer_info\":{\"signers\":[{\"accountid\":\"GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO\",\"publickey\":\"GBT6G2KZI4ON3LTVRWEPT3GH66TTBTN77SIHRGNQ4KAU7N3GTFLYXYOM\",\"weight\":1}]},\"timestamp\":\"1444386782\"}", "signature"=>"O+WxDbyjk1xD4R/J2LoSjR2LIsnLBQPoHnPIuafPCUcB1wp0FIiyjURNTu9B\nfYAU6+Ug7KKMWM/ogPR4HeMECg==\n"}

def check_witness_hash(hash)
  #this will check that the witness signing of the hash is valid
  #the witness_account is a stellar pubic account number of who signed the hash in the
  #the function make_witness_hash above. the hash is also timestamped to prove the accountid
  # seen in the hash was in this state at this witnessed time. 
  sig_hash = hash["signature"]
  if !(hash["signed_json"].nil?)
    hash.delete("signed_json")
  end
  hash.delete("signature")
  json_string = hash.to_json
  puts "json_string: #{json_string}" 
  verify_signed_msg(json_string, hash["witness_account"], sig_hash)
end


def envelope_to_hash(envelope_b64)
  #envelope_b64 can be base64 format or stellar::envelope structure
  #this will breakdown an envelope into a human readable and ruby workable format of hash
  #at this time it doesn't support all stellar transaction types, just the ones I had been using at the time.
  if envelope_b64.class == String
    env = b64_to_envelope(envelope_b64)
  else
    env = envelope_b64
  end
  hash = {} 
  begin
    tx = env.tx 
  rescue
    return hash = {"status"=>"error", "error"=>"bad_envelope"}
  end
  pk = tx.source_account
  hash["source_address"] = public_key_to_address(pk)
  hash["fee"] = tx.fee
  hash["seq_num"] = tx.seq_num
  #hash["time_bounds"] = tx.time_bounds
  if !(tx.time_bounds.nil?)
    hash["time_bounds_max_time"] = tx.time_bounds.max_time
    hash["time_bounds_min_time"] = tx.time_bounds.min_time
  end
  if tx.memo.type == Stellar::MemoType.memo_none()   
    hash["memo_type"] = "memo_none"
  else
    hash["memo_type"] = Stellar::MemoType.memo_none()
  end
  if tx.memo.type == Stellar::MemoType.memo_id()
    puts "memo_type: memo_id"
    hash["memo_type"] = "memo_id"
    hash["memo_id"] = tx.memo.value
    hash["memo_value"] = tx.memo.value.to_s
    puts "memo.id: #{tx.memo.value}"
  end
  if tx.memo.type == Stellar::MemoType.memo_text()   
    hash["memo_type"] = "memo_text"
    #puts "tx.memo: #{tx.memo.inspect}"
    s = tx.memo.value
    s.delete!("^\u{0000}-\u{007F}")
    hash["memo_text"] = s
    hash["memo_value"] = s
    #hash["memo.text"] = tx.memo.text
  end  
  # seems we can have more than one operation per tx but I've only ever sent one at a time before
  # but now I need to iterate over multi operations
  hash["op_length"] = tx.operations.length
  opnum = 0
  hash["operations"] = []
  tx.operations.each do |op|
    hash["operations"][opnum] = {}
    hash["operations"][opnum]["operation"] = op.body.arm
    case op.body.arm
    when :payment_op   
      hash["operations"][opnum]["destination_address"] = public_key_to_address(op.body.value.destination)
      if op.body.value.asset.to_s == "native"   
        hash["operations"][opnum]["asset"] = "native"
      else
        hash["operations"][opnum]["asset"] = op.body.value.asset.code
        hash["operations"][opnum]["issuer"] = public_key_to_address(op.body.value.asset.issuer)
      end
      hash["operations"][opnum]["amount"] = (op.body.value.amount)/1e7
    when :set_options_op 
      hash["operations"][opnum]["inflation_dest"] = op.body.value.inflation_dest
      hash["operations"][opnum]["clear_flags"] = op.body.value.clear_flags
      hash["operations"][opnum]["set_flags"] = op.body.value.set_flags
      hash["operations"][opnum]["master_weight"] = op.body.value.master_weight
      hash["operations"][opnum]["low_threshold"] = op.body.value.low_threshold
      hash["operations"][opnum]["med_threshold"] = op.body.value.med_threshold
      hash["operations"][opnum]["high_threshold"] = op.body.value.high_threshold
      hash["operations"][opnum]["home_domain"] = op.body.value.home_domain
      if !(op.body.value.signer.nil?)
        hash["operations"][opnum]["signer_key_address"] = Stellar::Convert.pk_to_address(op.body.value.signer.pub_key)
        hash["operations"][opnum]["signer_weight"] = op.body.value.signer.weight
      end
    when :change_trust_op
      hash["operations"][opnum]["line"] = op.body.value.line
      hash["operations"][opnum]["limit"] = op.body.value.limit
    when :create_account_op
      hash["operations"][opnum]["destination_address"] = public_key_to_address(op.body.value.destination)
      hash["operations"][opnum]["starting_balance"] = (op.body.value.starting_balance)/1e7
    when :manage_offer_op
      if op.body.value.selling.to_s == "native"
        hash["operations"][opnum]["selling.asset"] = "native"
      else
        hash["operations"][opnum]["selling.asset"] = op.body.value.selling.code
        hash["operations"][opnum]["selling.issuer"] = public_key_to_address(op.body.value.selling.issuer)
      end
      if op.body.value.buying.to_s == "native"
        hash["operations"][opnum]["buying.asset"] = "native"
      else
        begin
          hash["operations"][opnum]["buying.asset"] = op.body.value.buying.code
          hash["operations"][opnum]["buying.issuer"] = public_key_to_address(op.body.value.buying.issuer)
        rescue
          hash["operations"][opnum]["buying.asset"] = "error"
        end
      end
      hash["operations"][opnum]["amount"] = (op.body.value.amount)/1e7
      hash["operations"][opnum]["price"] = op.body.value.price
      hash["operations"][opnum]["offer_id"] = op.body.value.offer_id   
    else 
      puts "operation not recognized #{op.body.arm}"
    end
    opnum = opnum + 1
  end
  return hash
end

def view_envelope(envelope_b64)
  #this is the same as envelope_to_hash(envelope_b64) above with just added prints statments added
  #at some point we might delete this as I don't want to maintain both. this was used in original design for debuging.
  #I still like the output format that I'm now used to so didn't delete it yet.
  #this needs to be rewriten to use envelope_to_hash as it's source
  env = b64_to_envelope(envelope_b64)
  siglist = env_signature_info(env)
  puts "siglist: #{siglist}"
  hash = {}
  #puts "env.inspect:  #{env.inspect}"
  #puts ""
  tx = env.tx
  #puts "tx.inspect:  #{tx.inspect}"
  #puts ""
  #puts "tx.source_account:  #{tx.source_account}"
  pk = tx.source_account
  puts "source_address:  #{public_key_to_address(pk)}"
  hash["source_address"] = public_key_to_address(pk)
  #sa = tx.source_account
  puts "tx.fee:  #{tx.fee}"
  hash["fee"] = tx.fee
  puts "tx.seq_num:  #{tx.seq_num}"
  hash["seq_num"] = tx.seq_num
  #puts "tx.time_bounds:  #{tx.time_bounds}"
  if !(tx.time_bounds.nil?)
    puts "Time.now.to_i: #{Time.now.to_i}"
    puts "time_bounds_min: #{tx.time_bounds.min_time}"
    puts "time_bounds_max: #{tx.time_bounds.max_time}"
    hash["time_bounds_max_time"] = tx.time_bounds.max_time
    hash["time_bounds_min_time"] = tx.time_bounds.min_time
  else
    puts "time_bounds: nil"
  end
  begin
  puts "tx.memo.type: #{tx.memo.type}"
  puts "tx.memo.type.inspect: #{tx.memo.type.inspect}"
  
  if tx.memo.type == Stellar::MemoType.memo_none()
    puts "memo.type:  memo_none"
    hash["memo.type"] = "memo_none"
  end  
  if tx.memo.type == Stellar::MemoType.memo_id()
    puts "memo.type: memo_id"
    hash["memo.type"] = "memo_id"
    hash["memo_id"] = tx.memo.value
    puts "memo.id: #{tx.memo.value}"
  end
  if tx.memo.type == Stellar::MemoType.memo_text()
    puts "tx.memo: #{tx.memo}"
    puts "memo_txt:  #{tx.memo.value}"
    hash["memo.type"] = "memo_text"
    hash["memo.text"] = tx.memo.value
  end
  rescue
    hash["memo.type"] = "bad_memo_contents"
  end
  puts "tx.ext:  #{tx.ext}"
  #puts "tx.operations:  #{tx.operations}"
  # seems we can have more than one operation per tx but I've only ever sent one at a time
  puts "tx.op.length:  #{tx.operations.length}"
  hash["op_length"] = tx.operations.length
  opnum = 0
  tx.operations.each do |op|
    puts ""
    puts "operation_type:  #{op.body.arm}"
    puts "oper_type: #{op.body.arm} opnum #{opnum}"
  
    hash["operation"] = op.body.arm
    case op.body.arm
    when :payment_op
      #puts "tx.op.body.value.destination #{op.body.value.destination}"
      puts "destination_address:  #{public_key_to_address(op.body.value.destination)}"
      hash["destination_address"] = public_key_to_address(op.body.value.destination)
      #puts "asset.class:  #{op.body.value.asset.class}"
      if op.body.value.asset.to_s == "native"
        puts "asset:  #{op.body.value.asset}"
        hash["asset"] = "native"
      else
        puts "asset:  #{op.body.value.asset.code}"
        puts "issuer:  #{public_key_to_address(op.body.value.asset.issuer)}"
        hash["asset"] = op.body.value.asset.code
        hash["issuer"] = public_key_to_address(op.body.value.asset.issuer)
      end
      puts "amount: #{(op.body.value.amount)/1e7}"
      hash["amount"] = (op.body.value.amount)/1e7
    when :set_options_op 
      puts "inflation_dest: #{op.body.value.inflation_dest}"
      hash["inflation_dest"] = op.body.value.inflation_dest
      puts "clear_flags:    #{op.body.value.clear_flags}"
      hash["clear_flags"] = op.body.value.clear_flags
      puts "set_flags:      #{op.body.value.set_flags}"
      hash["set_flags"] = op.body.value.set_flags
      #puts "body.value:  #{op.body.value.inspect}"
      puts "master_weight:  #{op.body.value.master_weight}"
      hash["master_weight"] = op.body.value.master_weight
      puts "low_threshold:  #{op.body.value.low_threshold}"
      hash["low_threshold"] = op.body.value.low_threshold
      puts "med_threshold:  #{op.body.value.med_threshold}"
      hash["med_threshold"] = op.body.value.med_threshold
      puts "high_threshold: #{op.body.value.high_threshold}"
      hash["high_threshold"] = op.body.value.high_threshold
      puts "home_domain:    #{op.body.value.home_domain}"
      hash["home_domain"] = op.body.value.home_domain
      if !(op.body.value.signer.nil?)
        puts "signer_key:  #{Stellar::Convert.pk_to_address(op.body.value.signer.pub_key)}"
        hash["signer_key_address"] = Stellar::Convert.pk_to_address(op.body.value.signer.pub_key)
        hash["signer_weight"] = op.body.value.signer.weight
        puts "signer_weight #{op.body.value.signer.weight}"
      else
        puts "signer:"
      end
    when :change_trust_op
      puts "line:   #{op.body.value.line}"
      hash["line"] = op.body.value.line
      puts "limit:  #{op.body.value.limit}"
      hash["limit"] = op.body.value.limit
    when :create_account_op
      puts "destination_address:  #{public_key_to_address(op.body.value.destination)}"
      hash["destination_address"] = public_key_to_address(op.body.value.destination)
      puts "starting_balance:     #{(op.body.value.starting_balance)/1e7}"
      hash["starting_balance"] = (op.body.value.starting_balance)/1e7
    when :manage_offer_op
      if op.body.value.selling.to_s == "native"
        puts "selling.asset:  native"
        hash["selling.asset"] = "native"
      else
        puts "selling.asset:  #{op.body.value.selling.code}"
        puts "selling.issuer:  #{public_key_to_address(op.body.value.selling.issuer)}"
        hash["selling.asset"] = op.body.value.selling.code
        hash["selling.issuer"] = public_key_to_address(op.body.value.selling.issuer)
      end
      if op.body.value.buying.to_s == "native"
        puts "buying.asset:  #{op.body.value.asset}"
        hash["buying.asset"] = "native"
      else
        puts "buying.asset:  #{op.body.value.buying.code}"
        puts "buying.issuer:  #{public_key_to_address(op.body.value.buying.issuer)}"
        hash["buying.asset"] = op.body.value.selling.code
        hash["buying.issuer"] = public_key_to_address(op.body.value.selling.issuer)
      end
      puts "amount:    #{(op.body.value.amount)/1e7}"
      hash["amount"] = (op.body.value.amount)/1e7
      puts "price:     #{op.body.value.price}"
      hash["price"] = op.body.value.price
      puts "offer_id:  #{op.body.value.offer_id}"
      hash["offer_id"] = op.body.value.offer_id   
    else 
      puts "operation not recognized #{op.body.arm}"
    end
    opnum = opnum + 1
  end
  return hash
end

def envelope_to_txid(env_base64)
  #this will convert a b64 envelope into a txid as seen in txhistory 
  #records in stellar database,  that can be used in database search
  # to recover any txhistory records there contained.
  begin 
    env_raw = Stellar::Convert.from_base64(env_base64)
  rescue 
    return "bad_base64"
  end
  begin
    env = Stellar::TransactionEnvelope.from_xdr(env_raw)
  rescue
    return "bad_env_raw"
  end
  hash_raw = env.tx.hash
  hash_hex = Stellar::Convert.to_hex hash_raw
  hash_hex
end

def verify_signature(envelope, address, sig_b64="")
  #if sig_b64 provided verify this sig matches as valid on this address on the tx found in this envelope 
  #if no sig_b64 provided then see if this address matches any signature now found in the envelope
  #envelope can be in base64 xdr string or TransactionEnvelope structure format
  #address can be an address or keypair with no secreet seed needed
  # sig_b64 is optional and can be a b64 encoded decorated signature that will be used instead of what
  # signatures are presently found in the envelope.
  # returns true if valid sig found or false if not
  if envelope.class == String
    bytes = Stellar::Convert.from_base64 envelope
    envelope = Stellar::TransactionEnvelope.from_xdr bytes
  end
  keypair = convert_address_to_keypair(address)
  puts "sig_b64: #{sig_b64}"
  puts "sig_b64.class: #{sig_b64.class}"
  if sig_b64 == ""
    puts "sig_b64: #{sig_b64}" 
    #sig = envelope.signatures.first.signature
    hash = Digest::SHA256.digest(envelope.tx.signature_base)
    envelope.signatures.each do |dsig|    
      sig = dsig.signature     
      if keypair.verify(sig,hash)
        return true
      end
    end
    return false
  else 
    #sig_b64 = signature[0].to_xdr(:base64)
    bytes = Stellar::Convert.from_base64(sig_b64)
    dsig = Stellar::DecoratedSignature.from_xdr bytes
    sig = dsig.signature
    hash = Digest::SHA256.digest(envelope.tx.signature_base)
    result = keypair.verify(sig,hash)
    puts "result verify: #{result}"
    return result
  end  
end

def push_sig(envelope,keypair)
  #this puts the added key signature from keypair to the first position in signatures array of the returned envelope
  #instead of adding it to the end, this might be needed if your adding the source_address signature to the envelope
  # that already has a signature of one of the needed signers in it.
  # after testing I'm not thinking it maters what order the signatures are in, they seem to work in any order
  # so this function is not really needed
  #envelope can be b64 or Stellar::envelope structure
  #returns a signed b64 envelope
  envelope = b64_to_envelope(envelope)
  tx = envelope.tx
  env2 = tx.to_envelope(keypair)
  new_sig = env2.signatures
  puts "new_sig: #{new_sig.inspect}"
  puts ""
  #if you want the signature at the end of the array you can push it
  #envelope.signatures.push(*env2.signatures)
  #this puts it at the fist position
  envelope.signatures.unshift(*env2.signatures)   
  puts "envelope.signatures #{envelope.signatures}"
  return envelope.to_xdr(:base64)
end

def env_signature_info(envelope)
  #output an array of key addresses that have valid signatures on this envelope
  #envelope can be in ether b64 or Stellar::envelope structure format
  #this is just a tool to analize the state of the present signatures in the envelope
  #it returns an array of the present valid signer addresses present and prints a count.
  envelope = b64_to_envelope(envelope)
  puts "sig.count:  #{envelope.signatures.length}"
  hash = envelope_to_hash(envelope)
  sigs = envelope.signatures
  #sig_b64 = sigs[0].to_xdr(:base64)
  #check = verify_signature(envelope, hash["source_address"], sig_b64)
  #puts "check sig0 to source_address: #{check}"
  source = {"accountid"=>hash["source_address"], "publickey"=>hash["source_address"], "weight"=>1}
  sig_info = get_signer_info(hash["source_address"])
  #puts "sig_info: #{sig_info.inspect}"
  sig_info["signers"].push(source)
  address = []
  sig_info["signers"].each do |row|
    #puts "row: #{row}"    
    sigs.each do |sig|
      #puts "sig_b64:  #{sig.to_xdr(:base64)}"
      sig_b64 = sig.to_xdr(:base64)
      check = verify_signature(envelope, row["publickey"], sig_b64)
      if check
        address.push(row["publickey"])
        puts "good key: #{row["publickey"]}"
      else
        #puts "bad key: #{row["publickey"]}"
      end
    end
  end
  puts "good_keys.count: #{address.length}"
  thresholds = get_thresholds_local(hash["source_address"])
  puts "thresholds: #{thresholds}"
  return address
end

def verify_signed_msg(string_msg, address, sig_b64)
  #verify this string message is signed by this address
  #with this signature that is in base64 xdr of a decorated signature structure
  #address can be an address or keypair with no secreet seed needed
  #see function sing_msg(string_msg, keypair) bellow that is used with this
  keypair = convert_address_to_keypair(address)
  sig = Base64.decode64(sig_b64)  
  hash = Digest::SHA256.digest(string_msg)
  result = keypair.verify(sig,hash)
  return result
end

def sign_msg(string_msg, keypair)
  #sign a string text message in string_msg using keypair
  # this is used with verify_signed_msg function to authenticate messages using stellar keypairs
  hash = Digest::SHA256.digest(string_msg)
  result = keypair.sign(hash)
  Base64.encode64(result)
end

def sha256_hash_file(filepath)
  sha1 = Digest::SHA256.new
  File.open(filepath) do|file|
    buffer = ''
    # Read the file 512 bytes at a time
    while not file.eof
      file.read(512, buffer)
      sha1.update(buffer)
    end
  end
  return sha1.to_s
end


def sign_file(filepath,keypair)
  #return a base64 encoded stellar signature of a file with
  # this keypair.  keypair in this case must include a secreet seed
  hash = sha256_hash_file(filepath)
  result = keypair.sign(hash)
  return Base64.encode64(result)
end

def verify_signed_file(filepath, address, sig_b64)
  #verify this files contents are signed by this stellar address
  #with this signature sig_b64 that is in base64 xdr of a stellar decorated signature structure
  #address can be a public address or keypair with no secreet seed needed
  # see function sign_file(filepath,keypair) that creates this sig_b64 signature from files
  # returns true if file matches signature for address, false if not or if sig_b64 is nil
  if sig_b64.nil? or sig_b64.length == 0
    return false
  end
  keypair = convert_address_to_keypair(address)
  sig = Base64.decode64(sig_b64)  
  hash = sha256_hash_file(filepath)
  result = keypair.verify(sig,hash)
  return result
end

def check_timestamp(message,timestamp)
  #timestamp is utc intiger from time.now that can be in string or int format
  #of the time the message was supposed to be stamped with
  #this timestamp must be within the real time now within tolerence settings default is +-60 sec
  # the string of timestamp is also expected to be seen within the message text body
  tolerence = 60
  time = Time.now.to_i
  max = time + tolerence
  min = time - tolerence
  if (timestamp.to_i > max) or (timestamp.to_i < min)
    puts "timestamp is outside present tolerence of #{tolerence}"
    puts "Time.now seen here is #{time} time stamp value is #{timestamp}"
    puts "returning false bad"
    return false
  end
  if message.include? timestamp.to_s
    puts "timestamped message checks out good"
    return true
  else
    puts "timestamp not found within body of message, return false bad"
    return false
  end
end

def add_timebounds(tx,min,max)
  #this will add timebounds to a transaction
  #min and max are in utc timestamp int format in ruby we use Time.now.to_i being now
  # you can add or subtract from that in secounds to get a wanted time window
  # that a transaction will be valid in
  # values of 0 for min is the same as start now or Time.now.to_i
  # value of 0 for max is the same as never expires
  timebounds = Stellar::TimeBounds.new
  if min > 0
    timebounds.min_time = min.to_i
  else
    timebounds.min_time = Time.now.to_i
  end
  if max > 0
    timebounds.max_time = max.to_i
  else
    #just make it a very big number, longer than the life of the universe?
    timebounds.max_time = Time.now.to_i * Time.now.to_i
  end
  tx.time_bounds = timebounds
  return tx
end

def create_unlock_transaction(target_account,unlocker_keypair,timebound)
  #this will return a transaction envelope in b64 to set target_account thresholds to 1,0,0,0
  #the unlocker_keypair address is expected to be one of the presently active signers in the target_account
  #if not found this function will return status as failed and it will print the reason for failure.
  #this function also expects that the present account is not already locked with only 1,0,0,0 thresholds to start
  #note the sequence number of the created transaction will be +2 from present sequence number of target_account to allow 
  #locking the target_account after this transaction has been delivered 
  #  timebound is an integer utc timestamp when this transaction begins to become active or valid on the stellar network
  target_account = convert_keypair_to_address(target_account) 
  if (timebound.to_i < Time.now.to_i)
    puts "timebound is less than Time.now, nothing will be done"
    return {"status"=>"fail", "target_account"=>target_account,"error"=>"timebound is less than Time.now or nil"}
  end
  signer_info = get_signer_info(target_account)
  puts "signer_info: #{signer_info}"
  if signer_info["signers"].length != 2
    puts "this account has the wrong number of signers, must have 2 with one being the witness server address, nothing will be done"
    return {"status"=>"fail", "target_account"=>target_account,"error"=>"signer count not eq 3"}
  end
  matchfound = false
  unlocker_address = unlocker_keypair.address
  signer_info["signers"].each do |signer|
    if signer["publickey"] = unlocker_address
      matchfound = true
    end
  end
  if !matchfound
    puts "the target_account doesn't contain unlocker_address as a valid signer, nothing will be done"
    return {"status"=>"fail", "target_account"=>target_account, "error"=>"target_account doesn't contain unlocker_address as a valid signer"}
  end
  target_keypair = convert_address_to_keypair(target_account)
  thresholds = get_thresholds_local(target_account) 
  puts "thresholds:  #{thresholds}" 
  if !({:master_weight=>1, :low=>0, :medium=>2, :high=>2} == thresholds)
    puts "the target_account is already unlocked or not in lock spec 1,0,2,2 so you don't need unlock tx "
    puts "present settings: #{thresholds}"
    return {"status"=>"fail", "target_account"=>target_account, "error"=>"target_account not locked to spec 1,0,2,2"}
  end 
  #envelope = set_thresholds(target_keypair, low: 0, medium: 0, high: 0)
  tx = set_options_tx(target_keypair, master_weight: 1, thresholds: {low: 0, medium: 0, high: 0})
  seq_num = tx.seq_num
  puts "seq_num: #{seq_num}"
  #tx.seq_num = tx.seq_num + 1
  puts "timebound: #{timebound}"
  tx = add_timebounds(tx,timebound,0)
  envelope = tx.to_envelope(unlocker_keypair)
  env_b64 = envelope_to_b64(envelope)
  return {"status"=>"success", "target_account"=>target_account, "witness_address"=>unlocker_keypair.address,"timebound" => timebound, "timenow"=>Time.now.to_i, "unlock_env_b64"=>env_b64}
end


end # end class Utils
end #end module Stellar_utilitiy

#include Stellar_utility
