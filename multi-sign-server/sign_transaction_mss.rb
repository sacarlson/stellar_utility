#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
# this will demonstrate how a client would use the multi-sign-server to get an unsigned transaction envelope
# from the mss-server, sign it and return the signature to the mss-server that will continue to collect the remaining
# needed signatures from other signers until the threshold is met so the transaction can be submited to the stellar
# network to be validated and processed.
 
require '../lib/stellar_utility/stellar_utility.rb'

#Utils = Stellar_utility::Utils.new("horizon")
Utils = Stellar_utility::Utils.new()
puts "Utils version: #{Utils.version}"
puts "configs: #{Utils.configs}"

if !File.file?("./multi_sig_account_keypair.yml")
  puts "you must run create_account_for_mss.rb before you run this to create needed keys and accounts used here, will exit now"
  exit -1
end
# load the keypairs needed to sign the pregenerated transaction submited with submit_transaction_to_mss.rb
#multi_sig_account_keypair = YAML.load(File.open("./multi_sig_account_keypair.yml"))
signerA_keypair = YAML.load(File.open("./signerA_keypair.yml"))
signerB_keypair = YAML.load(File.open("./signerB_keypair.yml"))

puts "signerA_keypair address #{signerA_keypair.address}"
puts "signerB_keypair address #{signerB_keypair.address}"


#note this function will later be moved to stellar_utility.rb when dev completed at that point an added Utils.**** will need to be added
# also note the all the Utils.*** will need to be removed from this function when it is moved
def setup_multi_sig_sign_hash(tx_code,keypair)
  #this will search the multi-sign-server for the published transaction with a matching tx_code.
  #if the transaction is found it will get the b64 encoded transaction from the server 
  #and sign it with this keypair that is assumed to be a valid signer for this transaction.
  #after it signs the transaction it will send the signed transaction back to the multi-sign-server
  #that will continue to collect more signatures from other signers until the total signer weight threshold is met,
  #at witch point the multi-sign-server will send the fully signed transaction to the stellar network for validation
  # this function only returns the sig_hash to be sent to send_to_multi_sign_server(sig_hash) to publish signing of tx_code
  # this sig_hash can be modified before it is sent 
  # example: 
  # sig_hash["tx_title"] = "some cool transaction"
  # sig_hash["signer_weight"] = 2
  # the other values should already be filled in by the function that for the most part should not be changed.

  #this action get_tx when sent to the mss-server will returns the master created transaction with added info,  
  #{"tx_num"=>1, "signer"=>0, "tx_code"=>"7ZZUMOSZ26", "tx_title"=>"test multi sig tx", "signer_address"=>"", "signer_weight"=>"", "master_address"=>"GDZ4AFAB...", "tx_envelope_b64"=>"AAAA...","signer_sig"=>"URYE..."}
  get_tx = {"action"=>"get_tx","tx_code"=>"7ZZUMOSZ26"}
  get_tx["tx_code"] = tx_code
  result = Utils.send_to_multi_sign_server(get_tx)
  puts "mss result: #{result}"
  puts "env_b64: #{result["tx_envelope_b64"]}"
  env = Utils.b64_to_envelope(result["tx_envelope_b64"])
  if env.nil?
    puts "env was nil"
    return nil
  end
  tx = env.tx
  signature = Utils.sign_transaction_env(env,keypair)
  envnew = Utils.envelope_addsigners(env, tx, keypair)
  tx_envelope_b64 = Utils.envelope_to_b64(envnew)
  submit_sig = {"action"=>"sign_tx","tx_title"=>"test tx","tx_code"=>"JIEWFJYE", "signer_address"=>"GAJYGYI...", "signer_weight"=>"1", "tx_envelope_b64"=>"AAAA...","signer_sig"=>"JIDYR..."}
  submit_sig["tx_code"] = tx_code
  submit_sig["tx_title"] = tx_code
  #submit_sig["signer_sig"] = signature
  submit_sig["tx_envelope_b64"] = tx_envelope_b64
  submit_sig["signer_address"] = keypair.address
  return submit_sig
end

#this code must be changed to the tx_code created when submit_transaction created it.
tx_code = "7QZP7W6FOM"

sign_hash = setup_multi_sig_sign_hash(tx_code,signerA_keypair)
puts ""
puts "sign_hashA:  #{sign_hash}"
puts ""
#example of what was returned in sign_hash:
#sign_hash:  {"action"=>"sign_tx", "tx_title"=>"ODEDFG4QER", "tx_code"=>"ODEDFG4QER", "signer_address"=>"GB2HYLGOZLUSSKEP47EY2GQE66KMEYT4AMFBV6NCBJGEKYONG6S5BMBO", "signer_weight"=>"1", "tx_envelope_b64"=>"AAAAAFiNI2HQ5glD03WWMluyTdaN531sZBGTiCWjxhduGzxIAAAACgAAAAAAAAABAAAAAAAAAAAAAAABAAAAAAAAAAUAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAACHRlc3Q4ODE0AAAAAAAAAAAAAAACzTel0AAAAEAL/QFdoLkWub9Q+hjjYMQtSUdvVilDcRpKHGVDq6HQfpshiDIU9v7UexU6J1Bn/LDAw8MeLCxF98LFB3rJgHcBbhs8SAAAAECnAXIm6tt8WUcATFpM5R4rWS9YVw2oRSyN9omRLDjCvz3HW6EToDCCUAp4Nnl9dChwN88Mf3ohTUm7gWFP8q0L", "signer_sig"=>"JIDYR..."}

#we could again modify this before we send it to the mss-server example:
#sign_hash["tx_title"] = "change the tx title"
# we could later send the signer_sig instead of the signed tx_envelope_b64 if desired, but I haven't writen that part yet.
# also the singers signer_weight is assumed to be 1 here but the writer of the tx could have modified that and the signer can change that here.
# the signer must know his weight to submit any changes here or the mss-server will attempt to transact the tx with the wrong number of weighted signers.
#sign_hash["signer_weight"] = 2
# in most cases the default signer_weight is good.
# we could also later pull the signer weights from the stellar-core network db instead of tracking it at the mss-server, but again I haven't writen that yet.
# but the way it is presently writen the mss-server can now run on a system without any local stellar-core running by using horizion to do final submitions.
if 1==0
 #we then take the sign_hash above and send it back the signed transaction to the mms-server
 result = Utils.send_to_multi_sign_server(sign_hash)
 puts "sign result: #{result}"
 exit -1
end

#this is setup to send the second of the two singers signatures
# normaly this would be performed by another client user in a different location, this is just to show how it works
sign_hash = setup_multi_sig_sign_hash(tx_code,signerB_keypair)
puts "sign_hashB:  #{sign_hash}"
result = Utils.send_to_multi_sign_server(sign_hash)
puts "sign result: #{result}"



