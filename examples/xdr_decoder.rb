#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
require './stellar_utilities'

#this is a tool to decode what is seen in the stellar database colums that are coded in base64 in xdr structures
# it can aide in isolating transaction errors by looking at txresults  
#these columes include:
#txhistory
#  txbody
#    decode_txbody_b64(b64)
#  txresult
#    decode_txresult_b64(b64)
#  txmeta
#    no decoder yet writen 
#
#accounts
#  thresholds
#    decode_thresholds_b64(b64)  //is broken 


def decode_thresholds_b64(b64)
  #  this one doesn't work yet, must be wrong structure 
  #ThresholdIndexes
  #b64 = 'AQAAAA=='
  bytes = Stellar::Convert.from_base64 b64
  thresholdindexes = Stellar::ThresholdIndexes.from_xdr bytes
  puts "thesholdindexes.inspect:  #{thresholdindexes.inspect}"
  return thresholdindexes.inspect
end

#examples of usage:

b64 = 'AQAAAA=='
#decode_thresholds_b64(b64)


#this can be used to view what is inside of a stellar db txhistory txresult in a more human readable format than b64
#TransactionResultPair 
b64 = '3E2ToLG5246Hu+cyMqanBh0b0aCON/JPOHi8LW68gZYAAAAAAAAACgAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAA=='
b64 = 'vbk+9tuTcnX5JdRUcY3E9fqwG3fnGPH0WVBGeC3QDtIAAAAAAAAACv////8AAAABAAAAAAAAAAX/////AAAAAA=='
result = decode_txresult_b64(b64)
#puts "result:  #{result}" 

exit -1

b64 = 'AAAAAGXNhLrhGtltTwCpmqlarh7s1DB2hIkbP//jgzn4Fos/AAAACgAAACEAAAGwAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAPsbtuH+tyUkMFS7Jglb5xLEpSxGGW0dn/Ryb1K60u4IAAAAXSHboAAAAAAAAAAAB+BaLPwAAAEDmsy29BbAv/oXdKMTYTKFiqPTKgMO0lpzBTJSaH5ZT2LFdpIT+fWnOjknlRlmXwazn0IaV8nlokS4ETTPPqgEK'
#this can be used to view what is inside of a stellar db txhistory txbody in a more human readable format than b64
result = decode_txbody_b64(b64)
#puts "result:  #{result}"

__END__

tx = create_account_tx(multi_sig_account_keypair, signerB_keypair, starting_balance, seqadd=0)
puts "tx.inpect #{tx.inspect}"
puts "tx.source_account #{tx.source_account.inspect}"

example of results seen where balance was too low SetOptionsResultCode.set_options_low_reserve(-1)
sacarlson@sacarlson-asrock ~/github/stellar/stellar_utility $ rr xdr_decoder.rb
tranPair.inspect:  #<Stellar::TransactionResultPair:0x00000003a93d20 @attributes={:transaction_hash=>"\xBD\xB9>\xF6\xDB\x93ru\xF9%\xD4Tq\x8D\xC4\xF5\xFA\xB0\ew\xE7\x18\xF1\xF4YPFx-\xD0\x0E\xD2", :result=>#<Stellar::TransactionResult:0x00000003a93898 @attributes={:fee_charged=>10, :result=>#<Stellar::TransactionResult::Result:0x00000003d03678 @switch=Stellar::TransactionResultCode.tx_failed(-1), @arm=:results, @value=[#<Stellar::OperationResult:0x00000003d036f0 @switch=Stellar::OperationResultCode.op_inner(0), @arm=:tr, @value=#<Stellar::OperationResult::Tr:0x00000003d03718 @switch=Stellar::OperationType.set_options(5), @arm=:set_options_result, @value=#<Stellar::SetOptionsResult:0x00000003d03740 @switch=Stellar::SetOptionsResultCode.set_options_low_reserve(-1), @arm=nil, @value=:void>>>]>, :ext=>#<Stellar::TransactionResult::Ext:0x00000003d033d0 @switch=0, @arm=nil, @value=:void>}>}>

puts "tx.operations  #{tx.operations[0]}"
#tx.operations[0].body.value.master_weight = 1
#puts "tx.operations[0].body.value.master_weight.inpect
#{tx.operations[0].body.value.master_weight.inspect}"

  
  
