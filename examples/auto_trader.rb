#!/usr/bin/ruby
#(c) 2016 Sep 14. by sacarlson  sacarlson_2000@yahoo.com aka Scott Carlson aka scotty.surething...
# This will be the prototype of an auto trader that will pull prices of currency off the yahoo API and/or openexchangerates.org
# and with this data will setup a single or pair of trades on the stellar.org network
#

# example: auto_trade_offer(trader_account, sell_issuer, sell_currency, buy_issuer, buy_currency, amount, profit_margin, key)
# 
# trader_account: the account pair secret, public to be used to setup the trade offer transaction
# sell_issuer: the issuer public address of the sell_currency
# sell_currency: the asset_code of the currency we will setup offer to sell (or trade) in exchange for buy_currency
# buy_issuer: the issuer public address of the buy_currency
# buy_currency: the asset_code of the currency we will setup offer to buy (or trade) in exchange for sell_currency
# key: the API key if needed for the get_exchangerate(currency_code,base_code,key="") some feeds require money and sign up that also require keys
#
# amount: the amount (qty shares) of sell_currency we will be offering to sell (or trade) in the offer to exchange
# profit_margin: value in percent, to set price to sell sell_currency above present value seen from yahoo API data feed of price per share exchange
#
# note: that the values sell_currency and buy_currency are equivalent in get_exchangerate(currency_code,base_code,key)
# as:
# base_code = buy_currency
# currency_code = sell_currency
# example #1 buy_currency or base_code of 1 USD we will sell currency_code THB for 34.9400 baht 
# example #2 buy_currency or base_code of 1 THB we will sell currency_code  USD for 0.0286 USD or 2.8 cents
#
#
# to start app: bundler exec ruby ./auto_trader.rb

# Utils.offer(sellers_account,sell_issuer,sell_currency, buy_issuer, buy_currency,amount,price)



require '../lib/stellar_utility/stellar_utility.rb'
require "mysql"

Utils = Stellar_utility::Utils.new("./testnet_read_ticker.cfg")

#see https://currencylayer.com to get this key
currencylayer_key = Utils.configs["currencylayer_key"]

#see https://openexchangerates.org to get this key
openexchangerates_key = Utils.configs["openexchangerates_key"]

#trader_account public addressId = GBROAGZJGZSSQWJIIH2OHOPQUI4ZDZL4MOH7CSWLQBDGWBYDCDQT7CU4
trader_account = Stellar::KeyPair.from_seed(Utils.configs["trader_account"])

trader_account_sell = trader_account
trader_account_buy = trader_account

#public addressId = GBIKT3CMSHZBQS7UAHU5YW6OXXPDSOWLNQMTF6Y7ALIWX7SLVIAV74NP
#trader_account_buy = Stellar::KeyPair.from_seed("xxxx")

#  config settings
sell_currency = "THB"
#public address of selling asset issuer
sell_issuer = "GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF"
#amount to sell
amount = 100
buy_currency = "USD"
#pubic address of buying asset issuer
buy_issuer = "GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF"
#profit margin in percent 
profit_margin = 2


$last_rate = 0
currency_code = "THB"
base_code = "USD"

#puts "Utils version: #{Utils.version}"
#puts "configs: #{Utils.configs}"

def auto_trade_offer(trader_account, sell_issuer, sell_currency, buy_issuer, buy_currency, amount, profit_margin=0,key="")
  # example: auto_trade_offer(trader_account, sell_issuer, sell_currency, buy_issuer, buy_currency, amount, profit_margin,key)
  # 
  # trader_account: the account pair secret, public to be used to setup the trade offer transaction
  # sell_issuer: the issuer public address of the sell_currency
  # sell_currency: the asset_code of the currency we will setup offer to sell (or trade) in exchange for buy_currency
  # buy_issuer: the issuer public address of the buy_currency
  # buy_currency: the asset_code of the currency we will setup offer to buy (or trade) in exchange for sell_currency
  # key: the API key if needed for the get_exchangerate(currency_code,base_code,key="") some feeds require money and sign up that also require keys
  #
  # amount: the amount (qty shares) of sell_currency we will be offering to sell (or trade) in the offer to exchange
  # profit_margin: value in percent, to set price to sell sell_currency above present value seen from yahoo API data feed of price per share exchange
  #
  # note: that the values sell_currency and buy_currency are equivalent in get_exchangerate(currency_code,base_code,key)
  # as:
  # base_code = buy_currency
  # currency_code = sell_currency
  # example #1 with buy_currency or base_code of 1 USD we will sell currency_code THB for 34.9400 baht 
  # example #2 with buy_currency or base_code of 1 THB we will sell currency_code  USD for 0.0286 USD or 2.8 cents
  #

  base_code = buy_currency
  currency_code = sell_currency
  result = get_exchangerate(currency_code,base_code,key)
  puts "last_rate: #{$last_rate}"
  going_rate = result["rate"].to_f
  $last_rate = going_rate
  price = going_rate + ((profit_margin.to_f/100.0)*going_rate)
  puts "going_rate: #{going_rate}"
  puts "price: #{price}"
  puts "amount: #{amount}"
  puts "trader_account: #{trader_account.address}"
  puts "sell_currency: #{sell_currency}"
  puts "sell_issuer: #{sell_issuer}"
  puts "buy_currency: #{buy_currency}"
  puts "buy_issuer: #{buy_issuer}"
  send_offer(trader_account,sell_issuer,sell_currency, buy_issuer, buy_currency,amount,price)
end

