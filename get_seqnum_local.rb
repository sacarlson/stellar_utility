#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com

require './stellar_utilities'

#account = 'GANOA5VBG3OMPMO7TG5NQD35IOHI627VBJYMXGPCUUFQRDGCT4MGPLL2'
account = 'GD5GK7WBU27XXAGD6J75JOLF7WVFGH2RXEBLOQ6OCVJTIA2JZDJLXAJ3'

seq = get_seqnum_local(account)

puts "seq = #{seq}"
