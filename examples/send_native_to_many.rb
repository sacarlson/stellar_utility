#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
# this is a test jig to test functionality of send_native_many_tx and and generate_pool_tx functions
# that were added to stellar_utility.rb to support the inflation destination pool project

require '../lib/stellar_utility/stellar_utility.rb'

Utils = Stellar_utility::Utils.new("horizon")
#Utils = Stellar_utility::Utils.new()
puts "Utils version: #{Utils.version}"
puts "configs: #{Utils.configs}"
puts ""
#master  = eval( @configs["master_keypair"])
master  = Stellar::KeyPair.master
funder = master

data = '{"accounts":[{"accountid":"GDW3CNKSP5AOTDQ2YCKNGC6L65CE4JDX3JS5BV427OB54HCF2J4PUEVG","balance":345.49983,"index":0,"to_receive":0.06644227500000001,"multiplier":0.01914122778140373},{"accountid":"GDRFRGR2FDUFF2RI6PQE5KFSCJHGSEIOGET22R66XSATP3BYHZ46BPLO","balance":2066.91551,"index":1,"to_receive":0.39748375192307694,"multiplier":0.11451033299155677},{"accountid":"GDSV3CO575XTVNBFNEW3EJ6F4O62YWVYREOBAOJCECCAH5VC4XVI4MP3","balance":20.999909,"index":2,"to_receive":0.004038444038461539,"multiplier":0.0011634276102473052},{"accountid":"GDTBOQPEEAKRFLGINUB3HZA6AV7OFWFLOAQQPLDII7HHU65ELW3WEY6L","balance":15589.256708,"index":3,"to_receive":2.9979339823076927,"multiplier":0.8636690605335582},{"accountid":"GDTHJDFZOENIOR5TITSW46KMSDQQN7WUULBJXO5EDOAOVDAAGEEB7LQQ","balance":27.36297,"index":4,"to_receive":0.005262109615384616,"multiplier":0.0015159510832341563}],"total_pool":18050.034926999997,"total_inflation":3.471160562884615,"action":"get_pool_members","status":"success"}'

to_hash = JSON.parse(data)

puts "check: #{data["accounts"][0]}"
# remove key from master address to generate completely unsigned b64 envelope
funder = Utils.convert_address_to_keypair(master.address)
b64 = Utils.generate_pool_tx(funder, to_hash)

puts "b64: #{b64}"

#Utils.send_native_to_many_tx(from_pair, to_array)
