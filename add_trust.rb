#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
require './stellar_utilities'

#my-stellar
#issuer_account = 'GCZSBCPPUPBGMESSKBZQVSUNEZZFFR37DDEZ3V2MUMUASWDOMS5PNUSA'
#to_pair = Stellar::KeyPair.from_seed("SCPY5UQQH4HZSKS3NZGZVWS2C7FOSEKK65M5QWKFRR4JQ3Q2D6VAJJWC")
#fred's
issuer_account = 'GBPJR44JZVXBGRXRQ7PN34IUERQOJ64OG44UIF7ICOIUWLN7H5MALVIU'
#to_pair = Stellar::KeyPair.from_seed('SB2N...')
to_pair = YAML.load(File.open("./secret_keypair_GBZH6Z74OWID6ZP67KYNF7T5ES4APLZSISYO7GZGXW7PJNMFL4XNV3PT.yml"))
currency = "BEER"
limit = 10000000

result = add_trust(issuer_account,to_pair,currency)
#result = add_trust(issuer_account,to_pair,currency,limit)
puts "#{result}"

exit -1
sleep 12

result = add_trust(issuer_account,to_pair,"CHP")
#result = add_trust(issuer_account,to_pair,currency,limit)
puts "#{result}"

sleep 12

result = add_trust(issuer_account,to_pair,"ABCD",10000)
#result = add_trust(issuer_account,to_pair,currency,limit)
puts "#{result}"





__END__
on my-stellar
issuer address GDJUIEGLARHHM6IVNFEMV5HRX3A2CQV4YVRYUB5FEHDSBVAFENPKRHBA
issuer seed SDWTC2MQLFH5J5GBXUI4H4KIPHOFAKY77G7RQH6RDXORIX25NZAJEET5

to address GCZSBCPPUPBGMESSKBZQVSUNEZZFFR37DDEZ3V2MUMUASWDOMS5PNUSA
to seed SCPY5UQQH4HZSKS3NZGZVWS2C7FOSEKK65M5QWKFRR4JQ3Q2D6VAJJWC

on fred stellar
issuer address GAV7X5HT2EOURBMAT5SFNX6IDKHKPHU3GN54GDV5VUNRQXV7ULCUBSY6
issuer seed SCM2WFYWB2W52WGQSEQIJ4UD2Y3HA7PUBBU5N5YA62IKH725RZJJAJHZ

to address GAHGLUPX7CRPMKOU4ZURFPZJHDQCCHXRYI26AHCQA7E2VFS4O444CZBM
to seed SB2NQE7LDVNLZPI3VU5Y6SQFY4FHWB6XL5CMEPMIGM2E3G6ZQ3Y3AELX

master address GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ
master seed SBQWY3DNPFWGSZTFNV4WQZLBOJ2GQYLTMJSWK3TTMVQXEY3INFXGO52X

