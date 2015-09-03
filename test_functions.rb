#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
require './stellar_utilities'
# do a basic test of all the added functions that hook to local db and horizon like next sequence and balance checkers
# this tets should be modified to disable horizon or local db tests for those that don't need or use them.

puts "configs[url_horizon] = #{@configs["url_horizon"]}"

master      = Stellar::KeyPair.from_raw_seed("allmylifemyhearthasbeensearching")
account = master.address
#account = 'GBPJR44JZVXBGRXRQ7PN34IUERQOJ64OG44UIF7ICOIUWLN7H5MALVIU'
#account = 'GBZH6Z74OWID6ZP67KYNF7T5ES4APLZSISYO7GZGXW7PJNMFL4XNV3PT'
account = 'GDJUIEGLARHHM6IVNFEMV5HRX3A2CQV4YVRYUB5FEHDSBVAFENPKRHBA'

currency = "CHP"
issuer = "GBPJR44JZVXBGRXRQ7PN34IUERQOJ64OG44UIF7ICOIUWLN7H5MALVIU"

query = "SELECT * FROM accounts;"
query = "SELECT count(*) FROM accounts WHERE accountid='#{account}';"
#query = "SELECT * FROM trustlines WHERE accountid='#{account}' AND assetcode= '#{currency}'"
puts "test get_db with query #{query}....................."
result = get_db(query)
#puts result.cmd_tuples
result.each{ |row|
    puts "row #{row}"
}

puts "test get_accounts_local(#{account}) = #{get_accounts_local(account)}....."

puts "test get_native_ballance_local(#{account}) = #{get_native_balance_local(account)}....."

puts "test get_seqnum_local(#{account}) = #{get_seqnum_local(account)}...."

puts "test next_sequence(#{account}) = #{next_sequence(account)}...."

puts "test get_lines_balance_local(#{account},#{issuer},#{currency}) = #{get_lines_balance_local(account,issuer,currency)}..."

puts "test get_account_sequence_horizon(#{account}) = #{get_account_sequence_horizon(account)}....."

puts "test get_account_info_horizon(#{account}) = #{get_account_info_horizon(account)}......."

puts "test get_native_balance_horizon(#{account}) = #{get_native_balance_horizon(account)}......"

puts "test get_lines_balance_horizon(#{account},#{issuer},#{currency}) = #{get_lines_balance_horizon(account,issuer,currency)}..."









