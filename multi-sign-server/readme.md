
#Multi Sign Server  also know as mss-server for short

## What is it?
multi-sign-server.rb is a JSON formated curl based API server for the stellar.org networks new stellar-core.
some look at the mss-server as a mini-horizon to allow performing transactions on a remote stellar-core. With all the function it has you might think it's big but it is really only 127kb of my code not counting the added 3rd party and Stellar.org lib support used in it.

## What can it do?
The mss-server can do most any stellar lib function or network transaction including , create key sets, create accounts, send assets from one account to another, change account option settings and signers. It also provides an interface to all the contents of a local stellar-core database to access account asset balances, transaction history and status searches for accounts and memo contents, present buy sell orderbook sorted price searches and much more.  Any data in a local stellar database can now be obtained from the mss-server API interface. The basic function of sending tx base64 blobs and other functions that are normaly done through the horizon server API can also be performed on the mss-server to also provide secure transaction interface.  The secondary goal of mss-server outside of multi sign support is to make it posible to do most anything you can do with a local stellar-core on site over the mss-server API from a remote location instead of running one locally by making all the steller-core database values accesable over the API.  The mss-server also runs in a horizon mode without need for a local stellar-core but in this mode not all functions of database search are active.  


#The mss-server json action command set and format

An example of a basic JSON formated string that is posted to the mss-server looks like this
{"action":"create_keys"}

In this case the "action" code is "create_keys" that needs no added veribles to perform the action of sending this transaction to the
mss-server to get a responce returned that will also be in JSON format.

example if used with curl when used in post mode:
curl -X POST http://zipperhead.ddns.net:9495 -d '{"action":"create_keys"}'

curl responce:
 {"action":"create_keys","secret_seed":"SA3NB4J3SMQWVYBQNPB6CIT6OVQTXIT34EWPTRZF33XNLU44XLOGJIPW","public_address":"GAAXP3IV7HP7QFR5V73236O6WA55XJWWRUM6GC6WPOCZGY3RQVJUS2CK"}

The present action codes and values required for each of them can be seen bellow in the format:

##action_code:    short explaination of what the action code does
  * Values sent: bellow will be the values we send the mss-server in JSON format
    * value_name:  short explaination of what the value name is and does for the action_code
       * as many values as needed for an action
       * ...

  * Value returned: bellow will be what the mss-server returns in JSON format
    * value_name: short explaination of what the value name is and does for the action_code
      * as many returned for this action
      * ...

 * example JSON sent:  showing examples of what is sent of this action in JSON format 
 * example JSON returned:  examples of JSON string returned from mss-server for this action

##core_status: dump the stellar-core info data that is presently hooked to the mss-server
  * Values sent: none

  * Values returned:
    * state: if it's working is should be "Synced!",  if not could be "Catching up", "joining" or other
    * network: this should show if the core is running in "Test SDF Network ; September 2015" for testnet mode,  or somthing Public for Live network
    * build: git version tag or hash of stellar-core now running, normaly tag changes if this version not compatible with last one.
    * other: other values you see you will have to look up in stellar-core docs
 
 * example json output:
 {"info":{"UNSAFE_QUORUM":"ALERT!!! QUORUM UNSAFE","build":"v0.3.0","extra":"Catchup mode 'minimal' awaiting checkpoint (ETA: 204 seconds)","ledger":{"age":7846,"closeTime":1448112595,"hash":"29555b0c689b478d34c16a7116e9e4ec42bd28576ca170eaf476ed6a8a2e24c1","num":876137},"network":"Test SDF Network ; September 2015","numPeers":3,"protocol_version":1,"quorum":{"877928":{"agree":4,"disagree":0,"fail_at":1,"hash":"9548bf","missing":0,"phase":"EXTERNALIZE"}},"state":"Catching up"}}

or if working: 
 {"info":{"UNSAFE_QUORUM":"ALERT!!! QUORUM UNSAFE","build":"v0.3.0","ledger":{"age":3,"closeTime":1448120942,"hash":"84ee9c25dcf271e00e787ce8d86c5012a2f4763bb0a7a022d4267b86d26002a7","num":878056},"network":"Test SDF Network ; September 2015","numPeers":3,"protocol_version":1,"quorum":{"878055":{"agree":4,"disagree":0,"fail_at":1,"hash":"9548bf","missing":0,"phase":"EXTERNALIZE"}},"state":"Synced!"}}

##get_sequence: return the present sequence number for this account
  * Values sent:
    * account: stellar address of the target account

  * Values returned:
    * status: returns success or error if fails
    * action: return "get_sequence" indicating what action is returning values
    * account: same value used in search above
    * sequence: the sequence number seen in stellar-core database for the account at this time 

 * example output:
 {"status":"success", "action":"get_sequence", "account":"GXST...", "sequence"=>"23455.."}

## create_keys: create a stellar keypair secret_seed and public_address
  * Values sent:
    * none

  * Values returned:
    * action: "create_keys"
    * secret_seed:  the stellar secret seed base32 56 letter number part of the key pair, used to create transactions and send funds
    * public_address:  the public address of the stellar account used to receive payment transactions

  * example return:  {"action":"create_keys","secret_seed":"SA3NB4J3SMQWVYBQNPB6CIT6OVQTXIT34EWPTRZF33XNLU44XLOGJIPW","public_address":"GAAXP3IV7HP7QFR5V73236O6WA55XJWWRUM6GC6WPOCZGY3RQVJUS2CK"}

##create_acc: create a multi sign account with the settings of the values given
  * Values sent:
    * master_address: the stellar address of the master creator of the account
    * master_seed:    optional master seed of the master creator of the account (not really needed at this time)
    * signers_total:  total number of signers that will be added to the account
    * thresholds:     threshold settings on the account including
      * master_weight: the signing weight of the master account seed as a signer
      * low:           the threshold for the low setting on this multi sign account
      * med:           the threshold for the med setting 
      * high:          the threshold for the high setting 

  * Values returned:
    * acc_num:  integer of local tx index on this mss-server (not uneque between mss-servers)
    * tx_title: what is now seen as tx_title on this transaction defaults to random 8 letter hash leading with A_
    * master_address:  master_address of what was used to create this account
    * master_seed: master_seed of account that created this account (none really needed)
    * start_balance: setting that were set or defaulted as what to fund the master_address account if created on mss-server
    * signers_total: the number of signers that have been attached to this account
    * thresholds:
    * master_weight: master_weight signing settings for the master_address account
    * master_weight: the signing weight of the master account seed as a signer
      * low:           the threshold for the low setting on this multi sign account
      * med:           the threshold for the med setting 
      * high:          the threshold for the high setting
 
  * example in JSON sent:
{"action":"create_acc","tx_title":"A_M7U2T7UQ","master_address":"GDM6RBPBTDY3YE35I7LLU53LP4IZH26PIFE5IFPITGCEOZBX66IFZIDH","master_seed":"SABKMP7S2A5QUQ2DHNV7HO53EJWUGO7C2BF3WU2RL3YCLGFFCNUOF4KA","start_balance":100,"signers_total":3,"thresholds":{"master_weight":1,"low":"0","med":3,"high":3},"signer_weights":{"GCHOUZUXO2CKBJJICJ6R4EHRLSKCANGD3QTACE5QZJ27T7TSGMD4JP5U":1,"GCFZMOSTNINJB65VOSXY3RKATANT7DQJJVUMJGSXMCAOBUUENSQME4ZZ":1}}
 
  * example in JSON return:
{"acc_num":1,"tx_title":"A_M7U2T7UQ","master_address":"GDM6RBPBTDY3YE35I7LLU53LP4IZH26PIFE5IFPITGCEOZBX66IFZIDH","master_seed":"none_provided","signers_total":"3"}

