
#Multi Sign websocket Server also know as mss-server or mss-websocket server for short

The mss-webscket server performs the same actions using the same JSON formated strings as the original mss-server did plus now more
only using a websocket instead of an http connected server.
The websocket advantage is that the websocket client can now continue to be connected and get feedback of the current status of the transaction
in realtime that in ruby can be driven with the EM eventmanager to triger function on transaction events as shown in the client_signer examples also contained here.
to do a full run of the example sesion you can run each of the samples in a different terminal window to allow seeing the events unfold.
in this sequence:
start the server:
  multi-sign-websocket.rb

create and account and submit it to the mss server:
  create_account_for_mss.rb

sumit a new transaction on the account created above and submits or publish it to the mss server:
  submit_transaction_to_mss.rb

example signer A picks up the transaction from the mss-server and signs it  and publishes it's signature with the mss-server
  client_signerA_test.rb

example signer B picks up the transaction and also signs it and publishes the final needed signature to the mss server
  client_signerB_test.rb

after the last of these example programs is run the mss-server will combine the signatures of all the signers and submits the transaction to the stellar.org network
for validation.

#More details of the operations and transaction format of the mss-server is described bellow.  note bellow was originaly writen for the  multi-sign-server 
so some filenames may not match, but the format basicly the same, only the lower level communication protocol has changed.
at the end of this readme contains the details for install setup and running of the server

multi-sign-server.rb is a JSON formated API server for the stellar.org networks new stellar-core.
it was originaly created to allow the publishing of multi sign transaction and provide a point of collection for the 
signers to pickup the original unsigned transaction, sign it and send a validation signature back to the mss-server
that would collect all the signatures and when weighted threshold is met will send the multi signed transaction to the stellar-core network

The mss-server can now also do most stellar network database lookup function of getting account balance, buy sell offers, tx result history and now most
any data in the stellar database can now be obtained from the mss-server api interface. also the basic function of sending tx blobs and other functions
that are normaly done through the horizon server API can also be performed on the mss-server.  as the secondary goal of mss-server is to make it posible
to do most anything you can do with a localcore on site over the mss-server API instead of running one localy by making almost all the steller-core database values accesable over the API.  


#The mss-server json action commands and format

An example of a basic JSON formated string that is sent to the mss-server looks like this
{"action":"send_tx","tx_code":"T_RQHKC7XD"}

In this case the "action" code is send_tx that needs one verible tx_code to perform the action of sending this tx_code transaction to the
stellar network to get a responce returned that will also be in JSON format.

The present action codes and values required for each of them can be seen bellow in the format:

#action_code:    short explaination of what the action code does
  Values sent: bellow will be the values we send the mss-server in JSON format
    value_name:  short explaination of what the value name is and does for the action_code
       .        as many values as needed for an action
       .
  Value returned: bellow will be what the mss-server returns in JSON format
    value_name: short explaination of what the value name is and does for the action_code
       .       as many returned for this action
       .

 example JSON sent:  showing examples of what is sent of this action in JSON format 
 example JSON returned:  examples of JSON string returned from mss-server for this action

