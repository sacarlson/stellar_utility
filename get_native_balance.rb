#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
require './stellar_utilities'

master = Stellar::KeyPair.from_raw_seed("allmylifemyhearthasbeensearching")
account = master.address
#account = 'GDJUIEGLARHHM6IVNFEMV5HRX3A2CQV4YVRYUB5FEHDSBVAFENPKRHBA'
#keypair = Stellar::KeyPair.random
#account = keypair.address


result = get_native_balance_local(account)
puts " native balance: #{result}"
