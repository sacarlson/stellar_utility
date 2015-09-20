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
    Stellar.default_network = eval(@configs["default_network"])
  elsif load == "db2"
    #localcore mode
    @configs = {"db_file_path"=>"/home/sacarlson/github/stellar/stellar_utility/stellar-db2/stellar.db", "url_horizon"=>"https://horizon-testnet.stellar.org", "url_stellar_core"=>"http://localhost:8080", "url_mss_server"=>"localhost:9494", "mode"=>"localcore", "fee"=>10, "start_balance"=>100, "default_network"=>"Stellar::Networks::TESTNET", "master_keypair"=>"Stellar::KeyPair.master"}
    Stellar.default_network = eval(@configs["default_network"])
  elsif load == "horizon"
    #horizon mode, if nothing entered for load this is default
    @configs = {"db_file_path"=>"/home/sacarlson/github/stellar/stellar_utility/stellar-db2/stellar.db", "url_horizon"=>"https://horizon-testnet.stellar.org", "url_stellar_core"=>"http://localhost:8080", "url_mss_server"=>"localhost:9494", "mode"=>"horizon", "fee"=>10, "start_balance"=>100, "default_network"=>"Stellar::Networks::TESTNET", "master_keypair"=>"Stellar::KeyPair.master"}
    Stellar.default_network = eval(@configs["default_network"])
  else
    #load custom config file
    @configs = YAML.load(File.open(load)) 
    Stellar.default_network = eval(@configs["default_network"])
  end
end #end initalize

def version
  puts "mode: #{@configs["mode"]}"
  return "0.1.0"
end

def get_db(query)
  #returns query hash from database that is dependent on mode
  if @configs["mode"] == "localcore"
    puts "db file #{@configs["db_file_path"]}"
    db = SQLite3::Database.open @configs["db_file_path"]
    db.execute "PRAGMA journal_mode = WAL"
    db.results_as_hash=true
    stm = db.prepare query 
    result= stm.execute
    return result.next
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
    return get_db(query) 
end

def get_lines_balance_local(account,issuer,currency)
  # balance of trustlines on the Stellar account from localy running Stellar-core db
  # you must setup your local path to @stellar_db_file_path for this to work
  # also at this time this assumes you only have one gateway issuer for each currency
  account = convert_keypair_to_address(account)  
  query = "SELECT * FROM trustlines WHERE accountid='#{account}' AND assetcode='#{currency}' AND issuer='#{issuer}'"
  result = get_db(query)
  if result == nil
    return 0
  else
    bal = result["balance"].to_f
    return bal/10000000
  end
end

def get_lines_balance(account,issuer,currency)
  if @configs["mode"] == "horizon"
    return get_lines_balance_horizon(account,issuer,currency)
  else
    return get_lines_balance_local(account,issuer,currency)
  end
end

def bal_CHP(account)
  get_lines_balance(account,"CHP")
end

def get_sequence_local(account)
  result = get_accounts_local(account)
  if result.nil?
    return 0
  end
  return result["seqnum"].to_i
end

def get_thresholds_local(account)
  result = get_accounts_local(account)
  if result.nil?
    return "nil"
  end
  thresholds_b64 = result["thresholds"]
  decode_thresholds_b64(thresholds_b64)
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

def get_sequence(account)
  if @configs["mode"] == "horizon"
    #puts "horizon mode get seq"
    return get_sequence_horizon(account)
  else
    return get_sequence_local(account)
  end
end

def get_sequence_horizon(account)
  data = get_account_info_horizon(account)
  return data["sequence"]
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
  get_native_balance(account).to_i
end

def get_native_balance(account)
  if @configs["mode"] == "horizon"
    return get_native_balance_horizon(account)
  else
    return get_native_balance_local(account)
  end
end

def get_native_balance_local(account)
  #puts "account #{account}"
  result = get_accounts_local(account)
  if result.nil?
    return 0
  end
  bal = result["balance"].to_f
  bal = bal/10000000
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
    puts "#{tr.result.code}"
    return tr.result.code
  end
  #puts "#result.body: #{result.body}"
  return result.body
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
    #puts "rescue failure at send_tx_horizon response.class #{response.class}: "
    puts response
    #puts "e.response.class  #{e.response.class}: "
    puts  JSON.parse(e.response)
    responce = JSON.parse(e.response)
    responce = decode_error(responce["error"])
  end
  #puts response
  return response
end

def send_tx(b64)
  if b64 == "no funds"
    return "no funds"
  end
  if @configs["mode"] == "horizon"
    result = send_tx_horizon(b64)
    sleep 12
    return result
  else
    result = send_tx_local(b64)
    sleep 12
    return result
  end  
end