def auto_trade_offer_set_dual_traders(trader_account_sell,trader_account_buy, sell_issuer, sell_currency, buy_issuer, buy_currency, amount, profit_margin=0,key="")
  #this will setup trades on both above and bellow the present market ask price of the asset with the set profit_margin percent markup price
  # it will setup sell trade with profit_margin percent so sell_price = market_ask_price + (market_ask_price * (profit_margin/100))
  # with unchanged amount value that we will now call amount_sell = amount
  # it will setup buy trade with profit_margin percent so buy_price = market_ask_price - (market_ask_price * (profit_margin/100))
  # with value amount_buy = amount_sell * (1 / sell_price)
  # so this should setup about equal trade values on both above and bellow present market trade price
  # see auto_trade_offer function for details on auto trading

  base_code = buy_currency
  currency_code = sell_currency
  result = get_exchangerate(currency_code,base_code,key)
  puts "last_rate: #{$last_rate}"
  market_ask_price = result["rate"].to_f

  sell_price = (market_ask_price + (market_ask_price * (profit_margin.to_f/100.0)))
  buy_price = (1/market_ask_price) + ((1/market_ask_price) * (profit_margin.to_f/100.0))
  amount_sell = amount
  amount_buy = amount_sell / (1.0 / sell_price)

  puts "trader_account_sell: #{trader_account_sell.address}"
  puts "profit margin percent: #{profit_margin.to_f}"
  puts "profit margin dec: #{profit_margin.to_f/100.0}"
  puts ""
  puts "market_ask_price: #{market_ask_price.to_f}"
  puts "margin difference: #{(market_ask_price.to_f * (profit_margin.to_f/100.0))}"
  puts "sell_currency: #{sell_currency}"
  puts "sell_issuer: #{sell_issuer}"
  puts "sell_price: #{sell_price}"
  puts "sell_priceR: #{1.0/sell_price}"
  puts "amount_sell: #{amount_sell}"
  puts ""
  puts "trader_account_buy: #{trader_account_buy.address}"
  puts "market_ask_price_R: #{1.0/market_ask_price.to_f}"
  puts "margin difference: #{((1.0/market_ask_price.to_f) * (profit_margin.to_f/100.0))}"    
  puts "buy_currency: #{buy_currency}"
  puts "buy_issuer: #{buy_issuer}"
  puts "buy_price: #{buy_price}"
  puts "buy_priceR: #{1.0/buy_price}"
  puts "amount_buy: #{amount_buy}"
 
  send_offer(trader_account_sell, sell_issuer, sell_currency, buy_issuer, buy_currency, amount_sell, sell_price)

  sleep 2

  send_offer(trader_account_buy, buy_issuer, buy_currency, sell_issuer, sell_currency, amount_buy, buy_price)

end

def auto_trade_offer_set(trader_account, sell_issuer, sell_currency, buy_issuer, buy_currency, amount, profit_margin=0,key="")
  #this will setup trades on both above and bellow the present market ask price of the asset with the set profit_margin percent markup price
  # it will setup sell trade with profit_margin percent so sell_price = market_ask_price + (market_ask_price * (profit_margin/100))
  # with unchanged amount value that we will now call amount_sell = amount
  # it will setup buy trade with profit_margin percent so buy_price = market_ask_price - (market_ask_price * (profit_margin/100))
  # with value amount_buy = amount_sell * (1 / sell_price)
  # so this should setup about equal trade values on both above and bellow present market trade price
  # see auto_trade_offer function for details on auto trading

  base_code = buy_currency
  currency_code = sell_currency
  result = get_exchangerate(currency_code,base_code,key)
  puts "last_rate: #{$last_rate}"
  market_ask_price = result["rate"].to_f

  sell_price = (market_ask_price + (market_ask_price * (profit_margin.to_f/100.0)))
  buy_price = (1/market_ask_price) + ((1/market_ask_price) * (profit_margin.to_f/100.0))
  amount_sell = amount
  amount_buy = amount_sell / (1.0 / sell_price)

  puts "trader_account: #{trader_account.address}"
  puts "profit margin percent: #{profit_margin.to_f}"
  puts "profit margin dec: #{profit_margin.to_f/100.0}"
  puts ""
  puts "market_ask_price: #{market_ask_price.to_f}"
  puts "margin difference: #{(market_ask_price.to_f * (profit_margin.to_f/100.0))}"
  puts "sell_currency: #{sell_currency}"
  puts "sell_issuer: #{sell_issuer}"
  puts "sell_price: #{sell_price}"
  puts "sell_priceR: #{1.0/sell_price}"
  puts "amount_sell: #{amount_sell}"
  puts ""
  puts "market_ask_price_R: #{1.0/market_ask_price.to_f}"
  puts "margin difference: #{((1.0/market_ask_price.to_f) * (profit_margin.to_f/100.0))}"    
  puts "buy_currency: #{buy_currency}"
  puts "buy_issuer: #{buy_issuer}"
  puts "buy_price: #{buy_price}"
  puts "buy_priceR: #{1.0/buy_price}"
  puts "amount_buy: #{amount_buy}"
 
  send_offer(trader_account, sell_issuer, sell_currency, buy_issuer, buy_currency, amount_sell.to_f, sell_price.to_f)

  sleep 2

  send_offer(trader_account, buy_issuer, buy_currency, sell_issuer, sell_currency, amount_buy.to_f, buy_price.to_f)

end


def get_yahoo_finance_exchangerate(currency_code,base_code)
 # note it seems USD/THB is delayed by about 30 minutes and in fact buy random time windows so be careful using this data
 # some others are delayed by much more like THB/USD can be 6 hours or more delayed  
 #https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20yahoo.finance.xchange%20where%20pair%20in%20(%22USDTHB%22)&format=json&diagnostics=true&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&callback=

    # if more than one currency is needed
    url_start_b = "https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20yahoo.finance.xchange%20where%20pair%20in%20"
    url_end_b = "&format=json&diagnostics=true&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&callback="
    # with just a single currency
    url_start = "https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20yahoo.finance.xchange%20where%20pair%20in%20(%22"
    url_end = "%22)&format=json&diagnostics=true&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&callback="
    puts " currency_code: #{currency_code}"
    puts " base_code: #{base_code}"
    send = url_start + currency_code + base_code + url_end
    #send = url_start_b +'(%22' + base_code + currency_code + '%22)' +  url_end_b
    # to lookup more than one currency at the same time
    #send = url_start_b +'(%22USDEUR%22,%20%22USDJPY%22)' +  url_end_b
    #puts "sending:  #{send}"
    begin
    postdata = RestClient.get send
    rescue => e
      return  e.response
    end
    #puts "postdata: " + postdata
    data = JSON.parse(postdata)
    data["rate"] = data["query"]["results"]["rate"]["Rate"].to_s
    data["datetime"] = data["query"]["results"]["rate"]["Date"].to_s + "T" + data["query"]["results"]["rate"]["Time"].to_s
    data["ask"] = data["query"]["results"]["rate"]["Ask"]
    data["bid"] = data["query"]["results"]["rate"]["Bid"]
    data["base"] = base_code
    return data
end


