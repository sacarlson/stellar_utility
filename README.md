# stellar_utility
a set of examples to setup transactions on the new stellar-core and a small utility lib that I setup and used to learn with 

The examples here are meant to be run when you are running a local standalone stellar-core on your system.
but now the new version of stellar-utility supports the horizon API interface so a local stellar-core is no longer needs on the client side.
you can still run a local core by haveing the url_stellar_core value correct in the stellar_utilities.cfg file.  Also added at
 ./stellar-db/ are scripts and stellar-core configs I used to do first start ups of stellar-core. run start_core.sh from the directory you plan to have the sqlite database,  or if that fails after first install or any upgrade pulls for stellar-core try reset_core.sh

note: this was writen in my attempts to learn how to use ruby-stellar-base.  I think later I may find
that stellar_core_commander is a better path to start to learning stellar-core features with after we figure out how to configure and use it with a localy hosted stellar-core.  Much of the code in the stellar_utility.rb lib was pulled and ported from what I found and needed in stellar_core_commander sections.  maybe someday I'll port or repackage a stellar_core_commander_lite edition where not all the fancy stuff is needed to be mostly used to integrate into other aplications.  I would also like to add a way to not only point controls to a localhosted stellar-core or docker core, but also send transactions through to the horizon website api interface with the commander as I now do with stellar_utility now.  When I get that all figured out maybe I'll also add it to this repository as a reference for others to learn from.

working examples included:

create_account.rb
 sets up a new active random account with funding from the default master account
 
send_native.rb
  demonstrates sending native lunes from one account to another
  
send_non_native.rb
  demonstrates sending non native currency "USD" in this case from one account to another
  
create_offers.rb
  demonstrates setting up order offers on the stellar-core network
  
there are many other examples most of them working at one point or another.
note at this point we do have the horizon interface also working that is selectable from changes made in stellar_utility.cfg file.
The config file is in need of documentation that I also haven't goten to.  The configs allows making many changes to point at old and new versions of
stellar using different typs of databases including sqlite3 and postgres support. We now also support the open-core branched network.

the bigest addition in this system set is called multi-sign-server system that is a whole new set of files that should probly be in another repository of it's own at some point.
it is a work in progress that will be used to create and share multi sign accounts and multi sign transactions.  it's strictly an API json restclient interface not realy meant for direct humans to be running. it's the planed infrastructure that will be used in the upgraded pokerth_accounting system.
It will later be fully documented when I have a fully functional system working and finalized.
to simplify in summery, multi-sign-server is a place where users can publish multi sign accounts and then publish transaction that other users can find, pick them up, and sign them and send back there signings to the server.
The server collects all the needed signatures and will auto submit the transaction when the threshold of needed signers is reached.
At this point the server already picks up and records both accounts and transactions.  The final step that is not done is to count how many valid sigs weights are
collected and merge the signatures onto the final transaction envelope and submit it.  It is not far from completions, maybe 2 - 3 more days.
I have been focusing more on rspec sections of both stellar_utilities and soon multi-sign-server first before I finalize the remaining parts
to be sure it all works and will contine to work even after the stellar network changes again.  The last big stellar network change at horizon3 broke many parts
of stellar_utilitiy that are still not fully functional, but most the major parts are back online and in better form than ever.

The main files and examples in multi-sign-server (also called mss-server) system explained:

multi-sign-server/multi-sign-server.rb:
  is the central servers of the mss-server system that runs and listens on port 9494 by default
  it has a Json API interface that is in a structure that is easiest to explain with examples but in this case in ruby hash format:
  create_acc = {"action"=>"create_acc","tx_title"=>"first multi-sig tx","master_address"=>"GDZ4AF...","master_seed"=>"SDRES6...","signers_total"=>"2", "thresholds"=>{"master_weight"=>"1","low"=>"0","med"=>"2","high"=>"2"},"signer_weights"=>{"GDZ4AF..."=>"1","GDOJM..."=>"1","zzz"=>"1"}}
    status_tx = {"action"=>"status_tx","tx_code"=>"RQJXT3BNBU"}
    status_acc = {"action"=>"status_acc","acc_num"=>"GDZ4AF..."}
    submit_tx = {"action"=>"submit_tx","tx_title"=>"test multi sig tx","acc_num"=>"123", "tx_envelope_b64"=>"AAAA..."}
    return_submit_tx = {"status"=>"success","tx_code"=>"URWOTGHR"}
    get_tx = {"action"=>"get_tx","tx_code"=>"RQJXT3BNBU"}
    return_get_tx = {"status"=>"pending","tx_num"=>"123","tx_envelope_b64"=>"AAAA..."}
    sign_tx = {"action"=>"sign_tx","tx_title"=>"test tx","tx_code"=>"JIEWFJYE", "signer_address"=>"GAJYGYI...", "signer_weight"=>"1", "tx_envelope_b64"=>"AAAA..."}
    return_sign_tx = {"status"=>"pending","tx_code"=>"URWOTGHR"}
    send_tx = {"action"=>"send_tx","tx_code"=>"W3M4PUQE3J"}
    
    return_status_tx = {"status"=>"sent","tx_num"=>"123","sign_count"=>"2","signed"=>["GDZ4AF...","GDOJM..."]}
    #status pending means that the transaction hasn't got all the needed signers yet, sent means we got the signers and it was transacted
    return_status_tx_not_sent = {"status"=>"pending","tx_num"=>"123","sign_count"=>"1","signed"=>["GDZ4AF..."]}

    These hash examples can be translated and sent to the multi-sign-server using send_restclient_test.rb
    or when translated to json you can send and get results with curl or any restclient compatible agent.



multi-sign-server/create_account_for_mss.rb
  that demonstrates how a client master account creator can create a multi signed account and then published it on the mss-server

multi-sign-server/submit_transaction_to_mss.rb
  that demonstrates how the master account created in create_account_for_mss.rb can be used to create a multi signed transaction and publish it to the mss-server

multi-sign-server/sign_transaction_mss.rb
  That demonstrates how signer clients would pickup the published transactions from mss-server, sign them and send them back to the mss-server that continues to 
  collect and count the signitures and when enuf collected the mss-server submits the transactions to the stellar network to be verified.
