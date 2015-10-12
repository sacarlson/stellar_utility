#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
require './multi_sign_lib.rb'

configs = YAML.load(File.open("./stellar_utilities.cfg"))
multi_sign = Multi_sign.new(configs)
puts ""
multi_sign.Utils.create_key_testset_and_account(122)
multi_sig_account_keypair = YAML.load(File.open("./multi_sig_account_keypair.yml"))
signerA_keypair = YAML.load(File.open("./signerA_keypair.yml"))
signerB_keypair = YAML.load(File.open("./signerB_keypair.yml"))
signerC_keypair = YAML.load(File.open("./secret_keypair_GCYSIZB4Q6ISTHFDXQMBBUPI4BVY7KW6QKCIZKTXAQBDXQYGRRIUTYSX.yml"))


timebound = Time.now.to_i + 10

if 1==0
multi_sign.create_db
rs = multi_sign.timestamp_witness(signerA_keypair,timebound)
puts "rs: #{rs.inspect}"
end

rs = multi_sign.make_witness_unlock(multi_sig_account_keypair,signerC_keypair,timebound)
puts "rs: #{rs.inspect}"