#create_acc: create a multi sign account with the settings of the values given
  Values sent:
    master_address: the stellar address of the master creator of the account
    master_seed:    optional master seed of the master creator of the account (not really needed at this time)
    signers_total:  total number of signers that will be added to the account
    thresholds:     threshold settings on the account including
       master_weight: the signing weight of the master account seed as a signer
       low:           the threshold for the low setting on this multi sign account
       med:           the threshold for the med setting 
       high:          the threshold for the high setting 

  Values returned:
    acc_num:  integer of local tx index on this mss-server (not uneque between mss-servers)
    tx_title: what is now seen as tx_title on this transaction defaults to random 8 letter hash leading with A_
    master_address:  master_address of what was used to create this account
    master_seed: master_seed of account that created this account (none really needed)
    start_balance: setting that were set or defaulted as what to fund the master_address account if created on mss-server
    signers_total: the number of signers that have been attached to this account
    thresholds:
      master_weight: master_weight signing settings for the master_address account
      master_weight: the signing weight of the master account seed as a signer
       low:           the threshold for the low setting on this multi sign account
       med:           the threshold for the med setting 
       high:          the threshold for the high setting
 
 example in JSON sent:
{"action":"create_acc","tx_title":"A_M7U2T7UQ","master_address":"GDM6RBPBTDY3YE35I7LLU53LP4IZH26PIFE5IFPITGCEOZBX66IFZIDH","master_seed":"SABKMP7S2A5QUQ2DHNV7HO53EJWUGO7C2BF3WU2RL3YCLGFFCNUOF4KA","start_balance":100,"signers_total":3,"thresholds":{"master_weight":1,"low":"0","med":3,"high":3},"signer_weights":{"GCHOUZUXO2CKBJJICJ6R4EHRLSKCANGD3QTACE5QZJ27T7TSGMD4JP5U":1,"GCFZMOSTNINJB65VOSXY3RKATANT7DQJJVUMJGSXMCAOBUUENSQME4ZZ":1}}
 
 example in JSON return:
{"acc_num":1,"tx_title":"A_M7U2T7UQ","master_address":"GDM6RBPBTDY3YE35I7LLU53LP4IZH26PIFE5IFPITGCEOZBX66IFZIDH","master_seed":"none_provided","signers_total":"3"}

#send_tx:    send the transaction with this matching tx_code to the stellar-core network for validation (normaly done automaticaly but for test we have this) 
  Values sent: 
    tx_code:  is a uneque auto generated code number that starts with T_ example T_RQHKC7XD that are used as references to transactions in the mss-server database

  Values returned:
    name:  stellar network error name
    value: value integer of stellar error code

 example returned:
 {"name":"tx_bad_seq","value":-5}  //this is what error output looks like if bad transaction sent

#status_tx:  return the status of the transaction in the mss-server db that matches tx_code to find out how many signatures collected or if tx already sent
  Value sent:
    tx_code: 

  Values returned:
    status: returns pending if not enuf sigs recieved to send transaction, ready if tx has already been sent to network
    tx_code:

 example JSON send: 
 {"action":"status_tx","tx_code":"T_RQHKC7XD"}
 example JSON return:
 {"status":"pending","tx_code":"T_RQHKC7XD"} // tx hasn't got all it signatures needed yet
 {"status":"ready","tx_code":"T_RQHKC7XD"}  // this will return if the tx has already been sent to stellar-core network for validation
 
#submit_tx:  adds a new transaction to the mss-server database with the added values of the veribles attached
  Values sent:
    tx_title: an added modifiable title used to help users discribe the transaction, defaults to tx_code 
    master_address: the stellar multi sign account number
    tx_envelope_b64: the transaction envelope to be signed by the signers in xdr base 64 format
    signer_weight:  the signing weight given to the master_address
    tx_code:  is not entered but is autocreated and added to the mss-server database and returned in responce

  Values returned:
    status: pending or ?? when after the system has sent the transaction to the stellar network for validation
    tx_code: 
    signer_count:  number of signers that have already signed this transaction (including the master)
    count_needed: the total number of signers needed for this transaction to be sent to the stellar network for validation
    

  example JSON send:
{"action":"submit_tx","tx_title":"T_JD7NBZPV","signer_address":"GDM6RBPBTDY3YE35I7LLU53LP4IZH26PIFE5IFPITGCEOZBX66IFZIDH","signer_weight":"1","master_address":"GDM6RBPBTDY3YE35I7LLU53LP4IZH26PIFE5IFPITGCEOZBX66IFZIDH","tx_envelope_b64":"AAAAANnoheGY8bwTfUfWundrfxGT689BSdQV6JmER2Q395BcAAAACgABh04AAAADAAAAAAAAAAAAAAABAAAAAAAAAAUAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAACHRlc3Q1NjkyAAAAAAAAAAAAAAABN/eQXAAAAEBaa64v1Pvh3g0eM1w5g9tlli/O6J0T4FPu9ifle3xGDyOLvGo7W2bpZ+uS9q31se2UMbd5gr0HFPivvuZyanYL","signer_sig_b64":""}

  example JSON returned:
    {"status":"pending","tx_code":"T_JD7NBZPV","signer_count":1,"count_needed":3}

