#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
require './stellar_utilities'
#this will demonstrate how a client would use the multi-sign-server to setup and publish a multi-sign-account
# to a multi-sign-server or as we will sometimes now call it an mss-server. 
# The multi-sign-server is used to distribute tx envelopes to the signers and acumulate the needed signatures and submit them
# to the stellar network when the mss-server finds that it has collected what is needed to validate the transactions.
# you must have a multi-sign-server entity running and you must have the @configs["multi_sign_server_url"] pointing at it
# for this to work.  This program will also create 1 active account with funding needed for this test.
# it will also setup the multi_sig_keypairs and save them as files as signerA_keypair and signerB_keypair for
# a total of 3 keypairs that will be used here and in the next example programs:
# submit_transaction_to_mss.rb and sign_transaction_mss.rb were the other functions of the mss server are demonstrated.
# each signer keypair and the mss_account pair itself is by default assigned a signing weight of 1
# the thresholds are set as master_weight: 1, low: 0, medium: 3, high: 3.
# This means that all 3 signers will need to sign this transaction to be validated and processed to be seen
# on the stellar network.
# after you run this program see  sign_transaction_mss.rb and submit_transaction_to_mss.rb that shows how this account and key sets are used to make a transaction that requires this account and these keys to transact.

# you will have to privide a master_keypair account in ./stellar_utility.cfg that has the funds needed to do this operation
# you will need 25 lunes minimum that will be used to activate and fund the multi_sig_account_keypair 

master  = eval( @configs["master_keypair"])
rs = Stellar.current_network
puts "current_network = #{rs}"
puts "multi-sign-server url: #{@configs["multi_sign_server_url"]}"
starting_balance = @configs["start_balance"]
puts "starting_balance = #{starting_balance}"
puts "fee = #{@configs["fee"]}"

# the bigginning of this program just sets up the needed accounts and keypair files that will be used here and in the 
# next steps in other programs that demonstrate other parts.
if 1==0
  # this is here as an option if you want to setup your own choice of keyfiles to be the multi signed account and keys
  # for this experimental multi sign account
  multi_sig_account_keypair = YAML.load(File.open("./secret_keypair_GBN3YBHSD653DQHADNP7AX5XA4UGZH5HFZ67MW4IIXYXGNBECTKFCZU2.yml"))
  signerA_keypair = YAML.load(File.open("./secret_keypair_GC7UGD45JFMPKCCRJTOBLTKEN64CWJC7GNBRS7WL75FNUVC5Z2B6TKGX.yml"))
  signerB_keypair = YAML.load(File.open("./secret_keypair_GC2TANKLHFXEX4MZA4WRM2ZC33JN5Z6SMNPV72WX2CQ22UWISXOGI3YA.yml"))
else
  if File.file?("./multi_sig_account_keypair.yml")
    # by default this will auto creates the needed files to test MSS-server
    # this assumes if the file exists that it is already funded and the other signer key files also exist.
    multi_sig_account_keypair = YAML.load(File.open("./multi_sig_account_keypair.yml"))
    signerA_keypair = YAML.load(File.open("./signerA_keypair.yml"))
    signerB_keypair = YAML.load(File.open("./signerB_keypair.yml"))
  else
    #if the file didn't exist we will create the needed set of keypair files and fund the needed account.
    multi_sig_account_keypair =Stellar::KeyPair.random
    puts "my #{multi_sig_account_keypair.address}"
    puts "mys #{multi_sig_account_keypair.seed}"
    to_file = "./multi_sig_account_keypair.yml"
    puts "save to file #{to_file}"
    File.open(to_file, "w") {|f| f.write(multi_sig_account_keypair.to_yaml) }

    signerA_keypair =Stellar::KeyPair.random
    puts "A #{signerA_keypair.address}"
    puts "As #{signerA_keypair.seed}"
    to_file = "./signerA_keypair.yml"
    puts "save to file #{to_file}"
    File.open(to_file, "w") {|f| f.write(signerA_keypair.to_yaml) }

    signerB_keypair =Stellar::KeyPair.random
    puts "B #{signerB_keypair.address}"
    puts "Bs #{signerB_keypair.seed}"
    to_file = "./signerB_keypair.yml"
    puts "save to file #{to_file}"
    File.open(to_file, "w") {|f| f.write(signerB_keypair.to_yaml) }
    if 1==1
      #fund the multi sign account we will use in the steps bellow 
      puts "create_account multi_sig_account_keypair"
      result = create_account(multi_sig_account_keypair, master, starting_balance)
      puts "#{result}"
      sleep 11
    end
  end
end


# so the real program bellow is just two function calls to create the acc_hash and optionaly modify it then send it 
# to the mss-server.

#this next function will create the acc_hash used in send_to_multi_sign_server function that will setup needed
# account settings and signer preperation.
# you can optionaly setup as many as 20 signers for a single account. This one only has 2 additional signers
# note at this stage the signer keypairs don't need to have the secreet seed
# only the multi_sig_account_keypair needs a secreet key for the transaction at this point

acc_hash = setup_multi_sig_acc_hash(multi_sig_account_keypair,signerA_keypair,signerB_keypair)
puts "tx_hash: #{acc_hash}"

#example out:
#{"action"=>"create_acc", "tx_title"=>"HHHM7L2GSH", "master_address"=>"GC6CMLFLFP6ZKZUA34XPQ3FNHJISZO5QHR3VIM3YOEXESPUNDTC4JDUF", "master_seed"=>"SB2GKZC2XALSYAV3HUDGMKC4BNTVXPCAZTB7FMC2Z2ACTIUCFR22TDL4", "signers_total"=>3, "thesholds"=>{"master_weight"=>1, "low"=>"0", "med"=>3, "high"=>3}, "signer_weights"=>{"GAUKOWGRSXVQVGYXQZ5EWXIHKW3V6LUGUUSERUCPIGDRB6F244XMW5KY"=>1, "GABH7PJKTMTZMO7NJ4TD7KCOV5FC3OK4EDU2DRRZSJ4LO433NNXZR3OC"=>1}}

# at this point you could customize the acc_hash to modify how you want the account thresholds and signer weights to be
# examples:
# acc_hash["signer_weights"]["GDZ4AF..."] = 2
# acc_hash["thesholds"]["high"] = 4
# acc_hash["thesholds"]["med"] = 1
# the default output is to require all signers to sign the transaction to allow validation and submition to the stellar network.
# default for med is the same as high threshold and low is set to zero
# default for signers is all equal with a signing weight of 1

#send the above created and optionaly edited acc_hash to the mss-server for processing
send_to_multi_sign_server(acc_hash)