##send_tx:    send the transaction with this matching tx_code to the stellar-core network for validation (normaly done automaticaly but for test we have this) 
  * Values sent: 
    * tx_code:  is a uneque auto generated code number that starts with T_ example T_RQHKC7XD that are used as references to transactions in the mss-server database

  * Values returned:
    * name:  stellar network error name
    * value: value integer of stellar error code

  * example returned:
 {"name":"tx_bad_seq","value":-5}  //this is what error output looks like if bad transaction sent

##status_tx:  return the status of the transaction in the mss-server db that matches tx_code to find out how many signatures collected or if tx already sent
  * Value sent:
    * tx_code: 

  * Values returned:
    * status: returns pending if not enuf sigs recieved to send transaction, ready if tx has already been sent to network
    *tx_code:

  * example JSON send: 
 {"action":"status_tx","tx_code":"T_RQHKC7XD"}
 
  * example JSON return:
 {"status":"pending","tx_code":"T_RQHKC7XD"} // tx hasn't got all it signatures needed yet
 {"status":"ready","tx_code":"T_RQHKC7XD"}  // this will return if the tx has already been sent to stellar-core network for validation
 
##submit_tx:  adds a new multi sign transaction to the mss-server database with the added values of the veribles attached
  * Values sent:
    * tx_title: an added modifiable title used to help users discribe the transaction, defaults to tx_code 
    * master_address: the stellar multi sign account number
    * tx_envelope_b64: the transaction envelope to be signed by the signers in xdr base 64 format
    * signer_weight:  the signing weight given to the master_address
    * tx_code:  is not entered but is autocreated and added to the mss-server database and returned in responce

  * Values returned:
    * status: pending or ?? when after the system has sent the transaction to the stellar network for validation
    * tx_code: 
    * signer_count:  number of signers that have already signed this transaction (including the master)
    * count_needed: the total number of signers needed for this transaction to be sent to the stellar network for validation
    

  *example JSON send:
{"action":"submit_tx","tx_title":"T_JD7NBZPV","signer_address":"GDM6RBPBTDY3YE35I7LLU53LP4IZH26PIFE5IFPITGCEOZBX66IFZIDH","signer_weight":"1","master_address":"GDM6RBPBTDY3YE35I7LLU53LP4IZH26PIFE5IFPITGCEOZBX66IFZIDH","tx_envelope_b64":"AAAAANnoheGY8bwTfUfWundrfxGT689BSdQV6JmER2Q395BcAAAACgABh04AAAADAAAAAAAAAAAAAAABAAAAAAAAAAUAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAACHRlc3Q1NjkyAAAAAAAAAAAAAAABN/eQXAAAAEBaa64v1Pvh3g0eM1w5g9tlli/O6J0T4FPu9ifle3xGDyOLvGo7W2bpZ+uS9q31se2UMbd5gr0HFPivvuZyanYL","signer_sig_b64":""}

  * example JSON returned:
    {"status":"pending","tx_code":"T_JD7NBZPV","signer_count":1,"count_needed":3}

##get_tx: lookup and return the values found for the transaction with this tx_code from the mss-server database
  * Values sent:
    * tx_code:

  * Values returned:
    * tx_num: an integer tx number used as index on the local mss-server
    * signer: set to 0 if it was signed by master_address, 1 if signed by a signer
    * tx_code: uneque code created as an indentifier to search for transactions over all mss-servers
    * tx_title: user definable to help users explain or identify what the transaction is or what it's for
    * signer_address: a stellar address in base 32 of a signer if this index identifies a signer entry
    * signer_weight: signing weight that this signer has in this transaction
    * master_address: master address of the creator of this transaction
    * tx_envelope_b64: a stellar formated tx envelope in xdr base64 format of the transaction that need to be signed. 


  * example JSON send:
{"action":"get_tx","tx_code":"T_RQHKC7XD"}

  * example return from get_tx:
{"tx_num":1,"signer":0,"tx_code":"T_RQHKC7XD","tx_title":"T_RQHKC7XD","signer_address":"GDM6RBPBTDY3YE35I7LLU53LP4IZH26PIFE5IFPITGCEOZBX66IFZIDH","signer_weight":"1","master_address":"GDM6RBPBTDY3YE35I7LLU53LP4IZH26PIFE5IFPITGCEOZBX66IFZIDH","tx_envelope_b64":"AAAAANnoheGY8bwTfUfWundrfxGT689BSdQV6JmER2Q395BcAAAACgABh04AAAACAAAAAAAAAAAAAAABAAAAAAAAAAUAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAACHRlc3Q3NDM2AAAAAAAAAAAAAAABN/eQXAAAAEB2xFD4v6goEazu9UeLY0naWENxGwDKktFquSF0MJN6MPYrucRuRFzYK/xRofZzl8EIljizva+XBEk/SRioh6QL","signer_sig_b64":""}

##sign_tx: add a signature to a transaction that is already in the mss-server, if no tx_code match is found nothing is done
  * Values sent:
    * tx_code:
    * signer_address: the stellar public address of this signer in base32 format example GCYFPRSLB...
    * signer_weight: the signing weight of this signer (default is 1)
    * tx_title: customisable by the user to add details for other users, not really used by the software
    * signer_sig_b64: the validation signature for this transaction by this signer in xdr base 64 format
    * tx_envelope_b64: optional (no longer used in v2) a signed envelope of the transaction in xdr base 64 format, v2 only needs signer_sig_b64 instead

  * Values returned:
    * status: pending returned if transaction not yet processed by stellar network, ready returned if needed signers have signed tx and tx already sent to network
    * tx_code:  
    
  * example JSON sent:
{"action":"sign_tx","tx_title":"T_RQHKC7XD","tx_code":"T_RQHKC7XD","signer_address":"GCHOUZUXO2CKBJJICJ6R4EHRLSKCANGD3QTACE5QZJ27T7TSGMD4JP5U","signer_weight":"1","tx_envelope_b64":"AAAAANnoheGY8bwTfUfWundrfxGT689BSdQV6JmER2Q395BcAAAACgABh04AAAACAAAAAAAAAAAAAAABAAAAAAAAAAUAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAACHRlc3Q3NDM2AAAAAAAAAAAAAAACcjMHxAAAAEApyJ3gfjYOZaAzY4ZLnt7uJCPrLlR1cPAos4fMRyrBrF2yrfz6U3dsAbv8tpmCMISiS9vZtKExaDZnsqdB1jcEN/eQXAAAAEB2xFD4v6goEazu9UeLY0naWENxGwDKktFquSF0MJN6MPYrucRuRFzYK/xRofZzl8EIljizva+XBEk/SRioh6QL","signer_sig_b64":"cjMHxAAAAEApyJ3gfjYOZaAzY4ZLnt7uJCPrLlR1cPAos4fMRyrBrF2yrfz6U3dsAbv8tpmCMISiS9vZtKExaDZnsqdB1jcE"}

  * example JSON returned:
{"status":"ready","tx_code":"T_RQHKC7XD"}