#get_tx: lookup and return the values found for the transaction with this tx_code from the mss-server database
  Values sent:
    tx_code:

  Values returned:
    tx_num: an integer tx number used as index on the local mss-server
    signer: set to 0 if it was signed by master_address, 1 if signed by a signer
    tx_code: uneque code created as an indentifier to search for transactions over all mss-servers
    tx_title: user definable to help users explain or identify what the transaction is or what it's for
    signer_address: a stellar address in base 32 of a signer if this index identifies a signer entry
    signer_weight: signing weight that this signer has in this transaction
    master_address: master address of the creator of this transaction
    tx_envelope_b64: a stellar formated tx envelope in xdr base64 format of the transaction that need to be signed. 


 example JSON send:
{"action":"get_tx","tx_code":"T_RQHKC7XD"}

 example return from get_tx:
{"tx_num":1,"signer":0,"tx_code":"T_RQHKC7XD","tx_title":"T_RQHKC7XD","signer_address":"GDM6RBPBTDY3YE35I7LLU53LP4IZH26PIFE5IFPITGCEOZBX66IFZIDH","signer_weight":"1","master_address":"GDM6RBPBTDY3YE35I7LLU53LP4IZH26PIFE5IFPITGCEOZBX66IFZIDH","tx_envelope_b64":"AAAAANnoheGY8bwTfUfWundrfxGT689BSdQV6JmER2Q395BcAAAACgABh04AAAACAAAAAAAAAAAAAAABAAAAAAAAAAUAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAACHRlc3Q3NDM2AAAAAAAAAAAAAAABN/eQXAAAAEB2xFD4v6goEazu9UeLY0naWENxGwDKktFquSF0MJN6MPYrucRuRFzYK/xRofZzl8EIljizva+XBEk/SRioh6QL","signer_sig_b64":""}

#sign_tx: add a signature to a transaction that is already in the mss-server, if no tx_code match is found nothing is done
  Values sent:
    tx_code:
    signer_address: the stellar public address of this signer in base32 format example GCYFPRSLB...
    signer_weight: the signing weight of this signer (default is 1)
    tx_title: customisable by the user to add details for other users, not really used by the software
    signer_sig_b64: the validation signature for this transaction by this signer in xdr base 64 format
    tx_envelope_b64: optional (no longer used in v2) a signed envelope of the transaction in xdr base 64 format, v2 only needs signer_sig_b64 instead

  Values returned:
    status: pending returned if transaction not yet processed by stellar network, ready returned if needed signers have signed tx and tx already sent to network
    tx_code:  
    
  example JSON sent:
{"action":"sign_tx","tx_title":"T_RQHKC7XD","tx_code":"T_RQHKC7XD","signer_address":"GCHOUZUXO2CKBJJICJ6R4EHRLSKCANGD3QTACE5QZJ27T7TSGMD4JP5U","signer_weight":"1","tx_envelope_b64":"AAAAANnoheGY8bwTfUfWundrfxGT689BSdQV6JmER2Q395BcAAAACgABh04AAAACAAAAAAAAAAAAAAABAAAAAAAAAAUAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAACHRlc3Q3NDM2AAAAAAAAAAAAAAACcjMHxAAAAEApyJ3gfjYOZaAzY4ZLnt7uJCPrLlR1cPAos4fMRyrBrF2yrfz6U3dsAbv8tpmCMISiS9vZtKExaDZnsqdB1jcEN/eQXAAAAEB2xFD4v6goEazu9UeLY0naWENxGwDKktFquSF0MJN6MPYrucRuRFzYK/xRofZzl8EIljizva+XBEk/SRioh6QL","signer_sig_b64":"cjMHxAAAAEApyJ3gfjYOZaAzY4ZLnt7uJCPrLlR1cPAos4fMRyrBrF2yrfz6U3dsAbv8tpmCMISiS9vZtKExaDZnsqdB1jcE"}

  example JSON returned:
{"status":"ready","tx_code":"T_RQHKC7XD"}

