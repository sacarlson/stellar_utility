#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
require './stellar_utilities'

#account = 'GBPJR44JZVXBGRXRQ7PN34IUERQOJ64OG44UIF7ICOIUWLN7H5MALVIU'
account = 'GDJUIEGLARHHM6IVNFEMV5HRX3A2CQV4YVRYUB5FEHDSBVAFENPKRHBA'
#account = 'GBZH6Z74OWID6ZP67KYNF7T5ES4APLZSISYO7GZGXW7PJNMFL4XNV3PT'
currency = "USD"

query = "SELECT * FROM accounts;"
#query = "SELECT count(*) FROM accounts WHERE accountid='#{account}';"
#query = "SELECT * FROM trustlines WHERE accountid='#{account}' AND assetcode= '#{currency}'"
result = get_db(query)
#puts result.cmd_tuples
result.each{ |row|
    puts "row #{row}"
}


result =  get_accounts_local(account)

puts result

puts get_native_balance_local(account)

puts get_seqnum_local(account)

puts next_sequence(account)

puts get_lines_balance_local(account,currency)



