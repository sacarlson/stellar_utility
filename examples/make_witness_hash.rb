#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
#here we demonstrate and test the make_witness_hash function and check_witness_hash function set
#this set can be used as an offline method of proof of assets if used on a timebound locked stellar account
#these functions have now also been incorporated into the multi-sign-websocket server
# work in progress

require '../lib/stellar_utility/stellar_utility.rb'
#Utils = Stellar_utility::Utils.new("horizon")
Utils = Stellar_utility::Utils.new()
puts "Utils version: #{Utils.version}"
puts "configs: #{Utils.configs}"
puts ""

master  = Stellar::KeyPair.master

Utils.create_key_testset_and_account(122)
multi_sig_account_keypair = YAML.load(File.open("./multi_sig_account_keypair.yml"))
signerA_keypair = YAML.load(File.open("./signerA_keypair.yml"))
signerB_keypair = YAML.load(File.open("./signerB_keypair.yml"))
signerC_keypair = YAML.load(File.open("./secret_keypair_GCYSIZB4Q6ISTHFDXQMBBUPI4BVY7KW6QKCIZKTXAQBDXQYGRRIUTYSX.yml"))
puts "multi: #{multi_sig_account_keypair.address}"
puts "signerA: #{signerA_keypair.address}"
puts "signerB: #{signerB_keypair.address}"
puts "signerC: #{signerC_keypair.address}"
puts ""

hash = Utils.make_witness_hash(multi_sig_account_keypair,multi_sig_account_keypair,asset="",issuer="")
puts "hash: #{hash}"


puts "check: #{Utils.check_witness_hash(hash)}"
#returns true as it shows that the above hash is signed correctly