#get_account_info: dump all data found in stellar-core db in account table. this will not work if mss-server is running in horizon mode
  Values sent:
    account: stellar address base 32 example GC3IIU5Q...

  Values returned:
    accountid: same as account address base 32 
    balance:  native balance seen in stellar network in lumens or STR or ??, it is in integer format so value is divided by 1e7 I think to be correct
    seqnum: sequence number of this account as seen on the stellar network
    numsubentries: the number of added signers that are attached to this account
    inflationdest: account number that this account has voted to be donated the inflation funds
    homedomain:  a value that can be set to be a nickname or an email or web address to ID the account
    thresholds: the value that this accounts thresholds are set that is in xdr base64 code
    flags:  ??
    lastmodified:  stellar sequence code of last changes made on this account

example return:
{"accountid":"GDM6RBPBTDY3YE35I7LLU53LP4IZH26PIFE5IFPITGCEOZBX66IFZIDH","balance":999999960,"seqnum":430244053909506,"numsubentries":2,"inflationdest":null,"homedomain":"test7436","thresholds":"AQADAw==","flags":0,"lastmodified":120119}

#get_lines_balance:
  Values sent:
    account: stellar address base 32 example GCYFPRSLBKM...
    issuer: stellar address of the issuer of the asset in this balance 
    asset:  asset name in this balance example USD, YEN, BEER...

  Values returned: 
    balance: float number of asset balance
    issuer:
    asset: 

example return:
{"issuer":"GC3IIU5Q2WLRC4B7T4GYBJ2UKOQ67RITKTVHCKC6UPECI6RT6JMDUPJO", "asset":"CHP", "balance":105.12}

#get_sell_offers: look up all sell offers made with this issuer and with this asset name
  Values sent:
    issuer: stellar address of the issuer of the asset in this search, if set to "any" will search through all issures on this asset
    asset: example USD, if set to "any" will search through all assets on this issuer
    limit: limit of the number of offers listed in the stellar-core database max is 10
    sort:  sort output assending "ASC" or sort desending "DESC"
    offset: start output from index X, this is used to page through output that has more than 10 elements that is max output

  Values returned:
    count: total number of orders found with these search params
    orders: an array of orders found with these search params
      sellerid: stellar account address making this order
      offerid: index number of the offer in the stellar database
      sellingassettype: always 1 ?? maybe depends on weather 4 or 12 letter asset name?
      sellingassetcode: asset code that they are selling example "USD"
      sellingissuer:  issuer address of the asset they are offering to selling
      buyingassettype: alway 1 ??
      buyingassetcode: asset code that they are buying
      buyingissuer: issuer address of the asset they are offering to buying
      amount: the quantity of the asset we are offering to sell
      pricen: price numerator of the asset price being offered to sell
      priced: price denominator of the asset price being offered to sell
      price: the price per unit of the asset being offered for sale based on the selling asset
      flags: ?? it's in the stellar database but I don't know what it is
      lastmodified: the last ledgerseq number that this assest order was modified.
      index: this is the index position of this search with these search params, to indicate position in page depending on offset, this starts from zero

   example input:
    {"action":"get_sell_offers", "issuer":"any","asset":"CCC","sort":"ASC", "offset":5}

  example return:
   {"orders":[{"sellerid":"GAMC...","offerid":24,"sellingassettype":1,"sellingassetcode":"CCC","sellingissuer":"GAX4...","buyingassettype":1,"buyingassetcode":"DDD","buyingissuer":"GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF","amount":10000000,"pricen":10,"priced":1,"price":10.0,"flags":0,"lastmodified":726345,"index":5}],"count":6}

#get_buy_offers: look up all buy offers made with this issuer and with this asset name
  Values sent:
    issuer: stellar address of the issuer of the asset in this search, if set to "any" will search through all issures on this asset
    asset: example USD, if set to "any" will search through all assets on this issuer
    limit: limit of the number of offers listed in the stellar-core database max is 10
    sort:  sort output assending "ASC" or sort desending "DESC"
    offset: start output from index X, this is used to page through output that has more than 10 elements that is max output
  Values returned:
    count: total number of orders with these search params found
    orders: an array of orders found with these search params
      sellerid: stellar account address making this order
      offerid: index number of the offer in the stellar database
      sellingassettype: always 1 ?? maybe depends on weather 4 or 12 letter asset name?
      sellingassetcode: asset code that they are selling example "USD"
      sellingissuer:  issuer address of the asset they are offering to selling
      buyingassettype: alway 1 ??
      buyingassetcode: asset code that they are buying
      buyingissuer: issuer address of the asset they are offering to buying
      amount: the quantity of the asset we are offering to sell
      pricen: price numerator of the asset price being offered to sell
      priced: price denominator of the asset price being offered to sell
      price: the price per unit of the asset being offered for sale based on the selling asset
      flags: ?? it's in the stellar database but I don't know what it is
      lastmodified: the last ledgerseq number that this assest order was modified.
      index: this is the index position of this search with these search params, to indicate position in page depending on offset
    
  example input:
    {"action":"get_buy_offers", "issuer":"any","asset":"CCC","sort":"ASC", "offset":0}

