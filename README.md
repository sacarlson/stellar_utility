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
it is a work in progress that will be used to create and share multi sign accounts and multi sign transactions.  it's strictly an API json interface not meant for 
direct humans to be running. it's the planed infrastructure that will be used in the upgraded pokerth_accounting system.
I will later be fully documented when I have a fully functional system working and finalized.
to simplify in summery, multi-sign-server is a place where users can publish multi sign accounts and then publish transaction that other users can find, pick them up, and sign them and send back there signings to the server.
The server collects all the needed signatures and will auto submit the transaction when the threshold of needed signers is reached.
At this point the server already picks up and records both accounts and transactions.  The final step that is not done is to count how many valid sigs weights are
collected and merge the signatures onto the final transaction envelope and submit it.  It is not far from completions, maybe 2 - 3 more days.
I have been focusing more on rspec sections of both stellar_utilities and soon multi-sign-server first before I finalize the remaining parts
to be sure it all works and will contine to work even after the stellar network changes again.  The last big stellar network change at horizon3 broke many parts
of stellar_utilitiy that are still not fully functional, but most the major parts are back online and in better form than ever.
