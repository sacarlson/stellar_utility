require '../lib/stellar_utility/stellar_utility.rb'
Utils = Stellar_utility::Utils.new("horizon")
puts "Utils version: #{Utils.version}"
puts "configs: #{Utils.configs}"
puts ""
# this the demonstration with the signing tools and the check_timestamp functions


keypair = Stellar::KeyPair.random

keypair2 = Stellar::KeyPair.random

address = keypair.address
address2 = keypair2.address
keypair_no_secret = Stellar::KeyPair.from_address(address)



string_msg = "hello world"

timestamp = Time.now.to_i 
message = string_msg + ":" + timestamp.to_s
#message = string_msg + ":" 

puts "re: #{Utils.check_timestamp(message,timestamp)}"


#returns sig_b64:  CT8wIZWmU0a5XrRFF1+OHEpK7BCrNtDnUfy613muXqFxRVd5db0Hymli3BWd
sig_b64 = Utils.sign_msg(string_msg, keypair)
puts "sig_b64:  #{sig_b64}"

#returns true with correct sig
result = Utils.verify_signed_msg(string_msg, address, sig_b64)
puts "res: #{result}"

#returns expected false due to incorrect address for sig
result = Utils.verify_signed_msg(string_msg, address2, sig_b64)
puts "res: #{result}"


tx = Utils.set_options_tx(keypair,home_domain: "test")

envelope = tx.to_envelope(keypair)
sig = envelope.signatures[0]
sig_b64 = sig.to_xdr(:base64)
b64 = envelope.to_xdr(:base64)

 #returns true
 puts "resn: #{Utils.verify_signature(envelope, address, sig_b64)}"

 #returns true
 puts "res: #{Utils.verify_signature(envelope, address)}"
 
 #returns true
 puts "res b64: #{Utils.verify_signature(b64, address)}"

 #returns true
 puts "res b64 keypair: #{Utils.verify_signature(b64, keypair_no_secret)}"

 #returns false as expected with bad address2
 puts "res b64 address2: #{Utils.verify_signature(b64, address2)}"



 