def get_currencylayer_exchangerate(currency_code,key)
  #  this does not work yet for reasons uknown probly headers needed but now sure what headers
  # this one when free will only do lookups compared to USD, also limits to 1000 lookup per month so only 1 per hour
  # but can lookup more than one currency at a time with coma delimited string
  # I see nothing better bettween apilayer.net and https://openexchangerates.org so we are no longer trying to support this one
  # if someone see's anything better here maybe we will again attempt to add it.
  #http://apilayer.net/api/live?access_key=fe2f96f017b702fec2f0c1e8092ae88f&currencies=THB,AUD&format=1

  url_start = "http://apilayer.net/api/live?access_key="
  url_end = "&format=1"
  send = url_start + key + "&currencies=" + currency_code +  url_end
  #send = "https://www.funtracker.site/map.html"
    puts "sending:  #{send}"
    begin
      #postdata = RestClient.get send , :user_agent => "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:47.0) Gecko/20100101 Firefox/47.0"
      postdata = RestClient.get send , { :Accept => '*/*', 'accept-encoding' => "gzip, deflate", :user_agent => "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:47.0) Gecko/20100101 Firefox/47.0"}
    rescue => e
      return  e.response
    end
    puts "postdata: " + postdata
    data = JSON.parse(postdata)
    return data
end

def get_poloniex_exchangerate(currency_code,base_code)
  #https://poloniex.com/public?command=returnOrderBook&currencyPair=BTC_STR
  # see: https://www.poloniex.com/support/api/ for details
  url_start = "https://poloniex.com/public?command=returnOrderBook&currencyPair="
  url_end = ""
  send = url_start + base_code + "_" + currency_code 
  puts "sending:  #{send}"
  begin
    postdata = RestClient.get send , { :Accept => '*/*', 'accept-encoding' => "gzip, deflate", :user_agent => "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:47.0) Gecko/20100101 Firefox/47.0"}
  rescue => e
    return  e.response
  end
  #puts "postdata: " + postdata
  data = JSON.parse(postdata)
  return data
end

#  data as seen from: https://poloniex.com/public?command=returnOrderBook&currencyPair=BTC_STR
#"asks":[["0.00000350",279686.42305454],["0.00000351",89018.26064602],["0.00000352",514346.31778051],["0.00000353",132533.55189335],["0.00000354",122766.37862908],["0.00000355",320471.11853559],["0.00000356",20000],["0.00000357",21198.2],["0.00000358",20000],["0.00000359",110000],["0.00000360",21156.00378728],["0.00000361",147639.69514127],["0.00000362",325719.00666655],["0.00000363",407287.46594513],["0.00000364",387443.86603574],["0.00000365",503595.53528734],["0.00000366",34675.82356483],["0.00000367",489740.86461743],["0.00000368",2792185.4781983],["0.00000369",125635.42444457],["0.00000370",12169.01944962],["0.00000371",106565.2654594],["0.00000372",25731.90331445],["0.00000373",100416.701145],["0.00000374",100433.98972434],["0.00000375",34501.7646708],["0.00000376",199535.58534803],["0.00000377",264268],["0.00000378",105228.95529689],["0.00000379",346858.2408121],["0.00000380",1167539.8296809],["0.00000381",7094.18218139],["0.00000382",2750.68870523],["0.00000383",1183.73976116],["0.00000386",500],["0.00000387",299733.17164878],["0.00000388",499250.5],["0.00000389",21039.69400478],["0.00000390",457047.50064103],["0.00000391",2637.74428087],["0.00000392",181.1892992],["0.00000393",1500],["0.00000394",305174.8239911],["0.00000395",184333.63198436],["0.00000396",596639.04],["0.00000397",5925.38094307],["0.00000398",90398.85896785],["0.00000400",435847.55605688],["0.00000401",57680.21761456],["0.00000406",26083.49772116]],"bids":[["0.00000344",1165.64244186],["0.00000343",174542.14303209],["0.00000342",300438.98276001],["0.00000341",395092.23294599],["0.00000340",1545465.4025835],["0.00000339",25318.58407079],["0.00000338",616745.56508876],["0.00000337",28745.99680754],["0.00000336",239219.29600937],["0.00000335",186349.87489555],["0.00000334",1073137.0640403],["0.00000333",2193310.8301359],["0.00000332",126321.09274824],["0.00000331",30642.68137558],["0.00000330",756751.18370449],["0.00000329",212748.01443768],["0.00000328",146800.13167322],["0.00000327",162853.98236137],["0.00000326",36893.46385377],["0.00000325",1856135.7257234],["0.00000324",30500],["0.00000323",637915.5601449],["0.00000322",130769.04517739],["0.00000321",645232.18679988],["0.00000320",1634293.9478452],["0.00000319",31529.56751848],["0.00000318",138555.00884435],["0.00000317",1113464.2878347],["0.00000316",276013.49999998],["0.00000315",788968.27148898],["0.00000314",25000],["0.00000313",280488.00958466],["0.00000312",105329.92403145],["0.00000311",334358.45764935],["0.00000310",1421179.8297221],["0.00000309",1022950.5706013],["0.00000308",95061.81560324],["0.00000307",34886.66579372],["0.00000306",25000],["0.00000305",144907.76393442],["0.00000304",25000],["0.00000303",91402.71245924],["0.00000302",25000],["0.00000301",485000],["0.00000300",1130997.9931911],["0.00000299",48.16053511],["0.00000298",6000],["0.00000297",14526.7003367],["0.00000295",23963.23050847],["0.00000294",1820.1691914]],"isFrozen":"0","seq":6482153}