def create_account_tx(account, funder, starting_balance)
  #puts "starting_balance #{starting_balance}"
  starting_balance = starting_balance.to_i
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

def send_native_tx(from_pair, to_account, amount, seqadd=0)
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

def send_native(from_pair, to_account, amount)
  # this will send native lunes from_pair account to_account
  # from_pair must be an active stellar key pair with the needed funds for amount
  # to_account can be an account address or an account pair with no need for secrete key.
  tx = send_native_tx(from_pair, to_account, amount)
  b64 = tx.to_envelope(from_pair).to_xdr(:base64)
  send_tx(b64)
end

def add_trust_tx(issuer_account,to_pair,currency,limit)
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

def send_currency(from_account_pair, to_account_pair, issuer_pair, amount, currency)
  # to_account_pair and issuer_pair can be ether a pair or just account address
  # from_account_pair must have full pair with secreet key
  tx = send_currency_tx(from_account_pair, to_account_pair, issuer_pair, amount, currency)
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
  tx = Stellar::Transaction.manage_offer({
    account:    account,
    sequence:   next_sequence(account),
    selling:    [:alphanum4, sell_currency, sell_issuer],
    buying:     [:alphanum4, buy_currency, buy_issuer],
    amount:     amount.to_s,
    fee:        @configs["fee"].to_i,
    price:      price.to_s,
  })
  b64 = tx.to_envelope(account).to_xdr(:base64)
  return b64
end

def tx_merge(*tx)
  # this will merge an array of tx transactions and take care of seq_num and fee adjustments
  # I'm not totaly sure you need a fee = count * 10, not sure what the exact number is yet but it works so go with it
  puts ""
  #puts "tx.inspect:  #{tx.inspect}"
  seq_num = tx[0][0].seq_num 
  tx0 = tx[0][0]
  count = tx[0].length
  #puts "count: #{count}"
  tx[0].drop(1).each do |row|
    seq_num = seq_num + 1
    row.seq_num = seq_num
    #puts "row.source_account: #{row.source_account}"
    tx0 = tx0.merge(row)
  end
  tx0.fee = count * 10
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
  bytes = Stellar::Convert.from_base64 b64
  envelope = Stellar::TransactionEnvelope.from_xdr bytes
end

def convert_keypair_to_address(account)
  if account.is_a?(Stellar::KeyPair)
    address = account.address
  else
    address = account
  end
  #puts "#{address}"
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
  #account = get_account account
  #puts "#{account}  #{args}"
  params = {
    account:  account,
    sequence: next_sequence(account),
  }

  if args[:inflation_dest].present?
    params[:inflation_dest] = get_account args[:inflation_dest]
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

def get_public_key(keypair)
  keypair.public_key
end

#Contract Symbol, Stellar::KeyPair => Any
def remove_signer(account, key)
  add_signer account, key, 0
end

#Contract(Symbol, MasterWeightByte => Any)
def set_master_signer_weight(account, weight)
  set_options account, master_weight: weight
end


def envelope_addsigners(env,tx,*keypair)
  #this is used to add needed keypair signitures to a transaction
  # and combine your added signed tx with someone elses envelope that has signed tx's in it
  # you can add one or more keypairs to the envelope
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
  if 1==0
  puts "got to env_merge"
  puts "envs.length:  #{envs.length}"
  puts ""
  puts "envs.inspect:  #{envs.inspect}"
  puts ""
  #puts "envs[0].length #{envs[0].length}"
  #puts ""
  puts "envs[0].inspect:  #{envs[0].inspect}"
  puts ""
  puts "envs[1].inspect:  #{envs[1].inspect}"
  end 
  #puts "envs[0][0].inspect:  #{envs[0][0].inspect}"
  #env = envs[0][0]
  env = envs[0]
  #puts "envs[0][0]:  #{envs[0][0].inspect}"
  #puts "env.class:  #{env.class}"
  #puts "env.inspect  #{env.inspect}"
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
  #puts "sigs #{sigs}"  
  envnew = tx.to_envelope()
  pos = 0
  sigs.each do |sig|
    envnew.signatures[pos] = sig
    pos = pos + 1
  end
  return envnew	    
end

