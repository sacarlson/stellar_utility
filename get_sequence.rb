#!/usr/bin/env ruby
require 'stellar-base'
require 'faraday'
require 'faraday_middleware'
require 'json'
require 'rest-client'

#pull sequence out of this hash
# curl https://horizon-testnet.stellar.org/accounts/gspbxqXqEUZkiCCEFFCN9Vu4FLucdjLLdLcsV6E82Qc1T7ehsTC
# curl https://horizon-testnet.stellar.org/accounts/gspbxqXqEUZkiCCEFFCN9Vu4FLucdjLLdLcsV6E82Qc1T7ehsTC

#{  new working account that had 1000 native on jul 17 2015
#	address: gwfVeurZHYGePUFBWfyNSp8uPwXQJs27tmCWppQGqnS5xt5inV,
# 	seed: s3w3yuHe8g9vF3WdRk8XX33UMQyxhfkA1AfTEDiLi23nKF8Wk63
#}

#account = "gwfVeurZHYGePUFBWfyNSp8uPwXQJs27tmCWppQGqnS5xt5inV"
#account = "gspbxqXqEUZkiCCEFFCN9Vu4FLucdjLLdLcsV6E82Qc1T7ehsTC"
#account = "gsUrFMansosSNaWByqRFa7VT81ok1ymfvnd6kdBRkH2932a6ptR"
account = "gQakKb1AgucHVLZ1RRE8G8GAPRVYH7pCNTWt2mRfZGHLXuU3WV"
#account = "g8kJv873ZgBNpiUMZqWqXPdT2QbmGU5jxkBRXaDTBS2647chcP" bad
#account = "gtJ7xih3uNU82S3soESuRC9xiEhDRktFtgmxFqvRM6teXgWwZY" bad
#seed sfCFULZU5YasDFeWdVgzCzTmjeVzvvqfaBXxwtk3kuTVS35Cn6J

def get_account_info(account)
    params = '/accounts/'
    url = 'https://horizon-testnet.stellar.org'
    send = url + params + account
    #puts "#{send}"
    postdata = RestClient.get send
    data = JSON.parse(postdata)
    return data
end
#result = get_account_info(account)
#puts "#{result}"


def get_account_sequence(account)
  data = get_account_info(account)
  return data["sequence"]
end

result = get_account_sequence(account)
puts "#{result}"

def get_ballances(account)
  data = get_account_info(account)
  return data["balances"]
end

result = get_ballances(account)
puts "#{result}"

__END__

hash = {"_links"=>{"effects"=>{"href"=>"/accounts/gWRYUerEKuz53tstxEuR3NCkiQDcV4wzFHmvLnZmj7PUqxW2wn/effects/{?cursor,limit,order}", "templated"=>true}, "offers"=>{"href"=>"/accounts/gWRYUerEKuz53tstxEuR3NCkiQDcV4wzFHmvLnZmj7PUqxW2wn/offers/{?cursor,limit,order}", "templated"=>true}, "operations"=>{"href"=>"/accounts/gWRYUerEKuz53tstxEuR3NCkiQDcV4wzFHmvLnZmj7PUqxW2wn/operations/{?cursor,limit,order}", "templated"=>true}, "self"=>{"href"=>"/accounts/gWRYUerEKuz53tstxEuR3NCkiQDcV4wzFHmvLnZmj7PUqxW2wn"}, "transactions"=>{"href"=>"/accounts/gWRYUerEKuz53tstxEuR3NCkiQDcV4wzFHmvLnZmj7PUqxW2wn/transactions/{?cursor,limit,order}", "templated"=>true}}, "id"=>"gWRYUerEKuz53tstxEuR3NCkiQDcV4wzFHmvLnZmj7PUqxW2wn", "paging_token"=>"315087390773248", "address"=>"gWRYUerEKuz53tstxEuR3NCkiQDcV4wzFHmvLnZmj7PUqxW2wn", "sequence"=>315087390769152, "balances"=>[{"currency_type"=>"native", "balance"=>1000000000}]}

hash.each do |x|
  puts "#{x}"
end
puts ""
puts "#{hash["sequence"]}"