def get_openexchangerates(currency_code,base_code,key)
  #   this is tested as working and so far is seen as the best in the lot  
  # this one when free will only do lookups compared to USD, also limits to 1000 lookup per month so only 1 per hour
  # at $12/month Hourly Updates, 10,000 api request/month
  # at $47/month 30-minute Updates, 100,000 api request/month
  # at $97/month 10-minute Updates, unlimited api request/month + currency conversion requests
  # does lookup more than one currency at a time
  #https://openexchangerates.org/api/latest.json?app_id=xxxxxxx
  # see: https://openexchangerates.org/
  #  example usage:
  #   result = get_openexchangerates("THB","JPY", openexchangerates_key)
  #   puts "rate: " + result["rate"].to_s  ; rate: 2.935490234019467
  #
  # inputs: 
  #  currency_code: the currency code to lookup example THB
  #  base_code: the currency base to use in calculating exchange example USD  or THB  or BTC
  #  key: the api authentication key obtained from https://openexchangerates.org
  #
  # return results:
  #  rate: the calculated rate of exchange
  #  timestamp: time the rate was taken in seconds_since_epoch_integer format (not sure how accurate as the time is the same for all asset currency)
  #  datetime: time in standard human readable format example: 2016-09-15T08:00:14+07:00
  #  base: the base code of the currency being calculated example USD
  #   example if 1 USD is selling for 34.46 THB then rate will return 34.46 for base USD
  #   example#2 if 1 USD is selling for 101.19 KES then rate will return 101.19 for base of USD
  #   example#3 with the same values above  1 THB is selling for 2.901 KES so rate will return 2.901 for base of KES  

  url_start = "https://openexchangerates.org/api/latest.json?app_id="
  url_end = ""
  send = url_start + key
  #puts "sending:  #{send}"
  begin
    #postdata = RestClient.get send , { :Accept => '*/*', 'accept-encoding' => "gzip, deflate", :user_agent => "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:47.0) Gecko/20100101 Firefox/47.0"}
    postdata = RestClient.get send , { :Accept => '*/*', 'accept-encoding' => "gzip, deflate"}
  rescue => e
    return  e.response
  end
  #puts "postdata: " + postdata
  data = JSON.parse(postdata)
  
  if (base_code == "USD")
    #defaults to USD
    data["base"] = base_code
    data["datetime"] = Time.at(data["timestamp"]).to_datetime.to_s
    #date["rate"] = data["rates"][currency_code]
    data["rate"] = (1 / data["rates"][currency_code]).to_s
    return data
  end
  usd_base_rate = data["rates"][currency_code]
  base_rate = data["rates"][base_code]
  rate = base_rate / usd_base_rate
  data["rate"] = rate.to_s
  data["base"] = base_code
  data["datetime"] = Time.at(data["timestamp"]).to_datetime.to_s
  return data
end

def get_exchangerate(currency_code,base_code,key="")
  # set to default exchange rate feed source
  return get_openexchangerates(currency_code,base_code,key)
  #return get_yahoo_finance_exchangerate(currency_code,base_code)
end

def send_offer(sellers_account,sell_issuer,sell_currency, buy_issuer, buy_currency,amount,price,offerid="")
  b64 = Utils.offer(sellers_account,sell_issuer,sell_currency, buy_issuer, buy_currency,amount,price,offerid)
  result = Utils.send_tx(b64)
  #puts "send_tx result #{result}"
end

def convert_polo_to_liquid(data_hash_in, min_liquid_shares)
  #this will convert our standard poloniex exchange api format to our
  # shrunken liquid data format:
  #this will return the price of a poloniex exchange traded asset pair that
  # would be requied to bid or ask if you were to purchase or sell min_liquid_shares of that asset.
  # this only takes a snapshot at the time so may not be what can be achieved at time of order
  # this should at least give you some clue at a glance as to the real price when working with the funds 
  # you plan to be trading.
  # return result example:
  #  {"ask"=>{"price"=>"0.00000383", "volume"=>"578679.19417415", "avg_price"=>"0.00000383", "offer_count"=>3, "total_volume"=>"10683552.18423253", "total_avg_price"=>"0.00000408", "total_offers"=>50}, "bid"=>{"price"=>"0.00000372", "volume"=>"333182.73763676", "avg_price"=>"0.00000372", "offer_count"=>2, "total_volume"=>"18066738.30346057", "total_avg_price"=>"0.00000341", "total_offers"=>50}}
  # 
  # price: is the price you would have to ask or bid to acheive liquidity on your order
  # volume: at this point is only the volume that was acumulated at the point your threshold of min_liquid_shares
  #   was achieved, this number maybe very close or far (much more) than your min_liquid_share if big blocks of shares are 
  #   trading within or near your min number.
  # avg_price: is the actual price you would end up paying (not exact) in your order due to averge price from bottom bid to top
  # offer_count: the number of orders you had to hit before your liquidity was reached
  # total_volume: provides the total number of shares that are now up for sale on ask or bid at a price in the market
  # total_avg_price: this is the price you would ask or bid to buy all present market orders now seen in market (not really useful but?)
  # total_offers: is the total number of orders now seen in bid and ask at this time.  seems to always be 50 so maybe that's just all they show?
  # base: base asset asset_code, asset_issuer contained but only if from stellar format data_hash, this data must be manualy added if from polo
  # counter: counter assets asset_code, asset_issuer info if from stellar format data_hash
  #
  # example currency_code of STR at base_code of BTC with min_liquid_shares set at 300000 shares of STR:
  #  get_poloniex_exchange_liquid("STR","BTC",300000)
  #  
  # 
  result = data_hash_in
  out_result = {}
  out_result["ask"] = {}
  out_result["bid"] = {}
  if !data_hash_in["base"].nil?
    out_result["base"] = data_hash_in["base"]
    out_result["counter"] = data_hash_in["counter"]
  end
  offer_count = 0
  liquid_mark = false
  total_volume = 0
  total_price = 0

  result["asks"].each{ |row|
    #puts "price: #{row[0]}"
    #puts "volume: #{row[1]}"
    total_volume = total_volume + row[1].to_f
    #puts "total vol: #{total_ask_volume}"
    total_price = total_price + (row[0].to_f * row[1].to_f)
    offer_count = offer_count + 1
    if (total_volume > min_liquid_shares && liquid_mark == false)
      liquid_mark = true
      out_result["ask"]["price"] = format("%.8f",row[0].to_f)
      out_result["ask"]["volume"] = format("%.8f",total_volume)
      out_result["ask"]["avg_price"] = format("%.8f",(total_price / total_volume))  
      out_result["ask"]["offer_count"] = offer_count 
    end
    
  }

  out_result["ask"]["total_volume"] = format("%.8f",total_volume)
  out_result["ask"]["total_avg_price"] = format("%.8f",(total_price / total_volume))
  out_result["ask"]["total_offers"] = offer_count

  #total_average_ask_price = total_price / total_ask_volume / ask_count 

  offer_count = 0
  liquid_mark = false
  total_volume = 0
  total_price = 0

  result["bids"].each{ |row|
    #puts "price: #{row[0]}"
    #puts "volume: #{row[1]}"
    total_volume = total_volume + row[1].to_f
    #puts "total vol: #{total_ask_volume}"
    total_price = total_price + (row[0].to_f * row[1].to_f)
    offer_count = offer_count + 1
    if (total_volume > min_liquid_shares && liquid_mark == false)
      liquid_mark = true
      out_result["bid"]["price"] = format("%.8f",row[0].to_f)
      out_result["bid"]["volume"] = format("%.8f",total_volume)
      out_result["bid"]["avg_price"] = format("%.8f",(total_price / total_volume))  
      out_result["bid"]["offer_count"] = offer_count 
    end
    
  }

  out_result["bid"]["total_volume"] = format("%.8f",total_volume)
  out_result["bid"]["total_avg_price"] = format("%.8f",(total_price / total_volume))
  out_result["bid"]["total_offers"] = offer_count
  #puts "out_result: #{out_result}"
  return out_result