def hash32(string)
  #a shortened 10 letter base32 SHA256 hash, not likely to be duplicate with small numbers of tx
  # example output "7ZZUMOSZ26"
  Base32.encode(Digest::SHA256.digest(string))[0..9]
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
  #tx_title will be the hash32 (ten leters) of hash created 
  #it will return a hash that can be submited to send_to_multi_sign_server function
  create_acc = {"action"=>"create_acc","tx_title"=>"none","master_address"=>"GDZ4AF...","master_seed"=>"SDRES6...", "start_balance"=>100, "signers_total"=>"2", "thresholds"=>{"master_weight"=>"1","low"=>"0","med"=>"2","high"=>"2"},"signer_weights"=>{"GDZ4AF..."=>"1","GDOJM..."=>"1","zzz"=>"1"}}
  signer_count = signers.length
  #puts "sigs: #{signer_count}"
  signer_weights = {}
  signers.each do |row|
    row = convert_keypair_to_address(row)
    signer_weights[row] = 1
  end
  #puts "signer_weights: #{signer_weights}"  
  create_acc["master_address"] = master_pair.address
  create_acc["master_seed"] = master_pair.seed
  create_acc["signer_weights"] = signer_weights
  create_acc["signers_total"] = signer_count + 1
  create_acc["thresholds"]["med"] = signer_count + 1
  create_acc["thresholds"]["high"] = signer_count + 1
  create_acc["thresholds"]["master_weight"] = 1  
  tx_codex = hash32(create_acc.to_json)
  create_acc["tx_title"] = tx_codex
  return create_acc
end

def setup_multi_sig_tx_hash(tx, master_keypair, signer_keypair=master_keypair)
  #setup a tx_hash that will be sent to send_to_multi_sign_server(tx_hash) to publish tx to multi-sign server
  # you have the option to customize the hash after this creates a basic template
  # you can change tx_title, signer_weight, signer_sig, if desired before sending it to the multi-sign-server
  signer_address = convert_keypair_to_address(signer_keypair)
  master_address = convert_keypair_to_address(master_keypair)
  tx_hash = {"action"=>"submit_tx","tx_title"=>"test tx", "signer_address"=>"RUTIWOPF", "signer_weight"=>"1", "master_address"=>"GAJYPMJ...","tx_envelope_b64"=>"AAAA...","signer_sig"=>""}
  tx_hash["signer_address"] = signer_address
  tx_hash["master_address"] = master_address
  envelope = tx.to_envelope(master_keypair)
  puts ""
  puts "envelope: #{envelope.inspect}"
  b64 = envelope_to_b64(envelope)
  tx_hash["tx_title"] = hash32(b64)
  tx_hash["tx_envelope_b64"] = b64
  return tx_hash
end 

def create_account_from_acc_hash(acc_hash, funder = nil)
  #this will create a b64 formated transaction from the standard formated acc_hash 
  #see acc_hash = setup_multi_sig_acc_hash(master_pair,*signers) for more details
  # if funder keypair is provided we will fund the master_seed account in the acc_hash with it  
  if funder.nil?
    #no funder was provided so see if master_seed is valid seed length
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
      #nope not a valid master_seed address so we will do nothing
      puts "master_seed not valid so will do nothing"
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
  signers = acc_hash["signer_weights"]
  puts "to_pair:  #{to_pair.address}"
  pos = 0
  signers.drop(0).each do |acc, wt|
    puts "acc:#{acc}  wt:#{wt}"
    keypair = Stellar::KeyPair.from_address(acc)
    public_key = keypair.public_key
    env = add_signer_public_key(to_pair, public_key, wt.to_i)
    tx[pos] = env.tx
    pos = pos + 1
  end
  #puts "tx: #{tx[0].inspect}"  
  th = acc_hash["thresholds"]
  env = set_thresholds(to_pair, master_weight: th["master_weight"].to_i, low: th["low"].to_i, medium: th["med"].to_i, high: th["high"].to_i)
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
  return envelope.signatures
end

def sign_transaction_env(env,keypair)
  #return a signature for a transaction
  #signature = sign_transaction(tx,keypair)
  # todo: make it so tx can be a raw tx or an envelope that already has some sigs in it.
  # just depending on the class of tx
  tx = env.tx
  envelope = tx.to_envelope(keypair)
  return envelope.signatures
end

def merge_signatures_tx(tx,*sigs)
  #merge an array of signing signatures onto a transaction
  #output is a signed envelope
  #envelope = merge_signatures(tx,sig1,sig2,sig3)
  # todo: make it so tx can be raw tx or envelope with sigs already in it.
  envnew = tx.to_envelope()
  pos = 0
  sigs.each do |sig|
    envnew.signatures[pos] = sig
    pos = pos + 1
  end
  return envnew	    
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
  bytes = Stellar::Convert.from_base64 b64
  result = Stellar::Thresholds.parse bytes
  #puts "res.inpsect:  #{result.inspect}"
end

