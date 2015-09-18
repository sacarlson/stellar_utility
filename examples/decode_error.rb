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

#Stellar::TransactionResultCode.tx_bad_auth_extra(-10)
b64 = "AAAAAAAAAAr////2AAAAAA=="

# decode to the raw byte stream
bytes = Stellar::Convert.from_base64 b64

# decode to the in-memory TransactionResult
tr = Stellar::TransactionResult.from_xdr bytes

# the actual code is embedded in the "result" field of the 
# TransactionResult.
puts "#{tr.result.code}"

__END__

txSUCCESS = 0, // all operations succeeded

    txFAILED = -1, // one of the operations failed (none were applied)

    txTOO_EARLY = -2,         // ledger closeTime before minTime
    txTOO_LATE = -3,          // ledger closeTime after maxTime
    txMISSING_OPERATION = -4, // no operation was specified
    txBAD_SEQ = -5,           // sequence number does not match source account

    txBAD_AUTH = -6,             // too few valid signatures / wrong network
    txINSUFFICIENT_BALANCE = -7, // fee would bring account below reserve
    txNO_ACCOUNT = -8,           // source account not found
    txINSUFFICIENT_FEE = -9,     // fee is too small
    txBAD_AUTH_EXTRA = -10,      // unused signatures attached to transaction
    txINTERNAL_ERROR = -11       // an unknown error occured