#version: return the version git hash of stellar-utility and the stellar-core that it is operating
  Values sent:
    no values needed
  
  Values returned:
    status: returns "success" if mss-server is working correctly
    version: values of the git hash for stellar_utility package and git hash for the stellar-core that it is controling if available

 example return:
 {"status":"success", "version":"su: 0.1.0  mss_version: 5063c84d core_version: 85472c7"}


#send_b64: send an envelope blob to the stellar-core network
  Values sent:
    envelope_b64: the envelope blob to be sent that is in xdr base 64 format, this can be any transaction that the signer of the envelope has authority to do

  Value returned:
    TBD

#get_signer_info: get a list of all the signers on this target account direct from the stellar network database
  Values sent:
    account: the target account for the information 
  Values returned:
    signers: an array signer hashes the length depending on how many signers the account has
      accountid: the same as the target account
      publickey: the address of this signer
      weight:  the signing weight that this signer has on this account

  example return:
  {"signers"=>[{"accountid"=>"GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO", "publickey"=>"GBT6G2KZI4ON3LTVRWEPT3GH66TTBTN77SIHRGNQ4KAU7N3GTFLYXYOM", "weight"=>1}]}

#get_threshold_info: get the threshold values for this account direct from the stellar database
  Values sent:
    account: the target account for the information wanted
  Values returned:
    master_weight:  the master signing weight, the signing power that this target account keypair has on this account
    low: the threshold of low
    medium: the threshold for medium security, needed to sign transactions to send payments and other
    high:  the threshold for high security,  needed when you want to sign transactions to change thresholds 

  example return:
    {"master_weight"=>1, "low"=>0, "medium"=>0, "high"=>0}

#get_tx_history: get the transaction history for this txid direct from the stellar database 
  Values sent:
    txid: the transaction number for the target transaction as seen in the stellar database
  Values return:
    txid: the txid of what is being searched for
    ledgerseq: the ledger sequence number of when this transaction was recorded
    txresult: a base64 encoded txresult seen on the stellar database server, note I should have decoded this for humans as the tools are already available in the libs

  example return:
   {"txid"=>"258fbbfb105a99d63665c31ef46cf721446835985103f37de934842fbd68cff6", "ledgerseq"=>4417, "txresult"=>"JY+7+xBamdY2ZcMe9Gz3IURoNZhRA/N96TSEL71oz/YAAAAAAAAAZAAAAAAAAAABAAAAAAAAAAUAAAAAAAAAAA=="} 
  
#make_unlock_transaction: create a env_b64 time bound transaction that will be used to unlock a locked account after some window of time
  Values sent:
    account: the target_account that will later be locked to be unlocked with this transaction
  Values return:
    status: returns success or fail depending on if account settings were within specs
    target_account: the account that the unlock transaction will unlock
    timebound:  this is the UTC time stamp of when this transaction begins to be valid on the stellar network
    timenow:  this is the UTC time stamp of what time it is now just used as a reference to the above to compare
    unlock_env_b64: a transaction envelope in base64 format that will be sent after the timebound time to unlock the target_account

  Example return: {"status"=>"success", "target_account"=>"GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO", "witness_address"=>"GCYSIZB4Q6ISTHFDXQMBBUPI4BVY7KW6QKCIZKTXAQBDXQYGRRIUTYSX", "timebound"=>1444562222, "timenow"=>1444475822, "unlock_env_b64"=>"AAAAAD1O39Zz2qUNUKLDH6BnGEEFOs8+CC/aVz5CUmCj3euQAAAAZAAACtMAAAAEAAAAAQAAAABWGkUuHPTGJ4CTykQAAAAAAAAAAQAAAAAAAAAFAAAAAAAAAAEAAAAAAAAAAQAAAAAAAAABAAAAAQAAAAEAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAEGjFFJAAAAQI1BcZWFOZzovdQC1SzT4BDJJ7AQsBHu1JXC89zCnUPrTjx7p0xHn/QoIoofT6zmhttXpVsyqdXF3JDdxKc1UQY="}

