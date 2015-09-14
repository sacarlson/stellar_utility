#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
# note: I can't get this to work yet Aug 12, 2015
require './stellar_utilities'

#master      = Stellar::KeyPair.from_raw_seed("allmylifemyhearthasbeensearching")
master  = eval( @configs["master_keypair"])

if File.file?("./multi_sig_account_keypair.yml")
    from_pair = YAML.load(File.open("./multi_sig_account_keypair.yml"))
    to_pair = YAML.load(File.open("./signerA_keypair.yml"))
    #signerB_keypair = YAML.load(File.open("./signerB_keypair.yml"))
else
  from_pair = Stellar::KeyPair.random
  puts "from address #{from_pair.address}"
  puts "from seed #{from_pair.seed}"
  to_pair = Stellar::KeyPair.random
  puts "to address #{to_pair.address}"
  puts "to seed #{to_pair.seed}" 
  result = create_account(to_pair, master, starting_balance=50)
  puts "#{result}"
  sleep 11
  result = create_account(from_pair, master, starting_balance=50)
  puts "#{result}"
  sleep 11
end

puts "from_pair.address:  #{from_pair.address}"
puts "to_pair.address:    #{to_pair.address}"

#send_native_tx(from_pair, to_account, amount, seqadd=0)
tx1 = send_native_tx(from_pair, to_pair.address, 1)
tx2 = send_native_tx(from_pair, to_pair.address, 2)
tx3 = send_native_tx(from_pair, to_pair.address, 3)
# if all 3 tx above do work, the output should have 6 more native balance 1+2+3

tx = tx_merge(tx1,tx2,tx3)
b64 = tx.to_envelope(from_pair).to_xdr(:base64)

result = get_native_balance(to_pair)
puts "#{result}"

result = send_tx(b64)
puts "#{result}"
sleep 11

result = get_native_balance(to_pair)
puts "#{result}"

