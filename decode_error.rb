#!/usr/bin/ruby
require 'stellar-base'

#Stellar::TransactionResultCode.tx_bad_seq(-5)
b64 = "AAAAAAAAAAD////7AAAAAA=="

# this txresult returned from attempted trust line add
#Unknown Stellar::TransactionResultCode member: 2055982553
b64 = 'j2WI/g7vWuV6i83ZyNe5hv3hY4Dbg3R8mcW0PVp6NZMAAAAAAAAACv////8AAAABAAAAAAAAAAb////9AAAAAA=='

#`unpack': invalid base64 (ArgumentError)
#b64 = '8AAAABAAAAAAAAAAb////9AAAAAA=='

#Unknown Stellar::TransactionResultCode member: -1620739607 
#b64 = 't1qpS2SGmIWfZXnpmlFsZBt6JYb2+YIUC5RcngrmvCoAAAAAAAAD6P////8AAAABAAAAAAAAAAP////5AAAAAA=='

# decode to the raw byte stream
bytes = Stellar::Convert.from_base64 b64

# decode to the in-memory TransactionResult
#tr = Stellar::TransactionResult.from_xdr bytes

#<Stellar::TransactionResult:0x000000024f6ff8>
tr = Stellar::TransactionResultPair.from_xdr bytes

#tr = Stellar::ChangeTrustResult.from_xdr bytes

# the actual code is embedded in the "result" field of the 
# TransactionResult.
puts "#{tr.result}"
#puts tr.transaction_hash
