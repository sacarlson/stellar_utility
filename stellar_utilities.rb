#!/usr/bin/ruby
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

#require 'base32'

#@configs = {}
#@configs["db_file_path"] = '/home/sacarlson/github/stellar/my-stellar/stellar-core/stellar.db'
#@configs["db_file_path"] = '/home/sacarlson/github/stellar/fred/stellar-db/stellar.db'
#only need url_horizon if your in horizon mode but this is default horizon-testnet
#@configs["url_horizon"] = 'https://horizon-testnet.stellar.org'
#@configs["url_stellar_core"] = 'http://localhost:8080'
#only need pg_*** if your using local_postgres mode
#@configs["pg_hostaddr"] = '127.0.0.1'
#@configs["pg_port"] = 5432
#@configs["pg_dbname"] = "stellar"
#@configs["pg_user"] = "sacarlson"
#@configs["pg_password"] = "password"
#@configs["mode"] = "localcore" || "horizon" || "local_postgres"
#@configs["mode"] = "local_postgres"
#@configs["fee"] = 10
#File.open("./stellar_utilities.cfg", "w") {|f| f.write(@configs.to_yaml) }
@configs = YAML.load(File.open("./stellar_utilities.cfg")) 
#@configs["mode"] = "localcore"

#exit -1

def get_db(query)
  #returns query hash from database that is dependent on mode
  if @configs["mode"] == "localcore"
    #puts "db file #{@configs["db_file_path"]}"
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
    return result["balance"]
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

def get_seqnum_local(account)
  result = get_accounts_local(account)
  if result.nil?
    return 0
  end
  return result["seqnum"].to_i
end

def get_native_balance_local(account)
  #puts "account #{account}"
  result = get_accounts_local(account)
  if result.nil?
    return 0
  end
  return result["balance"].to_i
end

def bal_STR(account)
  get_native_balance(account).to_i
end

def get_account_info_horizon(account)
    account = convert_keypair_to_address(account)
    params = '/accounts/'
    url = @configs["url_horizon"]
    send = url + params + account
    #puts "#{send}"
    postdata = RestClient.get send
    data = JSON.parse(postdata)
    return data
end

def get_account_sequence(account)
  if @configs["mode"] == "horizon"
    puts "horizon mode get seq"
    return get_account_sequence_horizon(account)
  else
    return get_seqnum_local(account)
  end
end

def get_account_sequence_horizon(account)
  data = get_account_info_horizon(account)
  return data["sequence"]
end

def next_sequence(account)
  # account here can be Stellar::KeyPair or String with Stellar address
  address = convert_keypair_to_address(account)
  #puts "address #{address}"
  return get_account_sequence(address)+1
end


def get_native_balance_horizon(account)
  #compatable with old ruby horizon and go-horizon formats
  data = get_account_info_horizon(account)
  data["balances"].each{ |row|
    puts "row = #{row}"
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
  data["balances"].each{ |row|
    if row["asset_code"] == currency
      if row["issuer"] == issuer
        return row["balance"]
      end
    end
  }
  return 0
end

def get_native_balance(account)
  if @configs["mode"] == "horizon"
    return get_native_balance_horizon(account)
  else
    return get_native_balance_local(account)
  end
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
  return result.body
end

def send_tx_horizon(b64)
  values = CGI::escape(b64)
  puts "url #{@configs["url_horizon"]}"
  headers = {
    :content_type => 'application/x-www-form-urlencoded'
  }
  puts "values: #{values}"
  #response = RestClient.post @configs["url_horizon"]+"/transactions", values, headers
  #response = RestClient.post @configs["url_horizon"]+"/transactions", b64, headers
  response = RestClient.post(@configs["url_horizon"]+"/transactions", {tx: b64}, headers)
  puts response
  return response
end

def send_tx(b64)
  if @configs["mode"] == "horizon"
    return send_tx_horizon(b64)
  else
    return send_tx_local(b64)
  end
end

def create_account_tx(account, funder, starting_balance=25.0, seqadd=0)
  account = convert_address_to_keypair(account)
  nxtseq = next_sequence(funder)
  #puts "create_account nxtseq #{nxtseq}"     
  tx = Stellar::Transaction.create_account({
    account:          funder,
    destination:      account,
    sequence:         next_sequence(funder)+seqadd,
    starting_balance: starting_balance,
    fee:        @configs["fee"]
  })
  return tx
end

def create_account_local(account, funder, starting_balance=25.0)
  tx = create_account_tx(account, funder, starting_balance)
  b64 = tx.to_envelope(funder).to_xdr(:base64)
  puts "b64: #{b64}"
  send_tx_local(b64)
end

def create_account_horizon(account, funder, starting_balance=25.0)
  tx = create_account_tx(account, funder, starting_balance)
  b64 = tx.to_envelope(funder).to_xdr(:base64)
  #b64 = tx.to_envelope(funder).to_xdr(:hex)
  send_tx_horizon(b64)
end

def create_account(account, funder, starting_balance=25.0)
  #this will create an activated account using funds from funder account
  # both account and funder are stellar account pairs, only the funder pair needs to have an active secrete key and needed funds
  # @configs["mode"] can point output to "horizon" api website or "local" to direct output to localy running stellar-core 
  if @configs["mode"] == "horizon"
    return create_account_horizon(account, funder, starting_balance=25.0)
  else
    return create_account_local(account, funder, starting_balance=25.0)
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
    amount:      [:native, amount * Stellar::ONE],
    fee:        @configs["fee"]
  })
  return tx   
