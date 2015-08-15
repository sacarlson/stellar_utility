#!/usr/bin/ruby
require 'stellar-base'

#b64 = "AAAAAAAAAAD////7AAAAAA=="
b64 = 'j2WI/g7vWuV6i83ZyNe5hv3hY4Dbg3R8mcW0PVp6NZMAAAAAAAAACv////8AAAABAAAAAAAAAAb////9AAAAAA=='

# decode to the raw byte stream
bytes = Stellar::Convert.from_base64 b64

# decode to the in-memory TransactionResult
tr = Stellar::TransactionResult.from_xdr bytes

# the actual code is embedded in the "result" field of the 
# TransactionResult.
puts tr.result.code
