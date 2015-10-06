require '../lib/stellar_utility/stellar_utility.rb'
Utils = Stellar_utility::Utils.new("horizon")
puts "Utils version: #{Utils.version}"
puts "configs: #{Utils.configs}"
puts ""

keypair = Stellar::KeyPair.random

keypair2 = Stellar::KeyPair.random

address = keypair.address
address2 = keypair2.address
keypair_no_secret = Stellar::KeyPair.from_address(address)

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



 