#make_witness: will create a signed timestamped document of the present state and ballances of a target account
  Values sent:
    account: that target account that the document will be write for
  Values return:
    accountid: the target account id address
    balance: the native balance on this account
    seqnum:  the sequence number of the account as seen at the moment the document was recorded 
    numsubentries: the number of signers seen on the account at time of recording
    inflationdest: setting of the inflation destination at time or recording
    homedomain:  home domain setting on the account
    master_weight:  the master weight setting on the account
    low:  theshold setting for the low threshold
    medium:  theshold setting for the medium threshold
    high:   threhold setting for the high threshold
    signers: number of signers returned depends on what the account presently holds, this is an array of signers and there weights
      accountid: same as above target account address  
      publickey: the public key address of this signer 
      weight: the weight that this signer has on this account when signing transactions
    timestamp: the UTC integer timestamp value at the time this record was created
    witness_account: the stellar account number of the pair that was used to signed this witness document
    signature: base64 signature of all the information in the above values and anything else added to the hash signed by the witness_account keypair
     this hash and signing can be validated on the user side with the function Utils.check_witness_hash(hash)

  Example return: {"acc_info":{"accountid":"GBYX56PB2I3T2W64ZZ62W7X4RUXQZJRR4EG7U4K7SCKDHU3DLM5NPCJM","balance":1219997700,"seqnum":2418066587666,"numsubentries":2,"inflationdest":null,"homedomain":"","thresholds":"AQACAg==","flags":0,"lastmodified":17037},"thresholds":{"master_weight":1,"low":0,"medium":2,"high":2},"signer_info":{"signers":[{"accountid":"GBYX56PB2I3T2W64ZZ62W7X4RUXQZJRR4EG7U4K7SCKDHU3DLM5NPCJM","publickey":"GCYSIZB4Q6ISTHFDXQMBBUPI4BVY7KW6QKCIZKTXAQBDXQYGRRIUTYSX","weight":1},{"accountid":"GBYX56PB2I3T2W64ZZ62W7X4RUXQZJRR4EG7U4K7SCKDHU3DLM5NPCJM","publickey":"GA4GWCCN7YNN5NFUX6MQ3IYPT3LBOFNBRZE3J2JVBJC3P6PNYWWIRPCG","weight":1}]},"timebound":null,"timestamp":"1444647586","witness_account":"GCYSIZB4Q6ISTHFDXQMBBUPI4BVY7KW6QKCIZKTXAQBDXQYGRRIUTYSX","signature":"IGPRXS9aNos5BaYrlwa5kSTdhlZkVsBPKQeP2Ho3DWftJVo7MLTe8LQpZZ0r\nIoxyWA5r1/WJZ9DGwODTh0wvCw==\n"}