end 

def get_poloniex_exchange_liquid(currency_code,base_code,min_liquid_shares)
  #this will return the price of a poloniex exchange traded asset pair that
  # would be requied to bid or ask if you were to purchase or sell min_liquid_shares of that asset.
  # see: convert_polo_to_liquid(data_hash_in, min_liquid_shares) for details
  result = get_poloniex_exchangerate(currency_code,base_code)
  return convert_polo_to_liquid(result)

end 

def get_stellar_exchange_liquid(params,min_liquid_shares)
  # see: Utils.get_order_book_horizon(params) for details on params input
  # see: convert_polo_to_liquid(data_hash_in, min_liquid_shares) for details for output and min_liquid_shares input
  result = Utils.get_order_book_horizon(params)
  #puts "result: #{result}"
  result2 = orderbook_convert_str_to_polo(result)
  #puts "result2: #{result2}"
  result3 = convert_polo_to_liquid(result2,min_liquid_shares)
  #puts "result3: #{result3}"
  return result3
end

def delete_all_offers(account)
  result = Utils.get_account_offers_horizon(account)
  puts "results: #{result["_embedded"]["records"][0]["id"]}"
  result["_embedded"]["records"].each{ |row|
    puts "id: #{row["id"]}"
    puts "selling"
    puts "asset_issuer: #{row["selling"]["asset_issuer"]}"
    puts "asset_code: #{row["selling"]["asset_code"]}"
    puts "buying"
    puts "asset_issuer: #{row["buying"]["asset_issuer"]}"
    puts "asset_code: #{row["buying"]["asset_code"]}"
    puts "amount: #{row["amount"].to_s}"
    puts "price: #{row["price"].to_s}"
    puts ""
    send_offer(account,row["selling"]["asset_issuer"],row["selling"]["asset_code"],row["buying"]["asset_issuer"], row["buying"]["asset_code"],"0",row["price"],row["id"])
  }

  #send_offer(sellers_account,sell_issuer,sell_currency, buy_issuer, buy_currency,amount,price)

end 

def delete_offers(account,asset_code = "")
  #if asset_code left blank or nil it will delete all open orders on this account
  result = Utils.get_account_offers_horizon(account)
  #puts "results: #{result["_embedded"]["records"][0]["id"]}"
  if (result["_embedded"]["records"][0].nil?)
    puts "no offers to delete, nothing done"
    return
  end
  result["_embedded"]["records"].each{ |row|
    puts "id: #{row["id"]}"
    puts "selling"
    puts "asset_issuer: #{row["selling"]["asset_issuer"]}"
    puts "asset_code: #{row["selling"]["asset_code"]}"
    puts "buying"
    puts "asset_issuer: #{row["buying"]["asset_issuer"]}"
    puts "asset_code: #{row["buying"]["asset_code"]}"
    puts "amount: #{row["amount"].to_s}"
    puts "price: #{row["price"].to_s}"
    puts ""
    if (asset_code == row["selling"]["asset_code"] || asset_code == row["buying"]["asset_code"] || asset_code == "")
      send_offer(account,row["selling"]["asset_issuer"],row["selling"]["asset_code"],row["buying"]["asset_issuer"], row["buying"]["asset_code"],"0",row["price"],row["id"])
    end
  }
end

def orderbook_convert_str_to_polo(str_data_in)
  # this converts stellar.org horizon formated orderbook output from data we get from Utils.get_order_book_horizon(params)
  # into our standard format based on poloniex.com API format. the original format of the Utils.get_order_book_horizon(params)
  # is still also present in the returned output (optional) in the sub of the hash object at data["str_format"]...
  # that has some other data not present in polo format that might have some use someday
  
  data_out = {}
  data_out["asks"] = []
  data_out["bids"] = []
  #data_out["str_format"] = str_data_in
  data_out["base"] = str_data_in["base"]
  data_out["counter"] = str_data_in["counter"]

  count = 0
  str_data_in["bids"].each{ |row|
    puts "price: #{row["price"]}"
    puts "amount: #{row["amount"]}"
    data_out["bids"][count] = []
    data_out["bids"][count][0] = row["price"]
    data_out["bids"][count][1] = row["amount"]
    count = count + 1
  }

  count = 0
  str_data_in["asks"].each{ |row|
    puts "price: #{row["price"]}"
    puts "amount: #{row["amount"]}"
    data_out["asks"][count] = []
    data_out["asks"][count][0] = row["price"]
    data_out["asks"][count][1] = row["amount"]
    count = count + 1
  }

  return data_out
   
 # example output  str format: from Utils.get_order_book_horizon(params)
   #{"bids"=>[{"price_r"=>{"n"=>1221665604, "d"=>35638429}, "price"=>"34.2794460", "amount"=>"100.0000000"}, {"price_r"=>{"n"=>1666630867, "d"=>48788952}, "price"=>"34.1600055", "amount"=>"100.0000000"}], "asks"=>[{"price_r"=>{"n"=>1551345046, "d"=>43650591}, "price"=>"35.5400697", "amount"=>"2.9274000"}, {"price_r"=>{"n"=>5100, "d"=>143}, "price"=>"35.6643357", "amount"=>"2.9172000"}], "base"=>{"asset_type"=>"credit_alphanum4", "asset_code"=>"USD", "asset_issuer"=>"GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF"}, "counter"=>{"asset_type"=>"credit_alphanum4", "asset_code"=>"THB", "asset_issuer"=>"GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF"}}

  # example out from polo that the input above becomes with a few additions:
  ##  data as seen from: https://poloniex.com/public?command=returnOrderBook&currencyPair=BTC_STR
