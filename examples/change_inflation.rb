#!/usr/bin/ruby
require '../lib/stellar_utility/stellar_utility.rb'

Utils = Stellar_utility::Utils.new("horizon")
#Utils = Stellar_utility::Utils.new()
puts "Utils version: #{Utils.version}"
puts "configs: #{Utils.configs}"
keypair = YAML.load(File.open("./secret_keypair_GCYSIZB4Q6ISTHFDXQMBBUPI4BVY7KW6QKCIZKTXAQBDXQYGRRIUTYSX.yml"))
keypair_inf = YAML.load(File.open("./multi_sig_account_keypair.yml"))
#keypair = YAML.load(File.open("./secret_keypair_Live_GDW3CNKSP5AOTDQ2YCKNGC6L65CE4JDX3JS5BV427OB54HCF2J4PUEVG.yml"))
#keypair = YAML.load(File.open("./secret_keypair_live_GBPO4N6XOLOLW2EV6X2AEQMLKOBH3WF2IJCZEQU65SVVSN4JD44WORKD.yml"))
domain = "no_way"
puts "keypair_inf.address:  #{keypair_inf.address}"
inflation_address = "GCOGKNEN3EMFEQCIVJANAQDW4GHEWY5OXSX3SLGHAUFWUY6C3EQIPX6G"
tx = Utils.set_options_tx(keypair,inflation_dest: inflation_address)

envelope = tx.to_envelope(keypair)

b64 = Utils.envelope_to_b64(envelope)
txid = Utils.envelope_to_txid(b64)
puts "txid:  #{txid}"
puts "b64:  #{b64}"

result = Utils.send_tx(b64)
puts "result send_tx #{result}"