##get_sorted_holdings: this will search holding in all accounts and return a sorted list of accounts in DESC order of the balance of the target asset
  * Values sent:
    * asset:  the asset symbol of the target search example "native"  or "USD" ...
    * issuer: if the asset is not native then issuer is an option to search with no issuer we will search the asset with any issuer 
    * offset: we will max return the 30 top holdings, offset allows paging down farther in the list

  * Values return:
    * accounts: an array of accounts format depending on weather native or non native asset
      * if the asset is native then the entire accounts table of each found will be added to the accounts array list
      * if the asset is non native then the entire trustlines table for the found asset will be added to the accounts array list
      * index: index is added to the each array to reference offset position in search if any added in offset param
    * status: return success or error
    * error: returns reason for error status if present
 
  * example JSON sent: 
 {"action":"get_sorted_holdings","asset":"AAA"}

 * example return:
 {"accounts":[{"accountid":"GDVYGXTUJUNVSJGNEX75KUDTANHW35VQZEZDDIFTIQT6DNPHSX3I56RY","assettype":1,"issuer":"GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF","assetcode":"AAA","tlimit":9000000000000000000,"balance":10000102300000,"flags":1,"lastmodified":835305,"index":0},{"accountid":"GAMCHGO4ECUREZPKVUCQZ3NRBZMK6ESEQVHPRZ36JLUZNEH56TMKQXEB","assettype":1,"issuer":"GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF","assetcode":"AAA","tlimit":9223372036854775807,"balance":9999897700000,"flags":1,"lastmodified":837690,"index":1}],"action":"get_sorted_holdings","status":"success"}

##get_account_info: dump all data found in stellar-core db in account table. this will not work if mss-server is running in horizon mode
  * Values sent:
    * account: stellar address base 32 example GC3IIU5Q...

  * Values returned:
    * accountid: same as account address base 32
    * action: returns "get_account_info" same as action sent
    * balance:  native balance seen in stellar network in lumens, it returns in floating point decimal format 
    * seqnum: sequence number of this account as seen on the stellar network
    * numsubentries: the number of added signers that are attached to this account
    * inflationdest: account number that this account has voted to be donated the inflation funds
    * homedomain:  a value that can be set to be a nickname or an email or web address to ID the account
    * thresholds: the value that this accounts thresholds are set that is in xdr base64 code
    * flags:  ??
    * lastmodified:  stellar sequence code of last changes made on this account

  * example return:
{"accountid":"GDVYGXTUJUNVSJGNEX75KUDTANHW35VQZEZDDIFTIQT6DNPHSX3I56RY","balance":10001.99964,"seqnum":2757845745401892,"numsubentries":35,"inflationdest":null,"homedomain":"","thresholds":"AQAAAA==","flags":0,"lastmodified":811510,"action":"get_account_info"}

##get_lines_balance:
  * Values sent:
    * account: stellar address base 32 example GCYFPRSLBKM...
    * issuer: stellar address of the issuer of the asset in this balance 
    * asset:  asset name in this balance example USD, YEN, BEER...

  * Values returned:
    * accountid: same as account address base 32 
    * balance: float number of asset balance
    * action: returns "get_lines_balance" same as sent
    * issuer: issuer address of asset
    * assettype: 0 for native, 1 for 4 letter assetcodes like "USD" I think (notsure)
    * assetcode: if assettype 1 or 2 then it will normaly be 3 leter symbol for currency or asset like "USD" "JYN" "BTC" 
    * tlimit: max trust limit on this assetcode issuer pair
    * flags: not sure maybe account lock enable?
    * lastmodified:  last ledger sequence that this trustlines asset entry was modified

  * example return:
{"accountid":"GDVYGXTUJUNVSJGNEX75KUDTANHW35VQZEZDDIFTIQT6DNPHSX3I56RY","assettype":1,"issuer":"GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF","assetcode":"AAA","tlimit":9000000000000000000,"balance":1000010,"flags":1,"lastmodified":835305}

## get_sell_offers: look up all sell offers in offers table that match given search params
  * Values sent:
    * asset: eqivilent to sell_asset in get_offers
    * issuer: equivilent to sell_issuer in get_offers
    * sellerid: optional, if set all orders that match this will be ignored to filter out looking at your own orders
    * limit: optional, limit of the number of offers listed in the stellar-core database max is 30
    * sort: optional,  sort output assending "ASC" or sort desending "DESC" default "ASC"
    * offset: optional, start output from index X, this is used to page through output that has more than 10 elements that is max output

  * Values returned:
    * same as get_offers bellow

## get_buy_offers: look up all buy offers in offers table that match given search params
  * Values sent:
    * asset: eqivilent to buy_asset in get_offers
    * issuer: equivilent to buy_issuer in get_offers
    * sellerid: optional, if set all orders that match this will be ignored to filter out looking at your own orders
    * limit: optional, limit of the number of offers listed in the stellar-core database max is 30
    * sort: optional,  sort output assending "ASC" or sort desending "DESC" default "ASC"
    * offset: optional, start output from index X, this is used to page through output that has more than 10 elements that is max output

  * Values returned:
    * same as get_offers bellow

