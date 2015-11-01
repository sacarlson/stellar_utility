#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
#test and an example usage of sig_b64 = Utils.sign_file(filepath,keypair)
# and Utils.verify_signed_file(filepath, address, sig_b64)
# example creates a file list with a stellar key signature of each file in a directory 
# and then verify that they match the precreated signature file of this directory
# default signature file is ./stellar_file_sigs.txt
# example output seen due to the last file checked was changed by this program writing to it
#list mismatched files: {"./stellar_file_sigs.txt"=>"zZGsdSaRi12SJhdnA1ZQtxTlfCK+JatSgeotIJOYXM07X+d6fM2aw2UX0YZL\n6ozr64K3S+2oqBrzp34Mx6XYBw==\n"}

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
 
#require 'digest'

filepath = "./sign_folder.rb"
address = signerA_keypair.address
keypair = signerA_keypair
puts "keypair address: #{keypair.address}"

def sha256_hash_file(filepath)
  sha1 = Digest::SHA256.new
  File.open(filepath) do|file|
    buffer = ''
    # Read the file 512 bytes at a time
    while not file.eof
      file.read(512, buffer)
      sha1.update(buffer)
    end
  end
  return sha1.to_s
end


def sign_file(filepath,keypair)
  #return a base64 encoded stellar signature of a file at filepath with
  # this keypair.  stellar keypair in this case must include a secreet seed
  hash = sha256_hash_file(filepath)
  result = keypair.sign(hash)
  return Base64.encode64(result)
end

def verify_signed_file(filepath, address, sig_b64)
  #verify this files contents are signed by this stellar address
  #with this signature sig_b64 that is in base64 xdr of a stellar decorated signature structure
  #address can be a public address or keypair with no secreet seed needed
  # see function sign_file(filepath,keypair) that creates this sig_b64 signature from files
  # returns true if file matches signature for address
  keypair = Utils.convert_address_to_keypair(address)
  sig = Base64.decode64(sig_b64)  
  hash = sha256_hash_file(filepath)
  result = keypair.verify(sig,hash)
  return result
end

#******* these functions above now integrated into stellar_utility.rb kept here as reference to bellow code ******

def get_filelist(root_path)
  array = Dir[root_path+'**/*'].reject {|fn| File.directory?(fn) }
end

def create_dir_sig_file(keypair,root_path,save_file_sigs_to)
  #this will create a recusive list of files starting from dir_path_root
  #and create a stellar signature  of the contents of each file in that list using this keypair.
  #and save this file sig list to a file
  file_list = get_filelist(root_path)
  list_hash = {"signer_public_address"=>keypair.address}
  file_list.each do |file|
    sig_b64 = Utils.sign_file(file,keypair)
    #puts "file: #{file}  sig: #{sig_b64}"
    list_hash[file] = sig_b64
  end
  File.open(save_file_sigs_to, "w") {|f| f.write(list_hash.to_yaml) }
end

def verify_file_sigs(address,root_path,sig_list_file)
  #this will check a recusive list of files starting from dir_path_root
  #and return list of files that don't match sig_list_file.
  #the sig_list_file contains a list of files and signature of the contents or these files
  # in this root_path with signatures created with the keypair of 
  #this stellar public address
  #if all files signatures match, then return true
  #if any files don't match the original sig_list_file then return a hash with a list of files that don't match 
  #and the present signature detected
  list_hash_org = YAML.load(File.open(sig_list_file))
  if list_hash_org["signer_public_address"]!= address
    puts "signer_public_address missmatch, will exit"
    return false
  end
  file_list = get_filelist(root_path) 
  list_hash = {}
  file_list.each do |file|
    sig_b64 = list_hash_org[file]
    puts "file: #{file}"
    if file != "signer_public_address"
      if !(Utils.verify_signed_file(file, address, sig_b64))
        list_hash[file] = sig_b64
      end
    end
  end
  if list_hash.length == 0
    return true
  else
    return list_hash
  end
end

root_path = "./"
sig_list_file = "./stellar_file_sigs.txt"
create_dir_sig_file(keypair,root_path,sig_list_file)

puts "list mismatched files: #{verify_file_sigs(address,root_path,sig_list_file)}"
exit -1

sig_b64 = Utils.sign_file(filepath,keypair)

Utils.verify_signed_file(filepath, address, sig_b64)