#"asks":[["0.00000350",279686.42305454],["0.00000351",89018.26064602],["0.00000352",514346.31778051],["0.00000353",132533.55189335],["0.00000354",122766.37862908],["0.00000355",320471.11853559],["0.00000356",20000],["0.00000357",21198.2],["0.00000358",20000],["0.00000359",110000],["0.00000360",21156.00378728],["0.00000361",147639.69514127],["0.00000362",325719.00666655],["0.00000363",407287.46594513],["0.00000364",387443.86603574],["0.00000365",503595.53528734],["0.00000366",34675.82356483],["0.00000367",489740.86461743],["0.00000368",2792185.4781983],["0.00000369",125635.42444457],["0.00000370",12169.01944962],["0.00000371",106565.2654594],["0.00000372",25731.90331445],["0.00000373",100416.701145],["0.00000374",100433.98972434],["0.00000375",34501.7646708],["0.00000376",199535.58534803],["0.00000377",264268],["0.00000378",105228.95529689],["0.00000379",346858.2408121],["0.00000380",1167539.8296809],["0.00000381",7094.18218139],["0.00000382",2750.68870523],["0.00000383",1183.73976116],["0.00000386",500],["0.00000387",299733.17164878],["0.00000388",499250.5],["0.00000389",21039.69400478],["0.00000390",457047.50064103],["0.00000391",2637.74428087],["0.00000392",181.1892992],["0.00000393",1500],["0.00000394",305174.8239911],["0.00000395",184333.63198436],["0.00000396",596639.04],["0.00000397",5925.38094307],["0.00000398",90398.85896785],["0.00000400",435847.55605688],["0.00000401",57680.21761456],["0.00000406",26083.49772116]],"bids":[["0.00000344",1165.64244186],["0.00000343",174542.14303209],["0.00000342",300438.98276001],["0.00000341",395092.23294599],["0.00000340",1545465.4025835],["0.00000339",25318.58407079],["0.00000338",616745.56508876],["0.00000337",28745.99680754],["0.00000336",239219.29600937],["0.00000335",186349.87489555],["0.00000334",1073137.0640403],["0.00000333",2193310.8301359],["0.00000332",126321.09274824],["0.00000331",30642.68137558],["0.00000330",756751.18370449],["0.00000329",212748.01443768],["0.00000328",146800.13167322],["0.00000327",162853.98236137],["0.00000326",36893.46385377],["0.00000325",1856135.7257234],["0.00000324",30500],["0.00000323",637915.5601449],["0.00000322",130769.04517739],["0.00000321",645232.18679988],["0.00000320",1634293.9478452],["0.00000319",31529.56751848],["0.00000318",138555.00884435],["0.00000317",1113464.2878347],["0.00000316",276013.49999998],["0.00000315",788968.27148898],["0.00000314",25000],["0.00000313",280488.00958466],["0.00000312",105329.92403145],["0.00000311",334358.45764935],["0.00000310",1421179.8297221],["0.00000309",1022950.5706013],["0.00000308",95061.81560324],["0.00000307",34886.66579372],["0.00000306",25000],["0.00000305",144907.76393442],["0.00000304",25000],["0.00000303",91402.71245924],["0.00000302",25000],["0.00000301",485000],["0.00000300",1130997.9931911],["0.00000299",48.16053511],["0.00000298",6000],["0.00000297",14526.7003367],["0.00000295",23963.23050847],["0.00000294",1820.1691914]],"isFrozen":"0","seq":6482153}
  
end

def read_ticker()
  # read_ticker(params)
  # all values are in params for example params["timestamp_start"]
  #if timestamp_end = 0 or default undefined that is also seen as start of now() to the end of time or max number or record pulls in the past
  #if timestamp_start = 0 or default undefined that is seen as start of Now() start time is present
  # if timestamp_end is less than 365 then the value is looked at as days back from timestamp_start - 24 hours/day
  # you can specify a start and stop range of timestamps on each that is in standard int seconds since Jan 01 1970. (UTC) if timestamp_end > 365
  # if asset_code is left blank default, we will return all asset_codes that have been recorded on the server
  # if you enter an asset_code with base_asset_code left blank, it will return all ask, bids on all matches of asset_code
  # with all other base_asset_code pairs found and returned.
  # if both asset_code and base_asset_code are entered, of course they must both match to be returned in query
  # in the return data the asset_code = counter_asset_code and base_asset_code = base_asset_code, sorry that's just how it ended up
  # I might consider rename of counter_asset_code to just asset_code in return at some point but not today
  params = {}
  timestamp_end = params["timestamp_end"]
  timestamp_start = params["timestamp_start"]
  asset_code = params["asset_code"]
  asset_code_issuer = params["asset_issuer"]
  base_asset_code = params["base_asset_code"]
  base_asset_issuer = params["base_asset_issuer"]

  #timestamp_end=0,timestamp_start=0,asset_code="THB", base_asset_code=""

  begin
    if timestamp_start == 0
      timestamp_start = Time.now.to_i
    end

    if timestamp_end < 365
      if timestamp_end > 0
         timestamp_end = timestamp_start - (timestamp_end * 24 * 60 * 60)
      end
    end

    puts "timestamp_start: #{timestamp_start}"
    puts "timestamp_end:  #{timestamp_end}"
  
    con = Mysql.new(Utils.configs["mysql_host"], Utils.configs["mysql_user"],Utils.configs["mysql_password"], Utils.configs["mysql_db"])
 
    if timestamp_end == 0
      rs = con.query("SELECT * FROM ticker")
    else
      if (asset_code.length > 0 && base_asset_code.length > 0)
        query_string = "SELECT * FROM ticker WHERE `counter_asset_code` = '" + asset_code + "' AND `base_asset_code` = '" + base_asset_code + "' AND  `timestamp` BETWEEN FROM_UNIXTIME(" + timestamp_end.to_s + ") AND FROM_UNIXTIME(" + timestamp_start.to_s + ")"
      elsif (asset_code.length > 0)
        query_string = "SELECT * FROM ticker WHERE `counter_asset_code` = '" + asset_code + "' AND `timestamp` BETWEEN FROM_UNIXTIME(" + timestamp_end.to_s + ") AND FROM_UNIXTIME(" + timestamp_start.to_s + ")"
      else
        query_string = "SELECT * FROM ticker WHERE `timestamp` BETWEEN FROM_UNIXTIME(" + timestamp_end.to_s + ") AND FROM_UNIXTIME(" + timestamp_start.to_s + ")"
      end
      puts "query_string: #{query_string}" 
      rs = con.query(query_string)
    end

    n_rows = rs.num_rows    
    puts "There are #{n_rows} rows in the result set"

    array = []
    n_rows.times do
        #puts rs.fetch_row.join("\s")
        #puts "fetch_row: #{rs.fetch_hash}"
        row["timestamp"] = row["timestamp"].to_time.to_i.to_s
        puts "row[timestamp]: #{row["timestamp"].to_time.to_i}"
        array.push(row)
        #array.push(rs.fetch_hash)
    end

    puts "array: #{array}"
 
  rescue Mysql::Error => e
    puts e.errno
    puts e.error
    
  ensure
    con.close if con
  end

