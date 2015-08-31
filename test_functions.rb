#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
require './stellar_utilities'
# do a basic test of all the needed added functions that hook to db like next sequence

master      = Stellar::KeyPair.from_raw_seed("allmylifemyhearthasbeensearching")
account = master.address
#account = 'GBPJR44JZVXBGRXRQ7PN34IUERQOJ64OG44UIF7ICOIUWLN7H5MALVIU'
#account = 'GDJUIEGLARHHM6IVNFEMV5HRX3A2CQV4YVRYUB5FEHDSBVAFENPKRHBA'
#account = 'GBZH6Z74OWID6ZP67KYNF7T5ES4APLZSISYO7GZGXW7PJNMFL4XNV3PT'
currency = "USD"

query = "SELECT * FROM accounts;"
#query = "SELECT count(*) FROM accounts WHERE accountid='#{account}';"
#query = "SELECT * FROM trustlines WHERE accountid='#{account}' AND assetcode= '#{currency}'"
puts "test get_db with query #{query}....................."
result = get_db(query)
#puts result.cmd_tuples
result.each{ |row|
    puts "row #{row}"
}

puts "test get_accounts_local from account #{account}.............#{get_accounts_local(account)}"
#result =  get_accounts_local(account)
#puts result

puts "test get_native_ballance_local from account #{account}..........#{get_native_balance_local(account)}"
#puts get_native_balance_local(account)

puts "test get_seqnum_local from account #{account}.............#{get_seqnum_local(account)}"
#puts get_seqnum_local(account)

puts "test next_sequence from account #{account}..............#{next_sequence(account)}"
#puts next_sequence(account)

puts "test get_lines_balance_local from account #{account}..currency #{currency}...#{get_lines_balance_local(account,currency)}"
#puts get_lines_balance_local(account,currency)



