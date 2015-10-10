#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
#here we will be developing a function that will create a timebound unlock transaction to change thresholds on a tobe locked account.
#this will be used with make_witness that will provide proof to a third party that an account that is presently
#locked has funds in it.  This would allow offline transactions without internet conectivity to still provide 
#safe secure transaction without fear of double spending.  this function will create the transaction needed to unlock
# the later to be locked account after some time bound window of time.
#to prevent any other account and this one from having the ability to create another unlock transaction at some earlier window of time 
#this function will first check the signers on the target account that there are no more that 2 other signers (total 3) and that the timebound locking server account
#is presently one of them.  It will also verify that the target accounts thresholds are presently set to unlocked default of low =0 med = 0 high =0
# After this creates the unlock transaction the user of the target account
#can then  lock the account with threshold settings of low = 0, med = 2, high = 2 that would now require having both the users
#signature and the timebound locking servers signature signing the precreated unlock transaction and also await the time needed for the precreated transaction 
#to be valid in time before it can be unlocked. NOTE:  As making changes to the thresholds above increments the sequence code by one, so the transaction create by
# the timebound server must have the transaction with the sequence number also incremented one higher than next_seq to allow this to happen.
# at anytime after the account is locked the account can have added funds added and then a make_witness could be captured as proof of locked assets.
#   As this is a 3 party account with a total of 3 signers, the user can now also take the option of creating and delivering 
#transactions to the 3rd signers account.  the 3rd party could then take the transaction and also sign it and submit it to the stellar network at any
#time before the expire window of the timebound locking transaction without any posibility that the target account could withdraw the funds before he does.
#even in the even he fails to make the transaction in time on the network, as long as the target_account doesn't withdraw the funds he can still get them.
#the 3rd party would know this by the target account user also providing the 3rd party with the signed witness information from a trusted
#automated witness server that proves that the account
#had funding that could only be spent by the 3rd party over a know window of time.  There is only one flaw that I can think of at this point.  as 
#the target accounts only other option would be to send a transaction of payment to the only other signer that can transact before the time window, 
#that being the timebound locking server address.  So the 3rd party also must go on trust that the timebound locking server will never accept funds in this way
#nor would the target account user ever be motivated to perform such an act.  to add more trust people could optionaly chain multiple trust servers if desired.


require '../lib/stellar_utility/stellar_utility.rb'
#Utils = Stellar_utility::Utils.new("horizon")
Utils = Stellar_utility::Utils.new()
puts "Utils version: #{Utils.version}"
puts "configs: #{Utils.configs}"
puts ""

master  = Stellar::KeyPair.master

Utils.create_key_testset_and_account(122)
multi_sig_account_keypair = YAML.load(File.open("./multi_sig_account_keypair.yml"))
signerA_keypair = YAML.load(File.open("./signerA_keypair.yml"))
signerB_keypair = YAML.load(File.open("./signerB_keypair.yml"))
signerC_keypair = YAML.load(File.open("./secret_keypair_GCYSIZB4Q6ISTHFDXQMBBUPI4BVY7KW6QKCIZKTXAQBDXQYGRRIUTYSX.yml"))
puts "multi: #{multi_sig_account_keypair.address}"
puts "signerA: #{signerA_keypair.address}"
puts "signerB: #{signerB_keypair.address}"
puts "signerC: #{signerC_keypair.address}"
puts ""


timebound = Time.now.to_i + 60
hash = Utils.create_unlock_transaction(multi_sig_account_keypair,signerA_keypair,timebound)
puts "hash:  #{hash}"
Utils.view_envelope(hash["unlock_env_b64"])
Utils.env_signature_info(hash["unlock_env_b64"])



