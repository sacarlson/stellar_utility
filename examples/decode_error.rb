#!/usr/bin/ruby
require 'stellar-base'

#Stellar::TransactionResultCode.tx_bad_seq(-5)
#b64 = "AAAAAAAAAAD////7AAAAAA=="

#new error sep 9 2015
#Stellar::TransactionResultCode.tx_bad_auth(-6)
#txBAD_AUTH = -6,   // not enough signatures to perform transaction
# txBAD_AUTH = -6,  // too few valid signatures / wrong network
#b64 = "AAAAAAAAAAD////6AAAAAA=="


#Stellar::TransactionResultCode.tx_no_account(-8)
#b64 = "AAAAAAAAAAD////4AAAAAA=="

b64 = "AAAAAAAAAAr////2AAAAAA=="

# decode to the raw byte stream
bytes = Stellar::Convert.from_base64 b64

# decode to the in-memory TransactionResult
tr = Stellar::TransactionResult.from_xdr bytes

# the actual code is embedded in the "result" field of the 
# TransactionResult.
puts "#{tr.result.code}"

