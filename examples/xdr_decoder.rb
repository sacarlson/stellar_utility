#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
#this is a tool to decode what is seen in the stellar database colums that are coded in base64 in xdr structures
# it can aide in isolating transaction errors by looking at txresults  
#these columes include:
#txhistory
#  txbody
#    decode_txbody_b64(b64)
#  txresult
#    decode_txresult_b64(b64)
#  txmeta
#    decode_txmeta_b64(b64) 
#
#accounts
#  thresholds
#    decode_thresholds_b64(b64)  

require '../lib/stellar_utility/stellar_utility.rb'
Utils = Stellar_utility::Utils.new("horizon")
puts "Utils version: #{Utils.version}"
puts "configs: #{Utils.configs}"

#puts "base version: #{Stellar::Base}"

#examples of usage:
puts ""
#txmeta data
b64 = "AAAAAAAAAAEAAAABAAKAzQAAAAAAAAAAZc2EuuEa2W1PAKmaqVquHuzUMHaEiRs//+ODOfgWiz8AAEtfm+1FNgAAACEAAAIhAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAABAAAAAgAAAAAAAoDNAAAAAAAAAABCzwVZeQ9sO2TeFRIN8Lslyqt9wttPtKGKNeiBvzI69wAAABdIdugAAAKAzQAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAEAAoDNAAAAAAAAAABlzYS64RrZbU8AqZqpWq4e7NQwdoSJGz//44M5+BaLPwAAS0hTdl02AAAAIQAAAiEAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAA=="
Utils.decode_txmeta_b64(b64)

exit -1

#account thresholds
#b64 = 'AQAAAA=='
#{:master_weight=>1, :low=>0, :medium=>3, :high=>3}
b64 = "AQADAw=="
Utils.decode_thresholds_b64(b64)
exit -1

#this can be used to view what is inside of a stellar db txhistory txresult in a more human readable format than b64
#TransactionResultPair 
b64 = '3E2ToLG5246Hu+cyMqanBh0b0aCON/JPOHi8LW68gZYAAAAAAAAACgAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAA=='
b64 = 'vbk+9tuTcnX5JdRUcY3E9fqwG3fnGPH0WVBGeC3QDtIAAAAAAAAACv////8AAAABAAAAAAAAAAX/////AAAAAA=='
b64 = 'o1+xo6/fzgtu4ryqv7EyjOX7BUnbYEr6U1YaQaXti5IAAAAAAAAACv////8AAAABAAAAAAAAAAD////9AAAAAA=='
result = Utils.decode_txresult_b64(b64)
#puts "result:  #{result}" 
#:CreateAccountResultCode.create_account_low_reserve(-3)

exit -1

b64 = 'AAAAAGXNhLrhGtltTwCpmqlarh7s1DB2hIkbP//jgzn4Fos/AAAACgAAACEAAAGwAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAPsbtuH+tyUkMFS7Jglb5xLEpSxGGW0dn/Ryb1K60u4IAAAAXSHboAAAAAAAAAAAB+BaLPwAAAEDmsy29BbAv/oXdKMTYTKFiqPTKgMO0lpzBTJSaH5ZT2LFdpIT+fWnOjknlRlmXwazn0IaV8nlokS4ETTPPqgEK'
#this can be used to view what is inside of a stellar db txhistory txbody in a more human readable format than b64
result = Utils.decode_txbody_b64(b64)
#puts "result:  #{result}"

__END__

tx = Utils.create_account_tx(multi_sig_account_keypair, signerB_keypair, starting_balance, seqadd=0)
puts "tx.inpect #{tx.inspect}"
puts "tx.source_account #{tx.source_account.inspect}"

example of results seen where balance was too low SetOptionsResultCode.set_options_low_reserve(-1)
sacarlson@sacarlson-asrock ~/github/stellar/stellar_utility $ rr xdr_decoder.rb
tranPair.inspect:  #<Stellar::TransactionResultPair:0x00000003a93d20 @attributes={:transaction_hash=>"\xBD\xB9>\xF6\xDB\x93ru\xF9%\xD4Tq\x8D\xC4\xF5\xFA\xB0\ew\xE7\x18\xF1\xF4YPFx-\xD0\x0E\xD2", :result=>#<Stellar::TransactionResult:0x00000003a93898 @attributes={:fee_charged=>10, :result=>#<Stellar::TransactionResult::Result:0x00000003d03678 @switch=Stellar::TransactionResultCode.tx_failed(-1), @arm=:results, @value=[#<Stellar::OperationResult:0x00000003d036f0 @switch=Stellar::OperationResultCode.op_inner(0), @arm=:tr, @value=#<Stellar::OperationResult::Tr:0x00000003d03718 @switch=Stellar::OperationType.set_options(5), @arm=:set_options_result, @value=#<Stellar::SetOptionsResult:0x00000003d03740 @switch=Stellar::SetOptionsResultCode.set_options_low_reserve(-1), @arm=nil, @value=:void>>>]>, :ext=>#<Stellar::TransactionResult::Ext:0x00000003d033d0 @switch=0, @arm=nil, @value=:void>}>}>

puts "tx.operations  #{tx.operations[0]}"
#tx.operations[0].body.value.master_weight = 1
#puts "tx.operations[0].body.value.master_weight.inpect
#{tx.operations[0].body.value.master_weight.inspect}"

  
  
