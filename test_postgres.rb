#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
require './stellar_utilities'
# this now really only tests postres db if your in postgres mode in ./stellar_utility.cfg
# otherwise this will test ether of the database sqlite or postgresql that you are now setup to use.

result = get_db("SELECT * FROM accounts;")
result.each{ |row|
    puts "row #{row}"
}