#make_witness_unlock: this preforms two actions as it does the same as the above make_witness but also records timestamp and timebound in the mss server database
                      it also creates and adds an unlock transacton that is timebound per the users request
  Values sent:
    account: that target account that the document will be write for
    timebound: a utc timestamp integer specifing the start time that the unlock tx that will be returned will become active to unlock the account

  Values returned:
    Values return:
    accountid: the target account id address
    balance: the native balance on this account
    seqnum:  the sequence number of the account as seen at the moment the document was recorded 
    numsubentries: the number of signers seen on the account at time of recording
    inflationdest: setting of the inflation destination at time or recording
    homedomain:  home domain setting on the account
    master_weight:  the master weight setting on the account
    low:  theshold setting for the low threshold
    medium:  theshold setting for the medium threshold
    high:   threhold setting for the high threshold
    signers: number of signers returned depends on what the account presently holds, this is an array of signers and there weights
      accountid: same as above target account address  
      publickey: the public key address of this signer 
      weight: the weight that this signer has on this account when signing transactions
    timebound: the UTC integer timestamp of the start time that the unlock_env_b64 transaction will become valid on the stellar network to unlock the account
    timestamp: the UTC integer timestamp value at the time this record was created
    witness_account: the stellar account number of the pair that was used to signed this witness document
    signature: base64 signature of all the information in the above values and anything else added to the hash signed by the witness_account keypair
     this hash and signing can be validated on the user side with the function Utils.check_witness_hash(hash)
    unlock: is the hash returned from the create_unlock_transaction function, it contains the values to unlock a timebound account at some point in time
     status: the status of the unlock_transaction_function results, returns success or fail
     target_account: the target address used in the unlock_transaction_function
     witness_address: the address of the witness server keypair used to sign this unlock transaction
     timebound: the utc timestame integer of when this unlock will be active
     timenow: just a reference to compare with the timebound above that is Time.now.to_i that also marks the time this transaction was created
     unlock_env_b64: a base64 encoded envelope transaction that contains a transaction that will unlock the target_address after some timebound is reached
     error: if status is failed this will return with the reason the create_unlock_transaction function failed.
       reasons for error include not enuf signers in target account, account not already locked, timebound not > time.now, witness server account not one of the  signers. and maybe a few more.

  Example return: {"acc_info":{"accountid":"GBYX56PB2I3T2W64ZZ62W7X4RUXQZJRR4EG7U4K7SCKDHU3DLM5NPCJM","balance":1219997700,"seqnum":2418066587666,"numsubentries":2,"inflationdest":null,"homedomain":"","thresholds":"AQACAg==","flags":0,"lastmodified":17037},"thresholds":{"master_weight":1,"low":0,"medium":2,"high":2},"signer_info":{"signers":[{"accountid":"GBYX56PB2I3T2W64ZZ62W7X4RUXQZJRR4EG7U4K7SCKDHU3DLM5NPCJM","publickey":"GCYSIZB4Q6ISTHFDXQMBBUPI4BVY7KW6QKCIZKTXAQBDXQYGRRIUTYSX","weight":1},{"accountid":"GBYX56PB2I3T2W64ZZ62W7X4RUXQZJRR4EG7U4K7SCKDHU3DLM5NPCJM","publickey":"GA4GWCCN7YNN5NFUX6MQ3IYPT3LBOFNBRZE3J2JVBJC3P6PNYWWIRPCG","weight":1}]},"timebound":1444648666,"timestamp":"1444648566","witness_account":"GCYSIZB4Q6ISTHFDXQMBBUPI4BVY7KW6QKCIZKTXAQBDXQYGRRIUTYSX","signature":"CsoU4TKWVeJHW8645P6/uHD45QZIaoSIX/Gb9WJqTQEjMjJuCz58j1HF6jmy\nfb/Vrt9P8SNIC0N8hBciLonrAw==\n","unlock":{"status":"success","target_account":"GBYX56PB2I3T2W64ZZ62W7X4RUXQZJRR4EG7U4K7SCKDHU3DLM5NPCJM","witness_address":"GCYSIZB4Q6ISTHFDXQMBBUPI4BVY7KW6QKCIZKTXAQBDXQYGRRIUTYSX","timebound":1444648666,"timenow":1444648566,"unlock_env_b64":"AAAAAHF++eHSNz1b3M59q378jS8MpjHhDfpxX5CUM9NjWzrXAAAAZAAAAjMAAAATAAAAAQAAAABWG5baHPaMEF1SfmQAAAAAAAAAAQAAAAAAAAAFAAAAAAAAAAEAAAAAAAAAAQAAAAAAAAABAAAAAQAAAAEAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAEGjFFJAAAAQGbbtB58wWShTwCWu/1Fd4D9LrrRAgTDt+wsBmhCwAVWbq0hZNFFqlQqa2IkjeiJRfDPu2E9AMz3abwd6yRi0wc="}}

