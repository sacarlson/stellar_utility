#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
require 'yaml'
require './stellar_utilities'

#keypairA = YAML.load(File.open("./secret_keypairA.yml"))
#keypairB = YAML.load(File.open("./secret_keypairB.yml"))
#keypairC = YAML.load(File.open("./secret_keypairC.yml"))
#keypairD = YAML.load(File.open("./secret_keypairD.yml"))
#buy_issuer = Stellar::KeyPair.from_seed("SCPY5UQQH4HZSKS3NZGZVWS2C7FOSEKK65M5QWKFRR4JQ3Q2D6VAJJWC")
buy_issuer = YAML.load(File.open("./secret_keypair_GBPJR44JZVXBGRXRQ7PN34IUERQOJ64OG44UIF7ICOIUWLN7H5MALVIU.yml"))
sell_issuer = buy_issuer
#sellers_account = YAML.load(File.open("./secret_keypair_GBZH6Z74OWID6ZP67KYNF7T5ES4APLZSISYO7GZGXW7PJNMFL4XNV3PT.yml"))
sellers_account = YAML.load(File.open("./secret_keypair_GDJUIEGLARHHM6IVNFEMV5HRX3A2CQV4YVRYUB5FEHDSBVAFENPKRHBA.yml"))
#sell_currency = "BEER"
sell_currency = "CHP"
buy_currency = "USD"
amount = 527
price = 0.00202003

seq = next_sequence(sellers_account)
puts "next_seq on sellers_account #{seq}"

b64 = offer(sellers_account,sell_issuer,sell_currency, buy_issuer, buy_currency,amount,price)
result = send_tx(b64)
puts "#{result}"
