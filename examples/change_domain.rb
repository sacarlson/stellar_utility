#!/usr/bin/ruby
require '../lib/stellar_utility/stellar_utility.rb'

#Utils = Stellar_utility::Utils.new("horizon")
Utils = Stellar_utility::Utils.new()
puts "Utils version: #{Utils.version}"
puts "configs: #{Utils.configs}"


keypair = YAML.load(File.open("./multi_sig_account_keypair.yml"))
#keypair = YAML.load(File.open("./secret_keypair_Live_GDW3CNKSP5AOTDQ2YCKNGC6L65CE4JDX3JS5BV427OB54HCF2J4PUEVG.yml"))
#keypair = YAML.load(File.open("./secret_keypair_live_GBPO4N6XOLOLW2EV6X2AEQMLKOBH3WF2IJCZEQU65SVVSN4JD44WORKD.yml"))
domain = "sacarlson"
max = Time.now.to_i + 10000
tx = Utils.set_options_tx(keypair,home_domain: domain, :max_time max)

envelope = tx.to_envelope(keypair)

b64 = Utils.envelope_to_b64(envelope)
txid = Utils.envelope_to_txid(b64)
puts "txid:  #{txid}"
puts "b64:  #{b64}"

result = Utils.send_tx(b64)
puts "result send_tx #{result}"
