require './multi_sign_lib.rb'

configs = YAML.load(File.open("./stellar_utilities.cfg"))
puts "configs_:  #{configs}"
mult_sig = Multi_sign.new(configs)
puts ""
address = "GDGWUMKCBSFVN5U2GS6K6GJYG2EXEHA3AKYL2SXYUX2S3A6K6XPCMRDF"
#result = mult_sig.search_signable_account(address)

result = mult_sig.search_signable_tx(address)