##get_offers: look up all offers in offers table that match given search params
 * note: revised replacement for "get_offerid"
  * Values sent:
    * sellerid: optional, if set all orders that match this will be ignored to filter out looking at your own orders
    * offerid: optional, if set all other input values are ignored and will search for the single matching offerid offer order
    * sell_asset_type: optional, if set it will look for matches of asset types on sell asset that can be "0" for native, "1" for 4 letter asset type,  "2" ??
    * sell_asset: optional, sell asset type example USD, if not set will search through all assets on this sell_issuer
    * sell_issuer: optional, stellar address of the selling issuer of the asset in this search, if not set will search through all issures on this asset
    * buy_asset_type: optional, if set it will look for matches of asset types on buy asset that can be "0" for native, "1" for 4 letter asset type, "2" ??
    * buy_asset:  optional, example USD, if not set will search through all assets on the buy_issuer
    * buy_issuer: optional, stellar address of the buying issuer of the asset in this search, if not set will search through all issures on this asset
    * limit: optional, limit of the number of offers listed in the stellar-core database max is 30
    * sort: optional,  sort output assending "ASC" or sort desending "DESC" default "ASC"
    * offset: optional, start output from index X, this is used to page through output that has more than 10 elements that is max output

  * Values returned:
    * count: total number of orders found with these search params
    * orders: an array of orders found with these search params
      * sellerid: stellar account address making this order
      * offerid: index number of the offer in the stellar database
      * sellingassettype: 0 for native  1 - 2 depends on weather 4 or 12 letter asset name
      * sellingassetcode: asset code that they are selling example "USD"
      * sellingissuer:  issuer address of the asset they are offering to selling
      * buyingassettype: 0 for native  1 - 2 depends on weather 4 or 12 letter asset name
      * buyingassetcode: asset code that they are buying example "USD"
      * buyingissuer: issuer address of the asset they are offering to buying
      * amount: the quantity of the asset we are offering to sell
      * pricen: price numerator of the asset price being offered to sell
      * priced: price denominator of the asset price being offered to sell
      * price: the price per unit of the asset being offered for sale based on the selling asset
      * flags: ?? it's in the stellar database but I don't know what it is
      * lastmodified: the last ledgerseq number that this assest order was modified.
      * index: this is the index position of this search with these search params, to indicate position in page depending on offset, this starts from zero
      * inv_base_price: is the 1/price to view what order would look like if reversed
      * inv_base_amount: is 1/amount to view what order would look like if reversed 

  * example input:
    {"action":"get_offers" , "sell_asset":"BBB","sell_amount":4,  "buy_asset":"AAA"}

  * example return:
   {"orders":[{"sellerid":"GDVYGXTUJUNVSJGNEX75KUDTANHW35VQZEZDDIFTIQT6DNPHSX3I56RY","offerid":14,"sellingassettype":1,"sellingassetcode":"BBB","sellingissuer":"GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF","buyingassettype":1,"buyingassetcode":"AAA","buyingissuer":"GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF","amount":1.0,"pricen":2,"priced":1,"price":2.0,"flags":0,"lastmodified":642332,"index":0,"inv_base_amount":1.0,"inv_base_price":0.5},{"sellerid":"GDVYGXTUJUNVSJGNEX75KUDTANHW35VQZEZDDIFTIQT6DNPHSX3I56RY","offerid":18,"sellingassettype":1,"sellingassetcode":"BBB","sellingissuer":"GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF","buyingassettype":1,"buyingassetcode":"AAA","buyingissuer":"GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF","amount":1.0,"pricen":2,"priced":1,"price":2.0,"flags":0,"lastmodified":642352,"index":1,"inv_base_amount":1.0,"inv_base_price":0.5}]

## get_market_price: get info from offers table of the averge price and the max bid needed to setup an order for a certain amount of one asset for another
  * Values sent:
    * sellerid: optional, if set all orders that match this will be ignored to filter out looking at your own orders
    * offerid: optional, if set all other input values are ignored and will search for the single matching offerid
    * sell_asset_type: optional, if set it will look for matches of asset types on sell asset that can be "0" for native, "1" for 4 letter asset type,  "2" ??
    * sell_asset: optional, sell asset type example USD, if not set will search through all assets on this sell_issuer
    * sell_issuer: optional, stellar address of the selling issuer of the asset in this search, if not set will search through all issures on this asset
    * sell_amount: the quantity of the sell_asset you want to trade for the buy_asset
    * buy_asset_type: optional, if set it will look for matches of asset types on buy asset that can be "0" for native, "1" for 4 letter asset type, "2" ??
    * buy_asset:  optional, example USD, if not set will search through all assets on the buy_issuer
    * buy_issuer: optional, stellar address of the buying issuer of the asset in this search, if not set will search through all issures on this asset
    * limit: optional, limit of the number of offers listed in the stellar-core database max is 30
    * sort: optional,  sort output assending "ASC" or sort desending "DESC" default "ASC"
    * offset: optional, start output from index X, this is used to page through output that has more than 10 elements that is max output

  * Values returned:
    * action: returns "get_market_price"
    * sell_asset: the sell_asset used in the search
    * buy_asset: the buy_asset used in the search
    * averge_price: the averge price that 1 buy asset order would end up costing on this sell_amount
    * max_bid: the max bid is what would be required to bid on the asset to end up with the amount you are asking for
    * status: return "success" or "error" or "not_liquid" depending on results of search, not_liquid means there are not that many open orders for the buy_asset
    * total_amount: the total number of buy asset shares seen on the books at this time with these search params
    * amount_available: if status returns "not_liquid" this returns the total number of buy asset shares available on the books 
    * max_sell_amount: if status returns "not_liquid" then this will return showing the max amount of sell asset you can sell to buy all available buy asset

  * example input:
{"action":"get_market_price","sell_asset":"BBB","sell_issuer":"GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF","buy_asset":"AAA","buy_issuer":"GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF","sell_amount":"10","sellerid":"GCL2C4ESE5PQ6GHGQUYVJ2EFH42FEHCN4LOAWYZTKTVEBCZ2GSQD66T4"}

  * example returns:
{"action":"get_market_price","buy_asset":"AAA","sell_asset":"BBB","averge_price":3.5999999880000004,"max_bid":5.0,"amount":10.0,"total_amount":5.3333334,"status":"success"} {"action":"get_market_price","buy_asset":"AAA","sell_asset":"BBB","averge_price":4.1249999859375,"max_bid":5.0,"amount":24.0,"amount_available":5.3333334,"max_sell_amount":22.000000200000002,"status":"not_liquid"}

##version: return the version git hash of stellar-utility and the stellar-core that it is operating
  * Values sent:
    * no values needed
  
  * Values returned:
    * status: returns "success" if mss-server is working correctly
    * version: values of the git hash for stellar_utility package and git hash for the stellar-core that it is controling if available

  * example return:
 {"status":"success", "version":"su: 0.1.0  mss_version: 5063c84d core_version: 85472c7"}


##send_b64: send an envelope blob to the stellar-core network
  * Values sent:
    * envelope_b64: the envelope blob to be sent that is in xdr base 64 format, this can be any transaction that the signer of the envelope has authority to do

  * Value returned:
    * action: returns "send_b64"
    * status: returns success or error
    * error: return depends on results from stellar-core normaly decoded to names, or timeout error from coms to stellar-core

  * example input:
 {"action":"send_b64", "envelope_b64":"AAAAABgjmdwgqRJl6q0FDO2xDlivEkSFTvjnfkrplpD99NioAAAAZAAJzDsAAAArAAAAAAAAAAEAAAAOc2NvdHR5X2lzX2Nvb2wAAAAAAAEAAAAAAAAAAQAAAADrg150TRtZJM0l/9VQcwNPbfawyTIxoLNEJ+G155X2jgAAAAFBQUEAAAAAAC/BUSR1Aa+wZ5rlARYmg8lxC8ZjtP1PIjfQQOUEM9w/AAAAAACYloAAAAAAAAAAAf302KgAAABA4lpggncXmx6VhSCgfmzstgK6+UvpaNkdiUVfRaQH8hMJXdNI8spNB/qL8VMn10HFkp0YFl+8cCPGPUjUUYOEAA=="}

  * example output:
   {"status":"error","action":"send_b64","error":{"name":"tx_bad_seq","value":-5}}
   {"status":"success","action":"send_b64"}

##send_native: send a native XLM transaction from one account to another using key seed 
  * Values sent:
    * from_seed: the secreet seed of the account sending the funds
    * to_account: the stellar public address of the account we are sending the funds to
    * amount: the amount of XLM or native currency being sent to the to_account
    * memo_text: a string that can be a message sent with the transaction

  * example output:
  {"action":"send_native", "from_seed":"SA3CKS64WFRWU7FX2AV6J6TR4D7IRWT7BLADYFWOSJGQ4E5NX7RLDAEQ", "to_account": "GDVYGXTUJUNVSJGNEX75KUDTANHW35VQZEZDDIFTIQT6DNPHSX3I56RY", "amount":"1.25"}

  * example return:
  {"txid":"bbbaa3ce05bf99c66cd5221b5e7c2fb05f53e1edff86a55907336c9d7dcc3296","ledgerseq":1102980,"txresult":"u7qjzgW/mcZs1SIbXnwvsF9T4e3/hqVZBzNsnX3MMpYAAAAAAAAAZAAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAA==","body":{"status":"PENDING"},"resultcode":{"name":"tx_success","value":0},"action":"send_b64","status":"success"}

  Note: this method may be ok for a server to be sending fund to a client but not a very secure method to be used from the client side.  On the client side I recomend using the stellar libs like stellar-sdk.js to prevent the server side from every haveing access to the secreet key seed of the clients.

##send_asset: send a non native asset transaction from one account to another using key seed 
  * Values sent:
    * from_seed: the secreet seed of the account sending the funds
    * to_account: the stellar public address of the account we are sending the funds to
    * amount: the amount of the asset or currency being sent to the to_account
    * issuer: the stellar public address of the issuer of the asset to be sent
    * assetcode: the asset code of the asset being sent example USD, EUR ...
    * memo_text: a string that can be a message sent with the transaction

  * example output:
  {"action":"send_asset", "from_seed":"SA3CKS64WFRWU7FX2AV6J6TR4D7IRWT7BLADYFWOSJGQ4E5NX7RLDAEQ", "to_account": "GDVYGXTUJUNVSJGNEX75KUDTANHW35VQZEZDDIFTIQT6DNPHSX3I56RY","issuer":"GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF", "assetcode":"AAA", "amount":"1.25"}

  * example return:
  {"txid":"bbbaa3ce05bf99c66cd5221b5e7c2fb05f53e1edff86a55907336c9d7dcc3296","ledgerseq":1102980,"txresult":"u7qjzgW/mcZs1SIbXnwvsF9T4e3/hqVZBzNsnX3MMpYAAAAAAAAAZAAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAA==","body":{"status":"PENDING"},"resultcode":{"name":"tx_success","value":0},"action":"send_b64","status":"success"}

##get_signer_info: get a list of all the signers on this target account direct from the stellar network database
  * Values sent:
    * account: the target account for the information 

  * Values returned:
    * signers: an array signer hashes the length depending on how many signers the account has
    * accountid: the same as the target account
    * publickey: the address of this signer
    * weight:  the signing weight that this signer has on this account

  * example return:
  {"signers"=>[{"accountid"=>"GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO", "publickey"=>"GBT6G2KZI4ON3LTVRWEPT3GH66TTBTN77SIHRGNQ4KAU7N3GTFLYXYOM", "weight"=>1}]}

##get_thresholds_info: get the threshold values for this account direct from the stellar database
  * Values sent:
    * account: the target account for the information wanted

  * Values returned:
    * master_weight:  the master signing weight, the signing power that this target account keypair has on this account
    * low: the threshold of low
    * medium: the threshold for medium security, needed to sign transactions to send payments and other
    * high:  the threshold for high security,  needed when you want to sign transactions to change thresholds 
    * action: returns "get_thresholds_info"
  * example return:
    {"action":"get_thresholds_info","master_weight":1, "low":0, "medium":0, "high":0}

##get_issuer_debt: return totals of all asset debts for this issuer account for each asset issued 
  * Values sent:
   * issuer: the target issuer account for totaled debts

  * Values returned
   * status: returns success or fail if problems in search detected
   * debt: return a hash with a group of key value sets of asset name and debt in each
   * issuer: the issuer account address that the search was run with

  * example input:
  {"action":"get_issuer_debt", "issuer":"GAMB56CPYXJZUM2QSWXTUFSFIWMNHB6GZBUFJ2YJQJRGW6WH223NRLND"}

  * example return:
  {"status":"success", "debt":{"CHP":200110.12,"USD":300}, "issuer","GAMB56CPYXJZUM2QSWXTUFSFIWMNHB6GZBUFJ2YJQJRGW6WH223NRLND"} 

##get_tx_offer_hist: get info from txhistory table filter info using optional search params
  * Values sent:
    * sell_asset_type: optional, if set it will look for matches of asset types on sell asset that can be "0" for native, "1" for 4 letter asset type,  "2" ??
    * sell_asset: optional, sell asset type example USD, if not set will search through all assets on this sell_issuer
    * sell_issuer: optional, stellar address of the selling issuer of the asset in this search, if not set will search through all issures on this asset
    * buy_asset_type: optional, if set it will look for matches of asset types on buy asset that can be "0" for native, "1" for 4 letter asset type, "2" ??
    * buy_asset:  optional, example USD, if not set will search through all assets on the buy_issuer
    * buy_issuer: optional, stellar address of the buying issuer of the asset in this search, if not set will search through all issures on this asset
    * limit: optional, limit of the number of offers listed in the stellar-core database max is 30
    * sort: optional,  sort output assending "ASC" or sort desending "DESC" default "ASC"
    * offset: optional, start output from index X, this is used to page through output that has more than 10 elements that is max output
    * closed: if set to "true" only returns offers that have been canceled when an offer_id = 0 is returned, if set "false" only return offers that have executed trades. if not set (nil) will return all offers in history
  * Values returned:
   * TBD

  * example input:
 {"action":"get_tx_offer_hist","sell_asset":"BBB","sell_issuer":"GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF","closed":"true"}

  * example return:
 {"txhistory":[{"source_address":"GCL2C4ESE5PQ6GHGQUYVJ2EFH42FEHCN4LOAWYZTKTVEBCZ2GSQD66T4","fee":100,"seq_num":4943404278480914,"memo_type":"memo_none","op_length":1,"operations":[{"operation":"manage_offer_op","selling.asset":"BBB\u0000","selling.issuer":"GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF","buying.asset":"AAA\u0000","buying.issuer":"GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF","amount":1.0,"price":{"attributes":{"n":1,"d":2}},"offer_id":0}],"txresults":"tx_success","index":0,"txid":"c23ae0e216b99de57263afed9b88cffed5d9d8efda3ad01d2a8c00f0bcf7f745","ledgerseq":1165140}]}

##get_tx_hist: get info from  txhistory table of stellar-core db for search params given max return 10 last transactions.
 results are sorted in last transaction performed is on top of search, this is the new improved version of get_tx_hist...

  * Values sent: note if txid = "all" then all transactions sorted by last ledger sequence first, max 30 results at a time returned
    * txid: if txid input is present it will override all other input values and just get this txid as the return, or if set to  "all" will return all txid
    * source_address: source_address of the transaction target account to search
    * destination_address: destination_address of the transaction target account search
    * memo_text: add to list if memo_text string matches a type memo_text memo in a transaction, if memo_text is nil then memo_text will be ignored
    * memo_id: add to list if memo_id number integer matches a type memo_id memo in a transaction, if memo_id is nil then memo_id will be ignored
    * memo: add to list if the contents of ether type memo_text or memo_id when converted to string match the contents 
    * memo_type: add to list if memo_type of or one of the type including memo_text, memo_id, memo_hash, memo_return matches
    * offset: offset in search results to allow paging through more than 30 resulting transactions a search

  * Values return:
    * txhistory: and array of tx history events
    * source_address: the source accountid that this transaction was sent from
    * fee: fee paid in this transaction
    * seq_num: the sequence number of this transaction
    * memo_type: if memo is present in transaction this returns type of memo_text, memo_id, memo_hash, memo_return, memo_none
    * memo_text: returns a string with value of memo_text if a memo_text type memo is found in the tx
    * memo_id: returns an integer number value of memo_id if a memo_id type memo is found in the tx
    * memo_value: always returns a string of the contents of eather memo_text string or memo_id number converted to string
    * op_length:
    * txresults: operation tx_success or fail results
    * ledgerseq: the ledger sequence that the transaction was performed
    * txid: the txid hash unique id of the transaction
    * index: index count of the search result used in offset for page sync to search more than one page of 10 
    * operations: an array of operations in this transaction
      * operation: name of the operation being performed
      * destination_address: destination of were the transaction will be sending assets to
      * other:  depends on the transaction what info is provided

  * example input:
    {"action":"get_tx_hist", "destination_address":"GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO","memo_text":"sacarlson"}

  * example outpt:
  {"txhistory":[{"source_address":"GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H","fee":100,"seq_num":7300,"memo.type":"memo_text","memo.text":"sacarlson","op_length":1,"operations":[{"operation":"payment_op","destination_address":"GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO","asset":"native","amount":1.0}],"txresults":{"name":"tx_success","value":0},"index":0}]}

##get_tx_history: get the transaction history for this txid direct from the stellar database
* note this is depricated and will later be removed see get_tx_hist above that replaces this 

  * Values sent:
    * txid: the transaction number for the target transaction as seen in the stellar database

  * Values return:
    * txid: the txid of what is being searched for
    * ledgerseq: the ledger sequence number of when this transaction was recorded
    * txresult: a base64 encoded txresult seen on the stellar database server, note I should have decoded this for humans as the tools are already available in the libs

  * example return:
   {"txid"=>"258fbbfb105a99d63665c31ef46cf721446835985103f37de934842fbd68cff6", "ledgerseq"=>4417, "txresult"=>"JY+7+xBamdY2ZcMe9Gz3IURoNZhRA/N96TSEL71oz/YAAAAAAAAAZAAAAAAAAAABAAAAAAAAAAUAAAAAAAAAAA=="} 

##get_account_tx_history: get the tx history from stellar-core db for this account max return 10 last transactions
  results are sorted in last transaction performed is on top of search
* this is old depricated version see get_tx_hist instead

  * Values sent:
    * account: address of the target account to search
    * offset: offset in search results to allow pageing through more than 10 resulting transactions in a search

  * Values return:
    * txhistory: and array of tx history events
      * source_address:
      * fee:
      * seq_num:
      * memo.type:
      * memo.text:
      * op_length:
      * txresults: operation tx_success or fail results
      * index: index count of the search result used in offset for page sync
      * operations: an array of operations in this transaction
        * operation: name of the operation being performed
        * destination_address: destination of were the transaction will be sending assets to
        * other:  depends on the transaction what info is provided

  * example input:
    {"action":"get_account_tx_history", "account":"GBS43BF24ENNS3KPACUZVKK2VYPOZVBQO2CISGZ777RYGOPYC2FT6S3K"}

  * example output:
{"txhistory":[{"source_address":"GBS43BF24ENNS3KPACUZVKK2VYPOZVBQO2CISGZ777RYGOPYC2FT6S3K","fee":100,"seq_num":55834576679,"memo.type":"memo_none","op_length":1,"operations":[{"operation":"create_account_op","destination_address":"GCURQA6KDN4WZ4L72WSSULRLBVIUXSZY6UII47KUO2FCTBEV6VGMKTHT","starting_balance":10000.0}],"txresults":{"name":"tx_success","value":0},"index":0},{"source_address":"GBS43BF24ENNS3KPACUZVKK2VYPOZVBQO2CISGZ777RYGOPYC2FT6S3K","fee":100,"seq_num":55834576678,"memo.type":"memo_none","op_length":1,"operations":[{"operation":"create_account_op","destination_address":"GCV7QHICOQC56AVQAZ2RAWOTFISTW2VGE5YBYR33RXOGZRJZ24SHEJYE","starting_balance":10000.0}],"txresults":{"name":"tx_success","value":0},"index":1},{"source_address":"GBS43BF24ENNS3KPACUZVKK2VYPOZVBQO2CISGZ777RYGOPYC2FT6S3K","fee":100,"seq_num":55834576677,"memo.type":"memo_none","op_length":1,"operations":[{"operation":"create_account_op","destination_address":"GANLZNTOEPQNGNN3LQQ6KSYBYPRZNGCGPTATDZPZSWZADBXIOZCMK5YE","starting_balance":10000.0}],"txresults":{"name":"tx_success","value":0},"index":2},{"source_address":"GBS43BF24ENNS3KPACUZVKK2VYPOZVBQO2CISGZ777RYGOPYC2FT6S3K","fee":100,"seq_num":55834576676,"memo.type":"memo_none","op_length":1,"operations":[{"operation":"create_account_op","destination_address":"GAE7UIEUGV34OQTO6ADF5GI6BYCMUXH7MLFQZXRFGZTSUR6EX2YG5OPL","starting_balance":10000.0}],"txresults":{"name":"tx_success","value":0},"index":3},{"source_address":"GBS43BF24ENNS3KPACUZVKK2VYPOZVBQO2CISGZ777RYGOPYC2FT6S3K","fee":100,"seq_num":55834576675,"memo.type":"memo_none","op_length":1,"operations":[{"operation":"create_account_op","destination_address":"GCIKTYFHX653TPU77WWUSYVCXIRQ555DTT3D35TAB7DRFFGOPBK7NT2J","starting_balance":10000.0}],"txresults":{"name":"tx_success","value":0},"index":4},{"source_address":"GBS43BF24ENNS3KPACUZVKK2VYPOZVBQO2CISGZ777RYGOPYC2FT6S3K","fee":100,"seq_num":55834576674,"memo.type":"memo_none","op_length":1,"operations":[{"operation":"create_account_op","destination_address":"GDUPMCWFBPNQ6RGMN5KRMT7XPQF6NATBAWXSXZ7REQEP7ULGPRF2B4DO","starting_balance":10000.0}],"txresults":{"name":"tx_success","value":0},"index":5},{"source_address":"GBS43BF24ENNS3KPACUZVKK2VYPOZVBQO2CISGZ777RYGOPYC2FT6S3K","fee":100,"seq_num":55834576673,"memo.type":"memo_none","op_length":1,"operations":[{"operation":"create_account_op","destination_address":"GBVWKA2I3UMJGCVSCH2CBYIRHTXDZAELAGD6W4C6GOQNNRKZ4CQIJAGD","starting_balance":10000.0}],"txresults":{"name":"tx_success","value":0},"index":6},{"source_address":"GBS43BF24ENNS3KPACUZVKK2VYPOZVBQO2CISGZ777RYGOPYC2FT6S3K","fee":100,"seq_num":55834576672,"memo.type":"memo_none","op_length":1,"operations":[{"operation":"create_account_op","destination_address":"GD6LPAPIARMYXBB4OBPAVRKSTFSEQYBBLKV7SPVNHBGAP6BS5Y7HFL5K","starting_balance":10000.0}],"txresults":{"name":"tx_success","value":0},"index":7},{"source_address":"GBS43BF24ENNS3KPACUZVKK2VYPOZVBQO2CISGZ777RYGOPYC2FT6S3K","fee":100,"seq_num":55834576671,"memo.type":"memo_none","op_length":1,"operations":[{"operation":"create_account_op","destination_address":"GCDJ34UURDZZVR7GN7DV7DT66WF46DLVCGHFX7RFQCADVS4F6LVZ6EZO","starting_balance":10000.0}],"txresults":{"name":"tx_success","value":0},"index":8},{"source_address":"GBS43BF24ENNS3KPACUZVKK2VYPOZVBQO2CISGZ777RYGOPYC2FT6S3K","fee":100,"seq_num":55834576480,"memo.type":"memo_none","op_length":1,"operations":[{"operation":"create_account_op","destination_address":"GBM7MDOGHTD2GRXR3WG3GHXKBWOHK7QULDLG7FRMGIY7RBAWWOR6L56G","starting_balance":10000.0}],"txresults":{"name":"tx_success","value":0},"index":9},{"source_address":"GBS43BF24ENNS3KPACUZVKK2VYPOZVBQO2CISGZ777RYGOPYC2FT6S3K","fee":100,"seq_num":55834576479,"memo.type":"memo_none","op_length":1,"operations":[{"operation":"create_account_op","destination_address":"GBLXXXA3S54K7Z2FGOXRMYSKXEOQVDSKZ6EWGGSMQT7HGFGO2TPBMAZ2","starting_balance":10000.0}],"txresults":{"name":"tx_success","value":0},"index":10}]}  


##make_unlock_transaction: create a env_b64 time bound transaction that will be used to unlock a locked account after some window of time
  * Values sent:
    * account: the target_account that will later be locked to be unlocked with this transaction
    * timebound: UTC timestamp integer at witch time this transaction will become valid
    * asset: the asset symbol whose holdings snapshot will be added to the witness section of the output json witness document
    * issuer: issuer address of the asset above

  * Values return:
    * status: returns success or fail depending on if account and input settings above were within specs
    * target_account: the account that the unlock transaction will unlock
    * timebound:  this is the UTC time stamp of when unlock_env_b64 transaction begins to be valid on the stellar network
    * timenow:  this is the UTC time stamp of what time it is now just used as a reference to the above to compare
    * unlock_env_b64: a transaction envelope in base64 format that will be sent after the timebound time to unlock the target_account

  * Example return:
    * TBD

##make_witness: will create a signed timestamped document of the present state and ballances of a target account
  * Values sent:
    * account: that target account that the document will be write for

  * Values return:
    * accountid: the target account id address
    * balance: the native balance on this account
    * seqnum:  the sequence number of the account as seen at the moment the document was recorded 
    * numsubentries: the number of signers seen on the account at time of recording
    * inflationdest: setting of the inflation destination at time or recording
    * homedomain:  home domain setting on the account
    * master_weight:  the master weight setting on the account
    * low:  theshold setting for the low threshold
    * medium:  theshold setting for the medium threshold
    * high:   threhold setting for the high threshold
    * signers: number of signers returned depends on what the account presently holds, this is an array of signers and there weights
    * accountid: same as above target account address  
    * publickey: the public key address of this signer 
    * weight: the weight that this signer has on this account when signing transactions
    * timestamp: the UTC integer timestamp value at the time this record was created
    * witness_account: the stellar account number of the pair that was used to signed this witness document
    * signature: base64 signature of all the information in the above values and anything else added to the hash signed by the witness_account keypair
    * this hash and signing can be validated on the user side in ruby with the function Utils.check_witness_hash(hash)

  * Example return: {"acc_info":{"accountid":"GBYX56PB2I3T2W64ZZ62W7X4RUXQZJRR4EG7U4K7SCKDHU3DLM5NPCJM","balance":1219997700,"seqnum":2418066587666,"numsubentries":2,"inflationdest":null,"homedomain":"","thresholds":"AQACAg==","flags":0,"lastmodified":17037},"thresholds":{"master_weight":1,"low":0,"medium":2,"high":2},"signer_info":{"signers":[{"accountid":"GBYX56PB2I3T2W64ZZ62W7X4RUXQZJRR4EG7U4K7SCKDHU3DLM5NPCJM","publickey":"GCYSIZB4Q6ISTHFDXQMBBUPI4BVY7KW6QKCIZKTXAQBDXQYGRRIUTYSX","weight":1},{"accountid":"GBYX56PB2I3T2W64ZZ62W7X4RUXQZJRR4EG7U4K7SCKDHU3DLM5NPCJM","publickey":"GA4GWCCN7YNN5NFUX6MQ3IYPT3LBOFNBRZE3J2JVBJC3P6PNYWWIRPCG","weight":1}]},"timebound":null,"timestamp":"1444647586","witness_account":"GCYSIZB4Q6ISTHFDXQMBBUPI4BVY7KW6QKCIZKTXAQBDXQYGRRIUTYSX","signature":"IGPRXS9aNos5BaYrlwa5kSTdhlZkVsBPKQeP2Ho3DWftJVo7MLTe8LQpZZ0r\nIoxyWA5r1/WJZ9DGwODTh0wvCw==\n"}


##make_witness_unlock: this preforms two actions as it does the same as the above make_witness but also records timestamp and timebound in the mss server database
                      it also creates and adds an unlock transacton that is timebound per the users request
  * Values sent:
    * account: that target account that the document will be write for
    * timebound: a utc timestamp integer specifing the start time that the unlock tx that will be returned will become active to unlock the account

  * Values returned:
    * Values return:
    * accountid: the target account id address
    * balance: the native balance on this account
    * seqnum:  the sequence number of the account as seen at the moment the document was recorded 
    * numsubentries: the number of signers seen on the account at time of recording
    * inflationdest: setting of the inflation destination at time or recording
    * homedomain:  home domain setting on the account
    * master_weight:  the master weight setting on the account
    * low:  theshold setting for the low threshold
    * medium:  theshold setting for the medium threshold
    * high:   threhold setting for the high threshold
    * signers: number of signers returned depends on what the account presently holds, this is an array of signers and there weights
    * accountid: same as above target account address  
    * publickey: the public key address of this signer 
    * weight: the weight that this signer has on this account when signing transactions
    * timebound: the UTC integer timestamp of the start time that the unlock_env_b64 transaction will become valid on the stellar network to unlock the account
    * timestamp: the UTC integer timestamp value at the time this record was created
    * witness_account: the stellar account number of the pair that was used to signed this witness document
    * signature: base64 signature of all the information in the above values and anything else added to the hash signed by the witness_account keypair
    * this hash and signing can be validated on the user side in ruby with the function Utils.check_witness_hash(hash)
    * unlock: is the hash returned from the create_unlock_transaction function, it contains the values to unlock a timebound account at some point in time
    * status: the status of the unlock_transaction_function results, returns success or fail
    * target_account: the target address used in the unlock_transaction_function
    * witness_address: the address of the witness server keypair used to sign this unlock transaction
    * timebound: the utc timestame integer of when this unlock will be active
    * timenow: just a reference to compare with the timebound above that is Time.now.to_i that also marks the time this transaction was created
    * unlock_env_b64: a base64 encoded envelope transaction that contains a transaction that will unlock the target_address after some timebound is reached
    * error: if status is failed this will return with the reason the create_unlock_transaction function failed.
       reasons for error include not enuf signers in target account, account not already locked, timebound not > time.now, witness server account not one of the  signers. and maybe a few more.

  * Example return: {"acc_info":{"accountid":"GBYX56PB2I3T2W64ZZ62W7X4RUXQZJRR4EG7U4K7SCKDHU3DLM5NPCJM","balance":1219997700,"seqnum":2418066587666,"numsubentries":2,"inflationdest":null,"homedomain":"","thresholds":"AQACAg==","flags":0,"lastmodified":17037},"thresholds":{"master_weight":1,"low":0,"medium":2,"high":2},"signer_info":{"signers":[{"accountid":"GBYX56PB2I3T2W64ZZ62W7X4RUXQZJRR4EG7U4K7SCKDHU3DLM5NPCJM","publickey":"GCYSIZB4Q6ISTHFDXQMBBUPI4BVY7KW6QKCIZKTXAQBDXQYGRRIUTYSX","weight":1},{"accountid":"GBYX56PB2I3T2W64ZZ62W7X4RUXQZJRR4EG7U4K7SCKDHU3DLM5NPCJM","publickey":"GA4GWCCN7YNN5NFUX6MQ3IYPT3LBOFNBRZE3J2JVBJC3P6PNYWWIRPCG","weight":1}]},"timebound":1444648666,"timestamp":"1444648566","witness_account":"GCYSIZB4Q6ISTHFDXQMBBUPI4BVY7KW6QKCIZKTXAQBDXQYGRRIUTYSX","signature":"CsoU4TKWVeJHW8645P6/uHD45QZIaoSIX/Gb9WJqTQEjMjJuCz58j1HF6jmy\nfb/Vrt9P8SNIC0N8hBciLonrAw==\n","unlock":{"status":"success","target_account":"GBYX56PB2I3T2W64ZZ62W7X4RUXQZJRR4EG7U4K7SCKDHU3DLM5NPCJM","witness_address":"GCYSIZB4Q6ISTHFDXQMBBUPI4BVY7KW6QKCIZKTXAQBDXQYGRRIUTYSX","timebound":1444648666,"timenow":1444648566,"unlock_env_b64":"AAAAAHF++eHSNz1b3M59q378jS8MpjHhDfpxX5CUM9NjWzrXAAAAZAAAAjMAAAATAAAAAQAAAABWG5baHPaMEF1SfmQAAAAAAAAAAQAAAAAAAAAFAAAAAAAAAAEAAAAAAAAAAQAAAAAAAAABAAAAAQAAAAEAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAEGjFFJAAAAQGbbtB58wWShTwCWu/1Fd4D9LrrRAgTDt+wsBmhCwAVWbq0hZNFFqlQqa2IkjeiJRfDPu2E9AMz3abwd6yRi0wc="}}

##broadcast: send a custom json packet to all that are presently connected to this mss-server 
  * Values sent:
    * any custom json index:value set is acceptable and will be echoed accept indexes "action" and "tx_code" due to conflicts in listener apps.
    * this disallowed list index values may change in future releases, disallowed indexs are just striped from being sent.
    * this can be used to send and recieve authenticated messages or commands to other connected users using lib tools already available.

  * Values returned:
    * whatever you sent above will be echoed to the sender and everyone connected to the mss-server at the time
  
  * Example send:
    {"action":"broadcast", "text_message":"hello world"}

  * Example return:
    {"text_message":"hello world"}

##########TODO: I note in most of my example outputs above I have the output in ruby hash format.  On the wire the values are in JSON I just convert them to hash for most of
my ruby usage and that's what I had as output on my terminal when I was originaly testing them.  sorry if this adds confusion to my docs if used to
operate the API from other languages like java scripts. at some point all the example output in this document should show example output in JSON.


##Note: before you run you may need to make some changes to the config file

##  Config file settings explained

####default example config file:

db_file_path: /home/sacarlson/github/stellar/stellar_utility/stellar-db2/stellar.db
url_horizon: https://horizon-testnet.stellar.org
url_stellar_core: http://localhost:8080
url_mss_server: "localhost:9494"
mode: localcore
fee: 100
start_balance: 100
default_network: Stellar::Networks::TESTNET
master_keypair: Stellar::KeyPair.master
mss_bind: '0.0.0.0'
mss_port: 9494
mss_db_mode: "sqlite"
mss_db_file_path: "./multisign.db"
version: "5063c84d"
core_version: "85472c7"

#### many of the values in the default config settings will work for most but some settings need to be customized
values explained

* db_file_path: points this to the sqlite database that the local stellar-core is now using on this system
              This setting is only needed if mode is set to "localcore" mode.  in "horizon" mode this value is not used
              only sqlite format is supported at this time, postgress will be added later.

* url_horizon: this is the URL of the horizon API instance, this is only needed if you are running in the "horizon" mode
             by default it is set to the horizon testnet setting but can later be pointed to the live network if desired

* url_stellar_core: This is the URL or IP address and port that you have the local or even a remote stellar-core running on
                  it is normaly run on the local system so localhost should work but the port can be changed and my settings here are not default to stellers release

* url_mss_server:  This is the URL and port that the mulit-sign-websocket will be set to be listening on to recieve action commands

* fee: is the fee settings that are used in ruby-stellar-base for transaction fee's, the default in most cases is 100 

* start_balance:  is the value in native stellar that will be funded to a newly created stellar account when the create_account function is called
                when a funder keypair is also provided.

* default_network:  defines weather the system will be using the stellar testnet or the stellar live network or maybe some third party network
                  it is defaulted to the testnet setting 

* master_keypair: this is the account used to fund new accounts when they are created.  it defaults to the master key that on testnet is 
                like the friendbot that provides free testnet native to play with.  on a live net you would set this to an account that 
                has the needed funding to allow account creation only if needed.

* mss_bind:  This is the bind address setting for the mss-server.  it determines the listen address of the server that by default is set to 
           all connected networks on the local system.  it can be set to only listen to itself with localhost setting or only on a sigle nic
           on the system.

* mss_port:  this is the port that the multi-sign-websocket will be listening on the networks for action commands

* mss_db_mode: this is the setting of the type of database backend used in the mss-server, at this time only the sqlite is tested
             but support for postgress has already also been partly setup but not debuged and tested yet. advise only using sqlite at this time

* mss_db_file_path: this is the sqlite database file path used in the multi-sign-websocket. be sure the location is read writable under the user you are
                  running the system under.

* version:  this is the version stellar-utility git hash number displayed when the "version" action command asks for it.  it should be set to the git
          hash first 8 letters of the stellar-utility you are now using to run mss-server. 

* core_version: this is the stellar-core git hash first 8 letters that this system is controling if running in localcore mode


## Test websites for mss-server using a browser
 We have created a example test web clients that utilises the websocket mode of mss-server for people to experment with and to server as an example how to setup a browser interface to an mss-server. 
 The example client provides a box to send raw JSON with a send button.  The text JSON results are then seen at the bottom.
 It also contains a list of some examples of some of the common usage functions with param values already contained to try.
 This can be seen sometimes (not stable site just adsl connected home computer due to limited resources and funding) at http://zipperhead.ddns.net/example_mss_server_actions.html. The code for this 
 is also in this github distribution for you to see and try.  The present server is also run on the unstable site so don't always expect a responce.
 We also created a primitive wallet app site that works in multi modes including mss-server mode and horizon testnet and live modes so you can compare operations and speed of API bettween both horizon and mss-server interfaces at http://zipperhead.ddns.net/stellar_min_client.html

## Why was it create?
Mss-server was originaly created to allow the publishing of multi sign transaction and provide a point of collection for the signers to pickup the original unsigned transaction, sign it and send a validation signature back to the mss-server that would collect all the needed signatures and when weighted threshold is met will send the multi signed transaction to the stellar-core network.  We later added features to make it more like a mini horizon API interface as well.

##install and setup
clone the git:
$git clone git@github.com:sacarlson/stellar_utility.git
$cd ./stellar_utility/multi-sign-server
$bundle install

##start server:
$bundle exec multi-sign-server.rb

##dependancies
most if not all of the dependancies should be contained in the Gemfile in this directory
other than that you do need bundler and I also run rbenv with ruby 1.9.3-p484 as default but newer ruby should also work just never tried

## System platforms supported
Only ever tried on Linux Mint 17 but should run on most any Ubuntu,debian derivitive or later version of Linux. In theory I guess it could be ported to windows or most any system that supports ruby.


 