end

def send_native_local(from_pair, to_account, amount)
  tx = send_native_tx(from_pair, to_account, amount)
  b64 = tx.to_envelope(from_pair).to_xdr(:base64)
  send_tx_local(b64)
end

def send_native_horizon(from_pair, to_account, amount)
  tx = send_native_tx(from_pair, to_account, amount)
  b64 = tx.to_envelope(from_pair).to_xdr(:base64)
  send_tx_horizon(b64)
end

def send_native(from_pair, to_account, amount)
  # this will send native lunes from_pair account to_account
  # from_pair must be an active stellar key pair with the needed funds for amount
  # to_account can be an account address or an account pair with no need for secrete key.
  if @configs["mode"] == "horizon"
    return send_native_horizon(from_pair, to_account, amount)
  else
    return send_native_local(from_pair, to_account, amount)
  end
end

def add_trust_tx(issuer_account,to_pair,currency,limit=(2**63)-1)
  #issuer_pair = Stellar::KeyPair.from_address(issuer_account)
  issuer_pair = convert_address_to_keypair(issuer_account)
  tx = Stellar::Transaction.change_trust({
    account:    to_pair,
    sequence:   next_sequence(to_pair),
    line:       [:alphanum4, currency, issuer_pair],
    limit:      limit,
    fee:        @configs["fee"]
  })
  puts "fee = #{tx.fee}"
  return tx
end

def add_trust_local(issuer_account,to_pair,currency,limit=(2**63)-1)
  tx = add_trust_tx(issuer_account,to_pair,currency,limit)
  b64 = tx.to_envelope(to_pair).to_xdr(:base64)
  send_tx_local(b64)
end

def add_trust_horizon(issuer_account,to_pair,currency,limit=(2**63)-1)
  tx = add_trust_tx(issuer_account,to_pair,currency,limit)
  b64 = tx.to_envelope(to_pair).to_xdr(:base64)
  send_tx_horizon(b64)
end

def add_trust(issuer_account,to_pair,currency,limit=(2**63)-1)
  if @configs["mode"] == "horizon"
    return add_trust_horizon(issuer_account,to_pair,currency,limit=(2**63)-1)
  else
    return add_trust_local(issuer_account,to_pair,currency,limit=(2**63)-1)
  end
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
    fee:        @configs["fee"],
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
    amount:      [:alphanum4, currency, issuer_pair, amount],
    fee:        @configs["fee"]
  })  
  return tx
end

def send_currency_local(from_account_pair, to_account_pair, issuer_pair, amount, currency)
  tx = send_currency_tx(from_account_pair, to_account_pair, issuer_pair, amount, currency)
  b64 = tx.to_envelope(from_account_pair).to_xdr(:base64)
  send_tx_local(b64)
end

def send_currency_horizon(from_account_pair, to_account_pair, issuer_pair, amount, currency)
  tx = send_currency_tx(from_account_pair, to_account_pair, issuer_pair, amount, currency)
  b64 = tx.to_envelope(from_account_pair).to_xdr(:base64)
  send_tx_horizon(b64)
end

def send_currency(from_account_pair, to_account_pair, issuer_pair, amount, currency)
  if @configs["mode"] == "horizon"
    return send_currency_horizon(from_account_pair, to_account_pair, issuer_pair, amount, currency)
  else
    return send_currency_local(from_account_pair, to_account_pair, issuer_pair, amount, currency)
  end
end

def send_CHP(from_issuer_pair, to_account_pair, amount)
  send_currency(from_issuer_pair, to_account_pair, from_issuer_pair, amount, "CHP")
end

def create_new_account_with_CHP_trust(acc_issuer_pair)
  currency = "CHP"
  to_pair = Stellar::KeyPair.random
  create_account(to_pair, acc_issuer_pair, starting_balance=30_0000000)
  sleep 11
  add_trust(issuer_account,to_pair,currency,limit=(2**63)-1)
  return to_pair
end


def offer(account,sell_issuer,sell_currency, buy_issuer, buy_currency,amount,price)
  tx = Stellar::Transaction.manage_offer({
    account:    account,
    sequence:   next_sequence(account),
    selling:    [:alphanum4, sell_currency, sell_issuer],
    buying:     [:alphanum4, buy_currency, buy_issuer],
    amount:     amount,
    fee:        @configs["fee"],
    price:      price,
  })
  b64 = tx.to_envelope(account).to_xdr(:base64)
  return b64
end

def tx_merge(account_keypair,tx1,tx2)
  # these tx1 and tx2 must be from before the b64 convert
  # also note that the tx's must all be for the same account
  # not sure I will ever need this. just added as a reference from the examples.
  b64 = tx1.merge(tx2).to_envelope(account_keypair).to_xdr(:base64)
  return b64
end
#hex = tx1.merge(tx2).to_envelope(master).to_xdr(:base64)

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
  envnew = envelope = tx.to_envelope(*keypair)
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
  #this assumes all envelops have sigs of the same tx
  #envs can be arrays of envelops or env_merge(envA,envB,envC)
  #this can be used to collect all the signers of a multi-sign transaction
  tx = envs[0].tx
  sigs = []
  envs.each do |env|
    #puts "env sig #{env.signatures}"
    sigs.concat(env.signatures)
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



