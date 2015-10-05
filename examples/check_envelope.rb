#this will be the start of development of group transaction analisys and signing
# in this example we will create a funtion that takes apart a transaction envelope_b64
# to verify that it has the desired action in it before it is signed by a signer.
require '../lib/stellar_utility/stellar_utility.rb'

Utils = Stellar_utility::Utils.new("horizon")
#Utils = Stellar_utility::Utils.new()
puts "Utils version: #{Utils.version}"
puts "configs: #{Utils.configs}"
puts ""
#master  = eval( @configs["master_keypair"])
master  = Stellar::KeyPair.master
funder = master

# the bigginning of this program just sets up the needed accounts and keypair files that will be used here and in the 
# next steps in other programs that demonstrate other parts. it will create 3 yaml files with the acount and keys.
# if the files are present it will do nothing but load them.

Utils.create_key_testset_and_account(start_balance = 1000)
multi_sig_account_keypair = YAML.load(File.open("./multi_sig_account_keypair.yml"))
signerA_keypair = YAML.load(File.open("./signerA_keypair.yml"))
signerB_keypair = YAML.load(File.open("./signerB_keypair.yml"))
#Utils.create_account(signerA_keypair, master,100)
puts "master: #{multi_sig_account_keypair.address}"
puts "signerA_keypair: #{signerA_keypair.address}"

#to check a base64 xdr transaction envelope we want to be able to check at least the basic actions for correct values
# 1. payment of native of an amount to a destination
# 2. payment of non native assets to a destination
# 3. delete a signer from an account
# 4. add a signer to an account
# 5. create account
# 6. make offer
# 7. set account options

# what we did is make it posible to create a hash template by converting an envelope into a hash with all it's values broken out for the basic transactions
# that can be modified with the values needed to be used as a reference hash that can be compared with a newly published base64 xdr coded envelope
# and return 0 if match or a positive integer of the number of mismatched items bettween them.
# you can then later use the other tool we created to find out why they don't match
#  see the example bellow of how these can be used in each of the transactions we have now tried them on.
# note at present this only supports a single operation per envelope, we will have to create multi transaction envelope method later if demanded

# trial transactions for compare tests and template creation
funder = multi_sig_account_keypair
rnd = rand(1000...9999) 
rndstring = "test#{rnd}"
#puts "#{rndstring}"
#tx = Utils.set_options_tx(multi_sig_account_keypair,home_domain: rndstring)
tx = Utils.send_native_tx(multi_sig_account_keypair, signerA_keypair, 2)
#tx = Utils.add_trust_tx(multi_sig_account_keypair,signerA_keypair,"CHP",100)
#tx = Utils.create_account_tx(signerA_keypair, multi_sig_account_keypair,100)
#tx = Utils.allow_trust_tx(account, trustor, code, authorize=true)  // not done
#tx = Utils.send_currency_tx(multi_sig_account_keypair, signerA_keypair, multi_sig_account_keypair, 123.1, "CHP")
#tx = Utils.offer_tx(multi_sig_account_keypair,signerA_keypair,"USD", signerA_keypair, "CHP",1.23,1.0001)
env_b64 = tx.to_envelope(funder).to_xdr(:base64)

#env_b64 = 'AAAAAJBrzw3ONDO46vf15HXGwuWaXCqUC5fW+wK5BJm5nfaMAAAD6AAAIU0AAAACAAAAAAAAAAAAAAABAAAAAAAAAAEAAAAAws9GWXeTd+kwubYVinVteea3EbflvS3k1plWg1IJ7F0AAAAAAAAAAACYloAAAAAAAAAAAbmd9owAAABAbVJYfpKjAqZquIFu1FMKg1Wjr7v8eM7UCA/YURSMnWJVwj7hnDQoQi4RbgG2t0UneWvpVeGz0v1oQ6fyOqriAw=='

#puts "env_b64:  #{env_b64}"

#variable = "home_domain"
#expected = rndstring
# both these functions will create a hash template of an b64 envelope, view_envelope just adds a print out of all values seen in env
hash = Utils.view_envelope(env_b64)
#hash = Utils.envelope_to_hash(env_b64)
puts "hash: #{hash}"

#Utils.send_tx(env_b64)

hash_template = {"source_address"=>"GAQC2M6FJI6Q3UFTY6B43LKQAZ4OL7WG3N4JSFC7AOMTNRQ3DBKYVHE5", "fee"=>10, "seq_num"=>899512180670465, "time_bounds"=>nil, "memo.type"=>"memo_none", "op_length"=>1, "operation"=>:payment_op, "destination_address"=>"GBBOGXDHIIT6RCJ6K453B2OJ7ZO4K2C5HIHZ5QL5DI7O623WYO4TVFVY", "asset"=>"native", "amount"=>22.0}

result = Utils.compare_env_with_hash(env_b64,hash_template)
puts "result:  #{result}"
diff = Utils.compare_hash(hash, hash_template)
puts "diff.length:  #{diff.length}"
puts "diff:  #{diff}"