end


def record_ticker(data)
  # record_ticker(data)
  # This will be writen to allow modifications to the data hash contents without need to modify the mysql sql part of this code.
  # it will parse the values in the data hash and create the needed sql create insert into the mysql database
  # it will only iterate one level into the data hash at this time with added pre data to add Time.now and timestamp each entry
  # data hash seen for the first time will insert fields and will modify the mysql table on the fly if later data format changes
  # also note if the contents of the first level hash are not a hash in a hash it will be ignored and not added to the table at this time
  #
  # this will take a data_hash formated output from our convert_polo_to_liquid(data_hash_in)
  # that can get feeds from several different sources
  # that come in looking like this if from polo:
  # {"ask"=>{"price"=>"0.00000383", "volume"=>"578679.19417415", "avg_price"=>"0.00000383", "offer_count"=>3, "total_volume"=>"10683552.18423253", "total_avg_price"=>"0.00000408", "total_offers"=>50}, "bid"=>{"price"=>"0.00000372", "volume"=>"333182.73763676", "avg_price"=>"0.00000372", "offer_count"=>2, "total_volume"=>"18066738.30346057", "total_avg_price"=>"0.00000341", "total_offers"=>50}}
  #   to be compatible with the stallar.org feed you would have to manually add base and counter to this feeds data object
  #
  # or this if from stellar exchange (note added asset_code and asset_issuer info if from this source):
  # {"ask"=>{"price"=>"35.66433570", "volume"=>"5.84460000", "avg_price"=>"35.60209427", "offer_count"=>2, "total_volume"=>"5.84460000", "total_avg_price"=>"35.60209427", "total_offers"=>2}, "bid"=>{"price"=>"34.27944600", "volume"=>"100.00000000", "avg_price"=>"34.27944600", "offer_count"=>1, "total_volume"=>"200.00000000", "total_avg_price"=>"34.21972575", "total_offers"=>2}, "base"=>{"asset_type"=>"credit_alphanum4", "asset_code"=>"USD", "asset_issuer"=>"GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF"}, "counter"=>{"asset_type"=>"credit_alphanum4", "asset_code"=>"THB", "asset_issuer"=>"GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF"}}

  # this data will will then be writen to a mysql database that will later be used in stellar.org custom api data feeds.
  #data = {"ask"=>{"price"=>"35.66433570", "volume"=>"0.0", "avg_price"=>"35.60209427", "offer_count"=>2, "total_volume"=>0, "total_avg_price"=>"35.60209427", "total_offers"=>2}, "bid"=>{"price"=>"34.27944600", "volume"=>"100.00000000", "avg_price"=>"34.27944600", "offer_count"=>1, "total_volume"=>"200.00000000", "total_avg_price"=>"34.21972575", "total_offers"=>2}, "base"=>{"asset_type"=>"credit_alphanum4", "asset_code"=>"USD", "asset_issuer"=>"GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF"}, "counter"=>{"asset_type"=>"credit_alphanum4", "asset_code"=>"THB", "asset_issuer"=>"GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF"}, "array"=>[1,2,3,4]}

  puts "data: #{data.keys}"
 
  begin
    con = Mysql.new(Utils.configs["mysql_host"], Utils.configs["mysql_user"],Utils.configs["mysql_password"], Utils.configs["mysql_db"])
    field_string = 'datetime'
    value_string = "'" + Time.now.to_s + "'"   
    prep_value = '?'
    #prep_value = '?,?,?...'
    start_sql = 'insert into ticker ('
    mid_sql = ') values ('
    end_sql = ')' 
    create_table_string = "CREATE TABLE IF NOT EXISTS `ticker` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `datetime` text NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)"
    data.each do |key, array|
      puts "key: #{key}"
      puts "array: #{array}"
      puts " respond_to?(:each)  #{data[key].respond_to?(:each)}"
      puts " respond_to?(:keys):  #{data[key].respond_to?(:keys)}"
      if data[key].respond_to?(:keys)
        data[key].each do |key2, array2|
          puts "sub key: #{key2}"
          puts "sub array: #{array2}"
          puts " planed mysql field name: #{key + "_"+key2}"
          puts " planed mysql field value: #{data[key][key2]}"
          field_string = field_string + "," + key + "_" + key2 
          value_string = value_string + "," +data[key][key2].to_s
          prep_value = prep_value + ",?"
          if (true if Float(data[key][key2]) rescue false)         
            puts "type double"
            type = "double NOT NULL"
          else
            puts "type text"
            type = "text NOT NULL"
          end
          create_table_string = create_table_string + ",`" + key + "_" + key2 + "` " + type
        end
      end    
    end
    create_table_string = create_table_string + ")"
    puts "field_string: #{field_string}"
    puts "value_string: #{value_string}"
    puts "prep_value: #{prep_value}"
    puts "create_table_string:  #{create_table_string}"
   
    sql = start_sql + field_string + mid_sql + prep_value + end_sql
    puts " sql: #{sql}"
    con.query(create_table_string)
    pst = con.prepare(sql)
    array_execute = value_string.split(',')
    pst.execute(*array_execute)
       
  rescue Mysql::Error => e
    puts e.errno
    puts e.error
    
  ensure
    con.close if con
    pst.close if pst
  end

end