#broadcast: send a custom json packet to all that are presently connected to this mss-server 
  Values sent:
    any custom json index:value set is acceptable and will be echoed accept indexes "action" and "tx_code" due to conflicts in listener apps.
    this disallowed list index values may change in future releases, disallowed indexs are just striped from being sent.
    this can be used to send and recieve authenticated messages or commands to other connected users using lib tools already available.

  Values returned:
    whatever you sent above will be echoed to the sender and everyone connected to the mss-server at the time
  
  Example send:
    {"action":"broadcast", "text_message":"hello world"}

  Example return:
    {"text_message":"hello world"}

TODO: I note in most of my example outputs above I have the output in ruby hash format.  On the wire the values are in JSON I just convert them to hash for most of
my ruby usage and that's what I had as output on my terminal when I was originaly testing them.  sorry if this adds confusion to my docs if used to
operate the API from other languages like java scripts. at some point all the example output in this document should show example output in JSON.

Note: before you run you may need to make some changes to the config file

##  Config file settings explained

default example config file:

db_file_path: /home/sacarlson/github/stellar/stellar_utility/stellar-db2/stellar.db
url_horizon: https://horizon-testnet.stellar.org
url_stellar_core: http://localhost:8080
url_mss_server: "localhost:9494"
mode: localcore
fee: 10
start_balance: 100
default_network: Stellar::Networks::TESTNET
master_keypair: Stellar::KeyPair.master
mss_bind: '0.0.0.0'
mss_port: 9494
mss_db_mode: "sqlite"
mss_db_file_path: "./multisign.db"
version: "5063c84d"
core_version: "85472c7"

many of the values in the default config settings will work for most but some settings need to be customized
values explained

db_file_path: points this to the sqlite database that the local stellar-core is now using on this system
              This setting is only needed if mode is set to "localcore" mode.  in "horizon" mode this value is not used
              only sqlite format is supported at this time, postgress will be added later.

url_horizon: this is the URL of the horizon API instance, this is only needed if you are running in the "horizon" mode
             by default it is set to the horizon testnet setting but can later be pointed to the live network if desired

url_stellar_core: This is the URL or IP address and port that you have the local or even a remote stellar-core running on
                  it is normaly run on the local system so localhost should work but the port can be changed and my settings here are not default to stellers release

url_mss_server:  This is the URL and port that the mulit-sign-websocket will be set to be listening on to recieve action commands

fee: is the fee settings that are used in ruby-stellar-base for transaction fee's, the default in most cases is 100 

start_balance:  is the value in native stellar that will be funded to a newly created stellar account when the create_account function is called
                when a funder keypair is also provided.

default_network:  defines weather the system will be using the stellar testnet or the stellar live network or maybe some third party network
                  it is defaulted to the testnet setting 

master_keypair: this is the account used to fund new accounts when they are created.  it defaults to the master key that on testnet is 
                like the friendbot that provides free testnet native to play with.  on a live net you would set this to an account that 
                has the needed funding to allow account creation only if needed.

mss_bind:  This is the bind address setting for the mss-server.  it determines the listen address of the server that by default is set to 
           all connected networks on the local system.  it can be set to only listen to itself with localhost setting or only on a sigle nic
           on the system.

mss_port:  this is the port that the multi-sign-websocket will be listening on the networks for action commands

mss_db_mode: this is the setting of the type of database backend used in the mss-server, at this time only the sqlite is tested
             but support for postgress has already also been partly setup but not debuged and tested yet. advise only using sqlite at this time

mss_db_file_path: this is the sqlite database file path used in the multi-sign-websocket. be sure the location is read writable under the user you are
                  running the system under.

version:  this is the version stellar-utility git hash number displayed when the "version" action command asks for it.  it should be set to the git
          hash first 8 letters of the stellar-utility you are now using to run mss-server. 

core_version: this is the stellar-core git hash first 8 letters that this system is controling if running in localcore mode


#install and setup
clone the git:
$git clone git@github.com:sacarlson/stellar_utility.git
$cd ./stellar_utility/multi-sing-websocket
$bundle install

start server:
$bundle exec multi-sign-websocket.rb

#dependancies
most if not all of the dependancies should be contained in the Gemfile in this directory
other than that you do need bundler and I also run rbenv with ruby 1.9.3-p484 as default but newer ruby should also work just never tried
 