def decode_txbody_b64(b64)
  #this can be used to view what is inside of a stellar db txhistory txbody in a more human readable format than b64
  #example data seen 
  #b64 = 'AAAAAGXNhLrhGtltTwCpmqlarh7s1DB2hIkbP//jgzn4Fos/AAAACgAAACEAAAGwAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAPsbtuH+tyUkMFS7Jglb5xLEpSxGGW0dn/Ryb1K60u4IAAAAXSHboAAAAAAAAAAAB+BaLPwAAAEDmsy29BbAv/oXdKMTYTKFiqPTKgMO0lpzBTJSaH5ZT2LFdpIT+fWnOjknlRlmXwazn0IaV8nlokS4ETTPPqgEK'

  #example output:
  #tx.inpect #<Stellar::Transaction:0x0000000317cb60 @attributes={:source_account=>#<Stellar::PublicKey:0x0000000317c110 @switch=Stellar::CryptoKeyType.key_type_ed25519(0), @arm=:ed25519, @value="e\xCD\x84\xBA\xE1\x1A\xD9mO\x00\xA9\x9A\xA9Z\xAE\x1E\xEC\xD40v\x84\x89\e?\xFF\xE3\x839\xF8\x16\x8B?">, :fee=>10, :seq_num=>141733921200, :time_bounds=>nil, :memo=>#<Stellar::Memo:0x00000003094fe0 @switch=Stellar::MemoType.memo_none(0), @arm=nil, @value=:void>, :operations=>[#<Stellar::Operation:0x00000003094950 @attributes={:source_account=>nil, :body=>#<Stellar::Operation::Body:0x00000003093a78 @switch=Stellar::OperationType.create_account(0), @arm=:create_account_op, @value=#<Stellar::CreateAccountOp:0x00000003094220 @attributes={:destination=>#<Stellar::PublicKey:0x00000003093cf8 @switch=Stellar::CryptoKeyType.key_type_ed25519(0), @arm=:ed25519, @value=">\xC6\xED\xB8\x7F\xAD\xC9I\f\x15.\xC9\x82V\xF9\xC4\xB1)K\x11\x86[Gg\xFD\x1C\x9B\xD4\xAE\xB4\xBB\x82">, :starting_balance=>100000000000}>>}>], :ext=>#<Stellar::Transaction::Ext:0x00000003093668 @switch=0, @arm=nil, @value=:void>}>

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
  #tranPair.inspect:  #<Stellar::TransactionResultPair:0x00000001816ae0 @attributes={:transaction_hash=>"\xDCM\x93\xA0\xB1\xB9\xDB\x8E\x87\xBB\xE722\xA6\xA7\x06\x1D\e\xD1\xA0\x8E7\xF2O8x\xBC-n\xBC\x81\x96", :result=>#<Stellar::TransactionResult:0x00000001816180 @attributes={:fee_charged=>10, :result=>#<Stellar::TransactionResult::Result:0x0000000170fbb0 @switch=Stellar::TransactionResultCode.tx_success(0), @arm=:results, @value=[#<Stellar::OperationResult:0x0000000170fc00 @switch=Stellar::OperationResultCode.op_inner(0), @arm=:tr, @value=#<Stellar::OperationResult::Tr:0x0000000170fca0 @switch=Stellar::OperationType.create_account(0), @arm=:create_account_result, @value=#<Stellar::CreateAccountResult:0x0000000170fcf0 @switch=Stellar::CreateAccountResultCode.create_account_success(0), @arm=nil, @value=:void>>>]>, :ext=>#<Stellar::TransactionResult::Ext:0x0000000170f868 @switch=0, @arm=nil, @value=:void>}>}>
#<Stellar::TransactionResultPair:0x00000001816ae0 @attributes={:transaction_hash=>"\xDCM\x93\xA0\xB1\xB9\xDB\x8E\x87\xBB\xE722\xA6\xA7\x06\x1D\e\xD1\xA0\x8E7\xF2O8x\xBC-n\xBC\x81\x96", :result=>#<Stellar::TransactionResult:0x00000001816180 @attributes={:fee_charged=>10, :result=>#<Stellar::TransactionResult::Result:0x0000000170fbb0 @switch=Stellar::TransactionResultCode.tx_success(0), @arm=:results, @value=[#<Stellar::OperationResult:0x0000000170fc00 @switch=Stellar::OperationResultCode.op_inner(0), @arm=:tr, @value=#<Stellar::OperationResult::Tr:0x0000000170fca0 @switch=Stellar::OperationType.create_account(0), @arm=:create_account_result, @value=#<Stellar::CreateAccountResult:0x0000000170fcf0 @switch=Stellar::CreateAccountResultCode.create_account_success(0), @arm=nil, @value=:void>>>]>, :ext=>#<Stellar::TransactionResult::Ext:0x0000000170f868 @switch=0, @arm=nil, @value=:void>}>}>

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


end # end class Utils
end #end module Stellar_utilitiy

#include Stellar_utility