def test_record(params)
  #params["sell_asset"] = "USD"
  #params["sell_issuer"] = "GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF"
  #params["buy_asset_type"] = "native"
  #params["buy_asset"] = "THB"
  #params["buy_issuer"] = "GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF"
  #params["min_liquid"] = 0
  result = Utils.get_order_book_horizon(params)
  puts "result: #{result}"
  result2 = orderbook_convert_str_to_polo(result)
  puts "result2: #{result2}"
  result3 = convert_polo_to_liquid(result2,params["min_liquid"])
  puts "result3: #{result3}"
  record_ticker(result3)
end


#https://poloniex.com/public?command=returnOrderBook&currencyPair=BTC_STR
#trader_account public addressId = GBROAGZJGZSSQWJIIH2OHOPQUI4ZDZL4MOH7CSWLQBDGWBYDCDQT7CU4

currency_code = sell_currency
base_code = buy_currency
params = {}
params["min_liquid"] = 0

puts "started infinite loop on auto trader, hit ctl-c to exit"
puts "trader_account: #{trader_account.address}"
puts "currency_code: #{currency_code}"
puts "base_code: #{base_code}"
puts "sell_currency: #{sell_currency}"
puts "buy_currency: #{buy_currency}"
puts "sell_issuer: #{sell_issuer}"
puts "buy_issuer:  #{buy_issuer}}"
puts "profit_margin: #{profit_margin}"
puts "amount: #{amount}"
puts "min_liquid: #{params["min_liquid"]}"

while true  do
  #infinite loop to run auto trader, ctl-c to exit

  #if asset_code left blank or nil it will delete all open orders on this account
  puts "deleting offers"
  begin
    delete_offers(trader_account, sell_currency)
    #delete_offers(trader_account,asset_code = "")
  rescue
    puts "delet_offers failed,  will attempt to delete the last orders on the next round"
  end
  
  sleep 10

  # trade both sides buy and sell above and bellow by margin %
  puts "setting up trade set"
  begin
    auto_trade_offer_set(trader_account, sell_issuer, sell_currency, buy_issuer, buy_currency, amount, profit_margin, openexchangerates_key)
    #auto_trade_offer(trader_account, sell_issuer, sell_currency, buy_issuer, buy_currency, amount, profit_margin, openexchangerates_key)
  rescue
    puts "auto_trade_offer_set errored out, maybe internet connection problem, we will try again later"
  end
  sleep 10

  
  params["sell_asset"] =  sell_currency
  params["sell_issuer"] = sell_issuer
  params["buy_asset"] =  buy_currency
  params["buy_issuer"] = buy_issuer
  puts "params A: #{params}"
  puts "record data"
  begin
    #test_record(params)
  rescue
    puts " test_record not sure why, check mysql user and passwords"
  end

  params["sell_asset"] =  buy_currency
  params["sell_issuer"] =  buy_issuer
  params["buy_asset"] = sell_currency
  params["buy_issuer"] = sell_issuer
  puts "params B: #{params}"
  begin
    test_record(params)
  rescue
    puts "test record failed"
  end
  sleep 3600
end



# ***************************************************************************
# every thing bellow was tested

#result = get_poloniex_exchangerate("STR","BTC")
#puts "result: #{result}"
#puts "low: #{result["asks"][0]}"

#get_poloniex_exchange_liquid(currency_code,base_code,min_liquid_shares)
# 300000 shares of STR (XLM) is worth about $500 so that is what we consider a minimal liquidity block
#results = get_poloniex_exchange_liquid("STR","BTC",300000)
#puts "ask: #{results["ask"]["price"]}"
#puts "bid: #{results["bid"]["price"]}"
#puts "all: #{results}"



#delete_all_offers(trader_account)

#delete_offers(account,asset_code)
#delete_offers(trader_account, "USD")

#record_ticker()
#read_ticker()
#exit 

#result = Utils.get_account_offers_horizon(trader_account)
#puts "results: #{result["_embedded"]["records"][0]["id"]}"
#puts "results: #{result["_embedded"]["records"][0].nil?}"

#get_order_book_horizon(params)
#    buy_asset_type = params["buy_asset_type"]
#    buy_asset = params["buy_asset"]
#    buy_issuer = params["buy_issuer"]
#    sell_asset_type = params["sell_asset_type"]
#    sell_asset = params["sell_asset"]
#    sell_issuer = params["sell_issuer"]

#params = {}
# sell_asset_type is optional as input as the function auto detects asset type needed
# depending on asset_code XLM (native), 4 letter credit_alphanum4 asset name or 12 leter credit_alphanum12 needed
# there is always the rare posibility that someone uses 4 letters and selects credit_aphanum12 so we will keep it for that posibility
#params["sell_asset_type"] = "credit_alphanum12"
#params["sell_asset"] = "USD"
#params["sell_issuer"] = "GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF"
#params["buy_asset_type"] = "native"
#params["buy_asset"] = "THB"
#params["buy_issuer"] = "GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF"
#result = Utils.get_order_book_horizon(params)
#puts "result: #{result}"
#result2 = orderbook_convert_str_to_polo(result)
#puts "result2: #{result2}"
#result3 = convert_polo_to_liquid(result2,4)
#puts "result3: #{result3}"
#exit
#******************************************************************************************** end of tests

#result = get_openexchangerates(currency_code,base_code, openexchangerates_key)
#result = get_exchangerate(currency_code, base_code, openexchangerates_key)

#puts "rate: " + result["rate"]
#puts "rate BTC to USD: " + result["rates"]["BTC"].to_s
#puts "timestamp: " + result["timestamp"].to_s
#puts "datetime: " + result["datetime"]
#puts "base: " + result["base"]

#puts ""

# example output
#rate: 2.935490234019467
#rate BTC: 0.001644233025
#timestamp: 1473901214
#datetime: 2016-09-15T08:00:14+07:00
#base: JPY



#result = get_yahoo_finance_exchangerate(currency_code,base_code)
#puts "Rate: " + result["query"]["results"]["rate"][0]["Rate"]
#puts "Rate: " + result["query"]["results"]["rate"][1]["Rate"]

#puts "rate: " + result["rate"]
#puts "rate BTC to USD: " + result["rates"]["BTC"].to_s
#puts "timestamp: " + result["timestamp"].to_s
#puts "datetime: " + result["datetime"]
#puts "base: " + result["base"]
#puts "ask: " + result["ask"]
#puts "bid: " + result["bid"]

#example outputs:
#rate: 34.8900
#datetime: 9/14/2016T11:02am
#base: THB



