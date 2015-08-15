#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
# this setup requires haveing a local stellar-core running on your system
# you must also modify @configs["db_file_path"] or edit stellar_utilities.cfg file to point to the location you now have the stellar-core sqlite db file
# there is also support to get results from https://horizon-testnet.stellar.org and at some point we should be able
# to also send base64 transactions to horizon to get results, but this is not yet tested. 
# some functions are duplicated just to be plug and play compatible with my old stellar network class_payment.rb lib that's used in pokerth_accounting.

require 'stellar-base'
require 'faraday'
require 'faraday_middleware'
require 'json'
require 'rest-client'
require 'sqlite3'
require 'yaml'

@configs = {}
#@configs["db_file_path"] = '/home/sacarlson/github/stellar/my-stellar/stellar-core/stellar.db'
#@configs["db_file_path"] = '/home/sacarlson/github/stellar/fred/stellar-db/stellar.db'
#@configs["url_horizon"] = 'https://horizon-testnet.stellar.org'
#@configs["url_stellar_core"] = 'http://localhost:39132'
#@configs["mode"] = "localcore" || "horizon"
#File.open("./stellar_utilities.cfg", "w") {|f| f.write(@configs.to_yaml) }
@configs = YAML.load(File.open("./stellar_utilities.cfg")) 

def get_accounts_local(account)
    # this is to get all info on table account on Stellar.db from localy running Stellar-core db
    # you must setup your local path to @configs["db_file_path"] for this to work
    #puts "db_file_path #{@configs["db_file_path"]}"
    account = convert_keypair_to_address(account)
    db = SQLite3::Database.open @configs["db_file_path"]
    db.execute "PRAGMA journal_mode = WAL"
    stm = db.prepare "SELECT * FROM accounts WHERE accountid='#{account}' " 
    rs = stm.execute
    rs.each do |row|
      #puts "#{row}"
      return row
    end   
end

def get_lines_balance(account,currency)
  # balance of trustlines on the Stellar account from localy running Stellar-core db
  # you must setup your local path to @stellar_db_file_path for this to work
  # also at this time this assumes you only have one gateway issuer for each currency
  account = convert_keypair_to_address(account)
  db = SQLite3::Database.open @configs["db_file_path"]
  db.execute "PRAGMA journal_mode = WAL"
  stm = db.prepare "SELECT * FROM trustlines WHERE accountid='#{account}' AND assetcode= '#{currency}'" 
  rs = stm.execute
  rs.each do |row|
    return row[5].to_f
  end
  return nil.to_f   
end

def bal_CHP(account)
  get_lines_balance(account,"CHP")
end

def get_seqnum_local(account)
  row = get_accounts_local(account)
  return row[2].to_i
end

def get_native_balance_local(account)
  puts "account #{account}"
  row = get_accounts_local(account)
  return row[1].to_i
end

def bal_STR(account)
  get_native_balance_local(account).to_i
end
#result = bal_STR(account)
#puts "#{result}"


def get_account_info(account)
    account = convert_keypair_to_address(account)
    params = '/accounts/'
    url = @configs["url_horizon"]
    send = url + params + account
    #puts "#{send}"
    postdata = RestClient.get send
    data = JSON.parse(postdata)
    return data
end
#result = get_account_info(account)
#puts "#{result}"


def get_account_sequence(account)
  return get_seqnum_local(account)
  #data = get_account_info(account)
  #return data["sequence"]
end

def next_sequence(account)
  # account here can be Stellar::KeyPair or String with Stellar address
  address = convert_keypair_to_address(account)
  #puts "address #{address}"
  return get_account_sequence(address)+1
end

#result = get_account_sequence(account)
#puts "#{result}"

def get_native_ballance(account)
  data = get_account_info(account)
  return data["balances"]
end

def create_random_pair
  return Stellar::KeyPair.random
end

def create_new_account()
  #this is created just to be compatible with old network function in payment_class.rb
  return Stellar::KeyPair.random
end

def send_tx(b64)
  # this assumes you have a stellar-core listening on this address
  $server = Faraday.new(url: @configs["url_stellar_core"]) do |conn|
    conn.response :json
    conn.adapter Faraday.default_adapter
  end
  result = $server.get('tx', blob: b64)
  return result.body
end

def create_account_tx(account, funder, starting_balance=1000_0000000, seqadd=0)
  account = convert_address_to_keypair(account)     
  tx = Stellar::Transaction.create_account({
    account:          funder,
    destination:      account,
    sequence:         next_sequence(funder)+seqadd,
    starting_balance: starting_balance,
  })
  return tx
end

def create_account(account, funder, starting_balance=1000_0000000)
  tx = create_account_tx(account, funder, starting_balance)
  b64 = tx.to_envelope(funder).to_xdr(:base64)
  send_tx(b64)
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
    amount:      [:native, amount * Stellar::ONE]
  })
  return tx   
end

def send_native(from_pair, to_account, amount)
  tx = send_native_tx(from_pair, to_account, amount)
  b64 = tx.to_envelope(from_pair).to_xdr(:base64)
  send_tx(b64)
end


def add_trust_tx(issuer_account,to_pair,currency,limit=(2**63)-1)
  #issuer_pair = Stellar::KeyPair.from_address(issuer_account)
  issuer_pair = convert_address_to_keypair(issuer_account)
  tx = Stellar::Transaction.change_trust({
    account:    to_pair,
    sequence:   next_sequence(to_pair),
    line:       [:alphanum4, currency, issuer_pair],
    limit:      limit
  })
  return tx
end

def add_trust(issuer_account,to_pair,currency,limit=(2**63)-1)
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
  tx = Stellar::Transaction.payment({
    account:     from_account_pair,
    destination: to_account_pair,
    sequence:    next_sequence(from_account_pair),
    amount:      [:alphanum4, currency, issuer_pair, amount]
  })  
  return tx
end

def send_currency(from_account_pair, to_account_pair, issuer_pair, amount, currency)
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
    price:      price,
  })
  b64 = tx.to_envelope(account).to_xdr(:base64)
  return b64
end

def tx_merge(account,tx1,tx2)
  # these tx1 and tx2 must be from before the b64 convert
  # also note that the tx's must all be for the same account
  # not sure I will ever need this. just added as a reference from the examples.
  b64 = tx1.merge(tx2).to_envelope(account).to_xdr(:base64)
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

  

