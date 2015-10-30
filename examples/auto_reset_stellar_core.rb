#!/usr/bin/ruby
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
# a hack to auto reset the stellar-core when it fails to sync after dynamic ip changes
# this happens to me when my ISP provider for my ADSL home Internet changes my IP address every 24 hours 
require 'rest-client'

#url address and port of stellar-core being monitored
url_core="localhost:8080"

#time between checks
check_interval = 60

#time to wait after first fail detect before finalized fail
timeout = 430

#time to check after soft and hard reset
post_reset_time = 420

def log_event(notes)
  timetag = Time.now.strftime("%d/%m/%Y %H:%M __")
  ip = RestClient.get "ip.appspot.com"
  puts timetag+" IP:"+ip+": "+notes  
  open('./stellar-core_status.log', 'a') { |f|
    f.puts timetag+" IP:"+ip+": "+notes
  }
end

def get_stellar_core_status(detail=false, url="localhost:8080" )
    #return true if stellar-core status is synced false if other than synced
    #if detail is true then return a hash containing all that is seen in return from stellar-core responce
    params = '/info'
    #url = @configs["url_stellar_core"]
    #url = "localhost:8080"
    #puts "url_stellar_core:  #{url}"
    send = url + params
    #puts "sending:  #{send}"
    begin
    postdata = RestClient.get send
    rescue => e
      puts "failed to connect to #{url}"
      return  false
    end
    #puts "postdata: #{postdata}"
    data = JSON.parse(postdata)
    #puts "data: #{data}"
    if detail == true
      return data
    end
    puts "data.state: #{data["info"]["state"]}"
    if data["info"]["state"] != "Synced!"
      return false
    else 
      return true
    end
end

def reset_stellar_core(hard = false)
  #kill and restart the stellar-core
  #if hard = true will do full database reset
  puts "got here"
  result = %x(ps -A |grep stellar)
  puts "result: #{result.include?("stellar-core")}"
  if result.include?("stellar-core")
    result = %x(killall stellar-core)
  else
    log_event("no stellar-core detected as running, so will start it now")
    if hard == true
      child_pid = fork do
        puts "This is the child process"
        result = %x(/home/sacarlson/github/stellar/stellar_utility/stellar-db2/reset_core_testnet.sh)
      end
    else
      child_pid = fork do
        puts "This is the child process"
        result = %x(/home/sacarlson/github/stellar/stellar_utility/stellar-db2/start_stellar_core_testnet.sh)
        exit
      end
      puts "child_pid: #{child_pid}"
    end
    puts "result_start: #{result}"
    return result
  end
  sleep 30
  if hard == true
    log_event("hard reset started on stellar-core")
    child_pid = fork do
      puts "This is the child process"      
      result = %x(/home/sacarlson/github/stellar/stellar_utility/stellar-db2/reset_core_testnet.sh)
    end
  else    
    log_event("soft reset started on stellar-core")
    child_pid = fork do
      puts "This is the child process"
      result = %x(/home/sacarlson/github/stellar/stellar_utility/stellar-db2/start_stellar_core_testnet.sh)
      exit
    end
    puts "child_pid: #{child_pid}"
  end
  puts "result_start: #{result}"
  return result
end


def check_stellar_core(timeout, check_interval, url_core )

  if get_stellar_core_status(false,url_core)
    puts "stellar core is already in sync, nothing to be done"
    return true
  end

  log_event("core out of sync detected")

  sleep(timeout)

  if get_stellar_core_status(false,url_core)
    log_event("core back in sync")
    return true
  end

  log_event("core still out of sync, soft reset will be started")
  reset_stellar_core(hard = false)
  sleep check_interval

  if get_stellar_core_status(false,url_core)
    log_event("core back in sync")
    return true
  end
  log_event("core still out of sync after soft reset, hard reset started")
  reset_stellar_core(hard = true)
  sleep check_interval

  if get_stellar_core_status(false,url_core)
    log_event("core back in sync")
    return true
  end
  log_event("core still out of sync after hard reset, we give up, let scotty check it out, will exit now")
  return false
end

#*************************** Start program ****************

log_event("auto reset stellar-core monitor started")
reset_stellar_core(hard = false)
puts "will sleep #{post_reset_time} sec before first check"
sleep post_reset_time
result = get_stellar_core_status(false,url_core)


count = 0
while 1==1 do
  puts "start loop count# #{count}"
  count= count + 1
  result = check_stellar_core(timeout, post_reset_time, url_core)
  if result == false
    exit -1
  end
  sleep check_interval
end

