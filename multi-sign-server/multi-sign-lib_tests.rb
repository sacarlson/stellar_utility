# this is not a working copy but just a reference of what may 
#later be translated into rspec for testing multi-sign-lib.rb functions
# for regresion testing of upgrades
#these all worked at one point in the development stage of the lib.

if 1==0
#enable funtion tests
# all pass on sep 8 2015
configs = {}
  configs["mss_db_file_path"] = "/home/sacarlson/github/stellar/stellar_utility/multi-sign-server/multisign.db"
  configs["mss_db_mode"] = "sqlite"
  @mult_sig = Multi_sign.new(configs)
  @mult_sig.create_db

#setup mock transaction post json data structures and other test data
multi_sig_account_create = {"action"=>"create_acc","tx_title"=>"first multi-sig tx","master_address"=>"GDZ4AFAB...","master_seed"=>"SDRES6...","signers_total"=>"2", "thresholds"=>{"master_weight"=>"1","low"=>"0","med"=>"2","high"=>"2"},"signer_weights"=>{"GDZ4AF..."=>"1","GDOJM..."=>"1","zzz"=>"1"}}

multi_sig_tx_submit = {"action"=>"submit_tx","tx_title"=>"test multi sig tx","master_address"=>"GDZ4AFAB...", "tx_envelope_b64"=>"AAAA..."}

multi_sig_tx_get = {"action"=>"get_tx","tx_num"=>"1"}

multi_sig_sign_tx = {"action"=>"sign_tx","tx_title"=>"test tx","tx_code"=>"7ZZUMOSZ26", "signer_address"=>"GAJYGYIa...", "signer_weight"=>"1", "tx_envelope_b64"=>"AAAAzz..."}
master_address = multi_sig_account_create["master_address"]
tx_code = multi_sig_sign_tx["tx_code"]

if 1==1
# setup mock acount data in db and test these functions
result = @mult_sig.add_acc(multi_sig_account_create)
#puts "result: #{result}"
if result == {"acc_num"=>1, "tx_title"=>"first multi-sig tx", "master_address"=>"GDZ4AFAB...", "master_seed"=>"SDRES6...", "signers_total"=>"2"}
  puts " @mult_sig.add_acc(multi_sig_account_create) results ok"
else
  puts " @mult_sig.add_acc(multi_sig_account_create) results bad"
  puts " #{result}"
end


result = @mult_sig.add_tx(multi_sig_tx_submit)
if result == {"status"=>"pending", "tx_code"=>"7ZZUMOSZ26", "signer_count"=>1, "count_needed"=>2}
  puts " @mult_sig.add_tx(multi_sig_tx_submit) results ok"
else
  puts " @mult_sig.add_tx(multi_sig_tx_submit) results bad"
  puts " #{result}"
end

result = @mult_sig.sign_tx(multi_sig_sign_tx)
if result == {"status"=>"ready", "tx_code"=>"7ZZUMOSZ26"}
  puts " @mult_sig.sign_tx(multi_sig_sign_tx) results ok"
else
  puts " @mult_sig.sign_tx(multi_sig_sign_tx) results bad"
  puts " #{result}"
end

end

# test get and utility functions
result = @mult_sig.check_tx_status(tx_code)
#puts "result: #{result}"
if result == {"status"=>"ready", "tx_code"=>"7ZZUMOSZ26"}
  puts " @mult_sig.check_tx_status(tx_code) results ok"
else
  puts " @mult_sig.check_tx_status(tx_code) results bad"
  puts " #{result}"
end

result = @mult_sig.get_acc_threshold_levels(master_address)
#puts "result: #{result["high"]}"
if result == {"acc_num"=>1, "master_address"=>"GDZ4AFAB...", "master_weight"=>"1", "low"=>"0", "med"=>"2", "high"=>"2"}
  puts " @mult_sig.get_acc_threshold_levels(master_address) results ok"
else
  puts " @mult_sig.get_acc_threshold_levels(master_address) results bad"
  puts " #{result}"
end


result = @mult_sig.get_Tx(tx_code)
#puts "result: #{result}"
if result == {"tx_num"=>1, "signer"=>0, "tx_code"=>"7ZZUMOSZ26", "tx_title"=>"test multi sig tx", "signer_address"=>"", "signer_weight"=>"", "master_address"=>"GDZ4AFAB...", "tx_envelope_b64"=>"AAAA...", "signer_sig_b64"=>""}
  puts " @mult_sig.get_Tx(tx_code) results ok"
else
  puts " @mult_sig.get_Tx(tx_code) results bad"
  puts " #{result}"
end


result = @mult_sig.get_Tx_signed(tx_code)
#puts "result: #{result}"
if result.next == {"tx_num"=>2, "signer"=>1, "tx_code"=>"7ZZUMOSZ26", "tx_title"=>"test tx", "signer_address"=>"GAJYGYIa...", "signer_weight"=>"1", "master_address"=>"", "tx_envelope_b64"=>"AAAAzz...", "signer_sig_b64"=>""}
  puts " @mult_sig.get_Tx_signed(tx_code) results ok"
else
  puts " @mult_sig.get_Tx_signed(tx_code) results bad"
  puts " #{result}"
end
#puts "#{result.next}"
#result.each_hash do |row|
#  puts " #{row}"
#end

result = @mult_sig.hash32(multi_sig_sign_tx["tx_envelope_b64"])
#puts "result: #{result}"
if result == "GOZIH3JSNY"
  puts " @mult_sig.hash32(multi_sig_sign_tx[tx_envelope_b64]) results ok"
else
  puts " @mult_sig.hash32(multi_sig_sign_tx[tx_envelope_b64]) results bad"
  puts " #{result}"
end

result = @mult_sig.get_acc_mss(master_address)
#puts "result: #{result}"
if result == {"acc_num"=>1, "tx_title"=>"first multi-sig tx", "master_address"=>"GDZ4AFAB...", "master_seed"=>"SDRES6...", "signers_total"=>"2"}
  puts " @mult_sig.get_acc_mss(master_address) results ok"
else
  puts " @mult_sig.get_acc_mss(master_address) results bad"
  puts " #{result}"
end

result = @mult_sig.get_acc_signers(master_address)
#puts "result: #{result}"
if result == {"GDZ4AF..."=>"1", "GDOJM..."=>"1", "zzz"=>"1"}
 puts " @mult_sig.get_acc_signers(master_address)  result ok"
else
 puts "  @mult_sig.get_acc_signers(master_address)  result bad"
end
#puts "#{result["GDZ4AF..."]}"
#result.each do |x,y|
#  puts "row: #{x}  #{y}"
#end


result = @mult_sig.get_acc_threshold_levels(master_address)
#puts "result: #{result}"
if result == {"acc_num"=>1, "master_address"=>"GDZ4AFAB...", "master_weight"=>"1", "low"=>"0", "med"=>"2", "high"=>"2"}
  puts " @mult_sig.get_acc_threshold_levels(master_address)  result ok"
else
  puts " @mult_sig.get_acc_threshold_levels(master_address)  result bad"
end
puts "tests completed"
exit -1
end

# end function tests*********************************************
