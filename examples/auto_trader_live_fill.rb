#!/usr/bin/ruby
#(c) 2016 Sep 14. by sacarlson  sacarlson_2000@yahoo.com aka Scott Carlson aka scotty.surething...
# This will be the prototype of an auto trader that will pull prices of currency off the yahoo API and/or openexchangerates.org
# and with this data will setup a single or pair of trades on the stellar.org network
#
#  main functions
# example: auto_trade_offer(trader_account, sell_issuer, sell_currency, buy_issuer, buy_currency, amount, profit_margin, key)
#          auto_trade_offer_set(trader_account, sell_issuer, sell_currency, buy_issuer, buy_currency, amount, profit_margin, key)
#
#   The auto_trade_offer_set version is what we mostly use now as it sets up trade of sells and buys above and bellow the feed price by our profit margin
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
# to start app: bundler exec ruby ./auto_trader_live_fill.rb
#


require '../lib/stellar_utility/stellar_utility.rb'
require "mysql"

Utils = Stellar_utility::Utils.new("./livenet_bot_trade_fill.cfg")



  params = {}
  
  #trade_pairs is a pair of assets to auto trade with 3 values it's trade asset 1 trade asset 2 and third item is how much to setup trades for in the first items value
  #params["trade_pairs"] = [["THB","USD",340],["XLM","USD",1000],["XLM","BTC",2000],["BTC","USD",0.001]]
  #params["trade_pairs"] = [["THB","USD",6000],["XLM","USD",2000],["INR","USD",2000]]
  params["trade_pairs"] = [["USD","XLM",0.01],["USD","THB",0.01],["USD","INR",0.01]]
  #params["trade_peg_pairs"] = [["FUNT","THB",40,"THB",10],["FUNT","THB",40,"XLM",10],["mBTC","BTC",0.001,"USD",10]]
  #params["trade_peg_pairs"] = [["mBTC","BTC",0.001,"XLM",5],["FUNT","THB",40,"THB",500],["FUNT","THB",40,"XLM",1000],["BTC","BTC",1,"BTC",0.0001,"GBUYUAI75XXWDZEKLY66CFYKQPET5JR4EENXZBUZ3YXZ7DS56Z4OKOFU","GATEMHCCKCY67ZUCKTROYN24ZYT5GK4EQZ65JJLDHKHRUZI3EUEKMTCH"]]
  #params["trade_peg_pairs"] = [["mBTC","BTC",0.001,"XLM",5],["FUNT","THB",40,"XLM",1000],["BTC","BTC",1,"BTC",0.0001,"GBUYUAI75XXWDZEKLY66CFYKQPET5JR4EENXZBUZ3YXZ7DS56Z4OKOFU","GATEMHCCKCY67ZUCKTROYN24ZYT5GK4EQZ65JJLDHKHRUZI3EUEKMTCH"]]
  #params["trade_peg_pairs"] = [["mBTC","BTC",0.001,"XLM",5],["FUNT","THB",40,"XLM",500],["BEER","THB",40,"XLM",0.01,"GDW3CNKSP5AOTDQ2YCKNGC6L65CE4JDX3JS5BV427OB54HCF2J4PUEVG"]]
  params["trade_peg_pairs"] = [["FUNT","THB",40,"XLM",0.01]]
  #params["trade_peg_pairs"] = [["FUNT","THB",40,"THB",10],["FUNT","THB",40,"XLM",10]]
  #params["order_book_pairs"] = [["USD","THB"],["BTC","USD"],["USD","XLM"],["FUNT","XLM"],["FUNT","THB"],["mBTC","USD"]]
  params["order_book_pairs"] = []

  # trade_count is the number of fill trades we put on each asset pair on each side buy and sell
  # this now expanded to new model that has different trade_count for each asset pair
  #params["trade_count"] = 5
  params["trade_count"] = {}
  params["trade_count"]["USD_XLM"] = 4
  params["trade_count"]["FUNT_XLM"] = 4
  params["trade_count"]["USD_THB"] = 1
  params["trade_count"]["USD_INR"] = 1
  # trade_increment is the distance price between each of the fill trades
  #if this not defined nil then we use profit margin as increment value
  # at present this is my prefered method, I stoped development on original profit_margin steps in price
  # I feel it's more important as a sycalogical perspective to see movements in price in a human readable form of steps when looking at historic data
  params["trade_increment"] = {}
  params["trade_increment"]["USD_XLM"] = 0.1 
  params["trade_increment"]["FUNT_XLM"] = 0.1 
  params["trade_increment"]["USD_THB"] = 0.1 
  params["trade_increment"]["USD_INR"] = 0.1 
  #example with trade_count 2 and trade_increment  0.1 and FUNT_XLM center price of 10 we would have order prices of 9.9, 9.8 on buys and  10.1, 10.2 on sells
  
  #trade_decimal_round will round all trades to precision past the decimal point example 2 would return for 1.12345 as trade would become 1.12
  # we now added individual setting for each asset pair, if not set will pass original trade value will all digits
  params["trade_decimal_round"] = {}
  params["trade_decimal_round"]["USD_XLM"] = 2
  params["trade_decimal_round"]["FUNT_XLM"] = 2
  params["trade_decimal_round"]["USD_THB"] = 2 
  params["trade_decimal_round"]["USD_INR"] = 2 

  # new optional amount calculation based on parabola formula  as seen in xls spreadsheet simulation with this quadratic equation
  # amount_sell = (((sell_price-market_ask_price)**2)*params["scale_parabola"][asset_pair].to_f)+ amount.to_f
  # if no scale_parabola exists for asset pair then original amount that is set in params above is used in all this groups trades
 
   params["scale_parabola"] = {}
   params["scale_parabola"]["FUNT_XLM"] = 0.9
   params["scale_parabola"]["USD_XLM"] = 0.9

  params["trade_increment_mult"] = 1
  # if trade_increment = 0 then we use trade_increment_mult instead
  # for trade_increment_mult we will use it as a multiple of the profit margin setting for each progresive trade above and bellow last trade price record   
  # this method is no longer supported in development see trade_increment instead, we might come back to this at some point if we see a need

  #trade_spread_offset is the percentage from center market price to start filling orders
  # this adds some space from center price to begin putting in the fill orders
  # if we use trade_increment we can just set profit_margin to perform this same function, but if if trade_increment for the asset pair is zero then this can take it's place
  # as noted above this is no longer supported
  params["trade_spread_offset"] = 0

  #GA4MTVSH2TRB4XBWPLY5ET6SXEQPFXHD6CKX55AFF3Y4FJYGQEUVKY7K
  params["trader_account"] = Stellar::KeyPair.from_seed(Utils.configs["trader_account"])
  # temp test account GA4MTVSH2TRB4XBWPLY5ET6SXEQPFXHD6CKX55AFF3Y4FJYGQEUVKY7K (now funded with 100XLM. 10 USD, 10FUNT, 300 THB, ?? INR)
  #params["trader_account"] = Stellar::KeyPair.from_seed("SBK...")

  #GBURK32BMC7XORYES62HDKY7VTA5MO7JYBDH7KTML4EPN4BV2MIRQOVR
  #params["trader_account_sell"] = Stellar::KeyPair.from_seed(Utils.configs["trader_account_sell"])
  #GBURK32BMC7XORYES62HDKY7VTA5MO7JYBDH7KTML4EPN4BV2MIRQOVR
  #params["trader_account_buy"] = Stellar::KeyPair.from_seed(Utils.configs["trader_account_buy"])
  params["sell_issuer"] = "GBUYUAI75XXWDZEKLY66CFYKQPET5JR4EENXZBUZ3YXZ7DS56Z4OKOFU"
  params["buy_issuer"] = params["sell_issuer"]

  params["buy_currency"] = "XLM"
  params["peg_base_asset"] = "THB"
  params["peg_multiple"] = 40
  params["amount"] = 10
  #params["profit_margin"] = 0.5
  params["profit_margin"] = {}
  params["profit_margin"]["default"] = 0.5
  #params["profit_margin"]["XLM_USD"] = 2.5
  params["profit_margin"]["XLM_USD"] = 0.1
  #params["profit_margin"]["FUNT_XLM"] = 2.5
  params["profit_margin"]["FUNT_XLM"] = 0.1
  params["profit_margin"]["BEER_XLM"] = 4.0
  params["profit_margin"]["BTC_USD"] = 5.0
  params["profit_margin"]["mBTC_USD"] = 5.0
  params["profit_margin"]["mBTC_XLM"] = 5.0
  params["profit_margin"]["BTC_THB"] = 5.0
  params["profit_margin"]["BTC_ETH"] = 1.0
  params["profit_margin"]["INR_USD"] = 0.05
  params["profit_margin"]["THB_USD"] = 0.05
  params["profit_margin"]["USD_THB"] = 0.05
  params["profit_margin"]["USD_INR"] = 0.05
  params["profit_margin"]["USD_XLM"] = 0.1
  params["exchange_feed_key"] = Utils.configs["openexchangerates_key"]  
  params["min_liquid"] = 0
  params["loop_time_sec"] = 60
  # loop time now in minutes (why was it 6 min?) also cut loop time to 30 min instead of 60 min to try faster tradeing loop
  params["loop_count_threshold"] = 30
  params["reset_loop_count_threshold"] = false
  #params["loop_time_sec"] = 12
  params["feed_poloniex"] = ["BTC","XLM","USDT","USD","ETH","XRP"]
  params["feed_other"] = ["THB","USD","NGN","XOF","INR"]
  params["tx_mode"] = true

  # for fill orders I don't think we need ticker any more.  I'm looking at removing it from all this bot trading as we no longer need to track prices here anymore
  # we have good trade tracking on the stellar.org network apps now so price tracking here will be removed entirely here soon
  params["disable_trade"] = false
  params["disable_record_ticker"] = true
  params["disable_record_feed"] = false
  params["disable_delete_offers"] = true

  params["disable_trade_peg"] = false
  #i'm not sure I will keep dual_trader in the future.  this allowed to buy and sell with two different accounts.  at present I just use one account for both
  # I guess the cool think is you can go bankrupt selling or buying but still trade on the other side.  with a single trader if one side goes broke both sides stop trading
  # as it only requires one failure in a group of opperations in a transaction for them all to fail
  params["dual_trader"] = false
  params["trade_on_sell_side"] = true
  params["trade_on_buy_side"] = true
  params["min_diff_trade_pct"] = 0.10
  #params["min_diff_trade_pct"] = 0.0
  params["min_diff_margin_mult_trade"] = 0.1
  #params["min_diff_margin_mult_trade"] = 0.0
  #params["mss_server_url"] = "http://www.funtracker.site:9495"
  params["mss_server_url"] = "http://b.funtracker.site:9495"

  puts "trade account: #{params["trader_account"].address}"

# max_diff is the max difference bettween two currency api feeds that are compared to verify that data is acurate within reason
# presently compares yahoo and openexchange 
$max_diff = 0.008

#params["loop_count_threshold"] is the number of time loops before trading takes place, this set at 10 means that loop_time_sec * 10 will
# be required before trading takes place.  This allows changes in the bot_config.yml file to influence changes within a smaller window of time. 

#params["reset_loop_count_threshold"] when set to true will restart the loop_count_threshold to zero and force trades to take place ahead
# of time, after the reset_loop event the value of this param will be again force set to false in the config file to prevent the next loop reset. 

#trade_pairs and the amount to trade this pair, this array controls what order sets the bot will setup in a group of orders on each loop
# first currency code is sell_currency also known as the base currency code, second is the currency to buy or counter asset or currency
#[base_code,currency_code,amount]
# params["trade_pairs"] = [["USD","THB",100],["BTC","XLM",1]]
# added options now added in array for changing  params["sell_issuer"] and params["buy_issuer"]:  [sell_asset,buy_asset,amount,sell_issuer,buy_issuer]
# [sell_currency,buy_currency,amount,sell_issuer,buy_issuer]
# example: ["ETH","BTC",0.1,"GDIR44J6EE3SVP4OAOAF7FAJGBXIHELRKHGC3RFAYXDE4I73S6ZNNW2F","GBUYUAI75XXWDZEKLY66CFYKQPET5JR4EENXZBUZ3YXZ7DS56Z4OKOFU"]

#order_book_pairs is an asset pair array that is a list of what is recorded in the local mysql database of what is seen on 
# the orderbook of stellar for these assets at the time. [base_asset,currency]. it records both buy and sell side
# with this data in mysql we also have a feed and methods to plot history on a webpage
# with this list now separate we can now capture and plot pairs that we are not the market maker for.
# we will also later add optional issuer address for each["USD","THB","GBDDUSD...","GBDDTHB..."] as we might for the others as well
# with no issuer values seen it will default both to the params["sell_issuer"] value as it does now
#params["order_book_pairs"] = [["USD","THB"],["BTC","XLM"]]
# added options now added in array for changing  params["sell_issuer"] and params["buy_issuer"]: [sell_asset,buy_asset,sell_issuer,buy_issuer]

# trade_peg_pairs
# [peged_asset,asset_peg,peg_multiple,counter_asset,sell_ammount]
# so in this example: ["FUNT","THB",40,"XLM",10]  we want to sell FUNT peged at the value each of 40 THB,
# so we want to trade 10 FUNT for XLM at the price of 40 THB. it will setup a set of trades of buy and sell above and bellow that price +- margins 
#params["trade_peg_pairs"] = [["FUNT","THB",40,"THB",10],["FUNT","THB",40,"XLM",10],["mBTC","BTC",0.001,"USD",10]]
#added options now added in array for changing  params["sell_issuer"] and params["buy_issuer"]:
# [sell_asset,peg_asset,peg_asset_multiple,buy_asset,sell_amount,sell_issuer,buy_issuer]
#["BTC","BTC",1,BTC,0.01,
#$mss_server_url is the mss-server we use to get stellar ticker data from at this time
$mss_server_url = params["mss_server_url"]

# all recorders and trading are now active
#disable setting up trade orders and canceling/deleting them on stellar.org network for test
#$disable_trade = true
$disable_trade = params["disable_trade"]

#disable recording data to mysql ticker table recorder db for test
#$disable_record = true
$disable_record = params["disable_record_ticker"]

#disable recording data feed to mysql feed table recorder db for test (records feed data from currency API data services)
#$disable_record_feed = true
$disable_record_feed = params["disable_record_feed"]

 # reference docs
#trader_account_sell = trader_account
#trader_account_buy = trader_account


# only setup single orders on each pair with ask order on sell_currency value only, default false will setup ask and bid above and bellow feed rate. 
#params["trade_single_side_pair"] = false

# feed_other is an array of listed assets currency codes that can be read from this feed.  other_feed can come from multi sources 
# and are verified with a compare between at least two feeds on each read, in most cases this for fiat currency only
#params["feed_other"] = ["THB","USD"]

# we use the https://poloniex.com/ feed for all crypto currency feed data, this array is the reference as to what we consider crypto assets 
# that need to come from this feed.
#params["feed_polo"] = ["BTC","XLM"]

#infinite loop time in seconds with 3600 being 1 hour that is as often as we can get free feeds from openexchangerates.org and most others.
#loop_time_sec = 3600

#params["min_diff_trade_pct"] is the minimum percent difference bettween what was last recorded as traded on the stellar network 
# and what is now seen on the feed channel that are used to trade from. this is presently used in trade_offer_set(params)
# if set to zero this value is ignored
# this now absolete, we now use params["min_diff_margin_mult_trade"]

#params["min_diff_margin_mult_trade"]
# this replaced above to set allow trade depending on minimum difference between last traded price with what is now market price to this value
# multiplied by the margin setting on this currency pair trade.  see params["profit_margin"]["XLM_USD"] for example
# default value was 0.25 so the value seen from a feed must change by 0.25 * profit_magin by what is presently seen on the order book
# before a trade is done. set to zero we will trade on all

#  config settings
#buy_currency = "THB"
#buy_currency = "USD"

#sell_currency = "USD" #sell_currency is also the base_asset currency code
#sell_currency = "THB"

#public address of selling asset issuer
#sell_issuer = "GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF"

#amount to sell
#amount = 100

#pubic address of buying asset issuer
#buy_issuer = "GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF"

#profit margin in percent 
#profit_margin = 0.5

#currency_code = "THB"
#base_code = "USD"

#minimum liquid shares bid or ask if you were to purchase or sell a block of shares  min_liquid_shares of that asset
# used in convert_polo_to_liquid() function for polonix and stellar.org network book trade market data to ticker format 
#params["min_liquid"] = 0

#see https://currencylayer.com to get this key
#currencylayer_key = Utils.configs["currencylayer_key"]

#see https://openexchangerates.org to get this key
#openexchangerates_key = Utils.configs["openexchangerates_key"]

#trader_account public addressId = GBROAGZJGZSSQWJIIH2OHOPQUI4ZDZL4MOH7CSWLQBDGWBYDCDQT7CU4
#trader_account = Stellar::KeyPair.from_seed(Utils.configs["trader_account"])

#public addressId = GBIKT3CMSHZBQS7UAHU5YW6OXXPDSOWLNQMTF6Y7ALIWX7SLVIAV74NP
#trader_account_buy = Stellar::KeyPair.from_seed(Utils.configs["trader_account_buy"])


#$last_rate = 0

#puts "Utils version: #{Utils.version}"
#puts "configs: #{Utils.configs}"

File.open("./bot_config_fill.yml", "w") {|f| f.write(params.to_yaml) }
#params = YAML.load(File.open("./bot_config_fill.yml"))
puts "params: #{params}"


def percent_diff(x,y)
  #return percent difference between two numbers
  # number will always return positive or zero
  return (100*(y.to_f - x.to_f) / x.to_f).abs
end


def send_tx(b64)
  puts "send_tx"
  if true
    puts "#{b64}"
    return Utils.send_tx(b64)
  else
    puts "send_tx disabled"
    puts "b64"
    puts "#{b64}"
  end
end


def trade_offer_set(params)
  #this will setup trades on both above and bellow the present market ask price of the asset with the set profit_margin percent markup price
  # it will setup sell trade with profit_margin percent so sell_price = market_ask_price + (market_ask_price * (profit_margin/100))
  # with unchanged amount value that we will now call amount_sell = amount
  # it will setup buy trade with profit_margin percent so buy_price = market_ask_price - (market_ask_price * (profit_margin/100))
  # with value amount_buy = amount_sell * (1 / sell_price)
  # so this should setup about equal trade values on both above and bellow present market trade price
  # see auto_trade_offer function for details on auto trading

  #params["trader_account"]
  #params["sell_issuer"]
  #params["sell_currency"]
  #params["buy_issuer"]
  #params["buy_currency"]
  #params["amount"]
  #params["profit_margin"]
  #params["exchange_feed_key"]
  #params["feed_poloniex"]
  #params["feed_other"]
  #params["min_liquid"]
  #params["tx_array_in"]  ; an empty array or an array of other tx we will add to and return with added tx from this run
  #params["tx_mode"] = true  ; don't perform the transaction just return a set to tx in an array [tx1,tx2], default is false
    # this is so we can collect all the tx and then perform a single transaction on all of them (much faster)
  #params["market_ask_price"] if not nil? will use this value instead of values from get_any_exchangerate
    #begin
  puts "start trade_offer_set"
  trader_account = params["trader_account"]
  trade_increment_mult = params["trade_increment_mult"]
  trade_spread_offset = params["trade_spread_offset"]
  sell_issuer = params["sell_issuer"]
  sell_currency = params["sell_currency"]
  buy_issuer = params["buy_issuer"]
  buy_currency = params["buy_currency"]
  amount = params["amount"]
  #profit_margin = params["profit_margin"]
  key = params["exchange_feed_key"]

  base_code = sell_currency
  currency_code = buy_currency
  asset_pair = base_code + "_" + currency_code
  puts "asset_pair #{asset_pair}"
  if params["profit_margin"][asset_pair].nil?
    profit_margin = params["profit_margin"]["default"]
  else
    puts " non default profit_margin asset_pair detected, will have custom value: #{params["profit_margin"][asset_pair]}"
    profit_margin = params["profit_margin"][asset_pair]
  end
  if params["market_ask_price"].nil? 
    market_ask_price = get_any_exchangerate(currency_code, base_code, params)
  else
    puts " params[market_ask_price]  is not nil will use: #{params["market_ask_price"]}"
    market_ask_price = params["market_ask_price"]
  end
  #$last_rate = market_ask_price
  puts "market_ask_price: #{market_ask_price}"
  #params["min_dif_trade_pct"]
  if market_ask_price.to_f == 0
    puts "market_ask_price is zero so must have problem with feed or ??,  will not trade this"
    return
  end
  # this returns what the last ask price was set on stellar.org network 
  # this already had profit margin added so must remove profit margit to compare to present market_ask_price
  #last_rate = get_funtracker_exchangerate_min(currency_code,base_code).to_f
  #last_real_rate = last_rate - (last_rate * (profit_margin.to_f/100.0)) #no longer needed with mod in get_funt...
  #min_diff = params["min_diff_margin_mult_trade"].to_f * profit_margin.to_f
 
  puts "asset_pair: #{asset_pair}"
  puts "profit_margin: #{profit_margin}"
  #puts "last_rate: #{last_rate}"
  #puts "min_diff_margin_mult: #{params["min_diff_margin_mult_trade"]}"
  #puts "min_diff: #{min_diff}"
  #puts "percent_diff: #{percent_diff(last_rate,market_ask_price)}"

  #if min_diff > percent_diff(last_rate,market_ask_price).to_f && min_diff > 0 && last_rate.to_f > 0
  #  puts " min_diff > percient_diff so will skip trading this set on this loop"
  #  return
  #end
  params["traded"].push([currency_code,base_code])
  sell_price = sprintf('%.7f',(market_ask_price + (market_ask_price * (profit_margin.to_f/100.0))))
  buy_price = sprintf('%.7f',(1/market_ask_price) + ((1/market_ask_price) * (profit_margin.to_f/100.0)))
  amount_sell = sprintf('%.7f',amount.to_f)
  amount_buy = sprintf('%.7f',amount_sell.to_f * sell_price.to_f)
  
  
  puts "trader_account: #{trader_account.address}"
  puts "profit margin percent: #{profit_margin.to_f}"
  puts "profit margin dec: #{profit_margin.to_f/100.0}"
  puts ""
  puts "market_ask_price: #{sprintf('%.7f',market_ask_price.to_f)}"
  puts "margin difference: #{sprintf('%.7f',(market_ask_price.to_f * (profit_margin.to_f/100.0)))}"
  puts "sell_currency: #{sell_currency}"
  puts "sell_issuer: #{sell_issuer}"
  puts "sell_price.to_s: #{sell_price.to_s}"
  puts "sell_priceR: #{sprintf('%.8f',(1.0/sell_price.to_f))}"
  puts "amount_sell.to_s: #{amount_sell.to_s}"
  puts ""
  puts "market_ask_price_R: #{sprintf('%.8f',(1.0/market_ask_price.to_f))}"
  puts "margin difference: #{sprintf('%.8f',(1.0/market_ask_price.to_f) * (profit_margin.to_f/100.0))}"    
  puts "buy_currency: #{buy_currency}"
  puts "buy_issuer: #{buy_issuer}"
  puts "buy_price.to_s: #{buy_price.to_s}"
  puts "buy_priceR: #{1.0/buy_price.to_f}"
  puts "amount_buy.to_s: #{amount_buy.to_s}"
 
  if params["disable_trade"] == "true" || params["disable_trade"] == true
    puts "disable_trade set true,  will not be trading"
    return
  end

  if params["dual_trader"] == true
    trader_account_sell = params["trader_account_sell"]
    trader_account_buy = params["trader_account_buy"]
  else
    trader_account_sell = params["trader_account"]
    trader_account_buy = params["trader_account"]
  end
  if params["tx_mode"] == "true" || params["tx_mode"] == true
     
       #offer_id = get_offer_id(sell_issuer,sell_currency, buy_issuer, buy_currency,params["offers"])
       offer_id = ""
       puts "start first trade_count loop"
       puts "asset_pair #{asset_pair}"
       #puts "scale_parabola: #{params["scale_parabola"][asset_pair]}"
       params["trade_count"][asset_pair].times do |i|
         puts "market_ask_price: #{market_ask_price}"
         puts "amount: #{amount.to_f}"
         if i!=0        
           if params["trade_increment"][asset_pair].nil?
             sell_price = sell_price.to_f + ((profit_margin.to_f/100)*sell_price.to_f )
           else
             #puts "trade_increment not nil"
             sell_price = sell_price.to_f + (params["trade_increment"][asset_pair].to_f) 
           end
         end
         if !params["trade_decimal_round"][asset_pair].nil?
            sell_price = sell_price.to_f.round(params["trade_decimal_round"][asset_pair])
         end
         if !params["scale_parabola"][asset_pair].nil?
           #puts "sell_price-market_ask_price: #{sell_price-market_ask_price}"
           #puts "**2:  #{(sell_price-market_ask_price)**2}"
           #puts "scaled: #{((sell_price-market_ask_price)**2)*params["scale_parabola"][asset_pair].to_f}"
           amount_sell = (((sell_price-market_ask_price)**2)*params["scale_parabola"][asset_pair].to_f)+ amount.to_f
           #puts "amount_sell: #{amount_sell}   i:#{i}"
         end 
         puts "sell_price: #{sell_price} i: #{i}"
         puts "amount_sell: #{amount_sell}"
         if params["trade_on_sell_side"] == true
           tx1 = send_offer_tx(trader_account_sell, sell_issuer, sell_currency, buy_issuer, buy_currency, amount_sell.to_s, sell_price.to_s,offer_id,params["next_seq"])
         
           if params["dual_trader"] == true
             params["tx_sell_array_in"].push(tx1)
           else
             #puts "push to tx_array_in"
             params["tx_array_in"].push(tx1)
           end
         end
       

            
         #offer_id = get_offer_id(buy_issuer, buy_currency, sell_issuer, sell_currency,params["offers"])
         offer_id = ""
      
         #puts "scale_parabola: #{params["scale_parabola"][asset_pair]}  i:#{i}"
         if i!=0
           if params["trade_increment"][asset_pair].nil? 
             buy_price = buy_price.to_f + ((profit_margin.to_f/100) * buy_price.to_f )
           else
             buy_price = 1/((1/buy_price.to_f) - params["trade_increment"][asset_pair].to_f) 
           end
         end    
           
         if !params["trade_decimal_round"][asset_pair].nil?            
            buy_price = 1/((1/buy_price.to_f).round(params["trade_decimal_round"][asset_pair]))          
         end        
         if !params["scale_parabola"][asset_pair].nil? 
           # the above amount_sell might work but I can't figure this one out           
           amount_buy = amount_sell * 1/buy_price
         end 
         puts "buy_price: #{buy_price} i: #{i}"
         puts "buy_priceR: #{1/buy_price.to_f}"
         puts "amount_buy: #{amount_buy}"
         puts "amount_buyR: #{amount_buy.to_f/sell_price.to_f}"
         if params["trade_on_buy_side"] == true  
           tx2 = send_offer_tx(trader_account_buy, buy_issuer, buy_currency, sell_issuer, sell_currency, amount_buy.to_s, buy_price.to_s,offer_id,params["next_seq"])
           if params["dual_trader"] == true
             params["tx_buy_array_in"].push(tx2)
           else
             params["tx_array_in"].push(tx2)
           end           
         end     
       end
       
       return params["tx_array_in"]
  else
    send_offer(trader_account, sell_issuer, sell_currency, buy_issuer, buy_currency, amount_sell.to_s, sell_price.to_s)

    sleep 2

    send_offer(trader_account, buy_issuer, buy_currency, sell_issuer, sell_currency, amount_buy.to_s, buy_price.to_s)
  end

  #rescue 
   # puts "trade_offer_set failed better luck next loop"
  #end

end

def get_offer_id(sell_issuer,sell_currency, buy_issuer, buy_currency,offers = nil,sellers_account = nil)
  if offers.nil?
    result = Utils.get_account_offers_horizon(sellers_account)
    offers = result["_embedded"]["records"]
  end
  #puts "offers: #{offers}"
  #puts ""
  #puts "sell_currency #{sell_currency}"
  #puts "sell_issuer #{sell_issuer}"
  #puts "buy_currency #{buy_currency}"
  #puts "buy_issuer #{buy_issuer}"
  #puts ""
  offers.each{ |row|
    tf = true  
    if row["selling"]["asset_type"] != "native"     
       if row["selling"]["asset_issuer"] != sell_issuer
         #puts "a false"
         tf = false
       end
       if row["selling"]["asset_code"] != sell_currency
         #puts "c false"
         tf = false
       end
    else
      if sell_currency != "XLM"
        #puts "g false"
        tf = false
      end
    end
    if row["buying"]["asset_type"] != "native"
      if row["buying"]["asset_issuer"] != buy_issuer
        #puts "b false"
        tf = false
      end
      if row["buying"]["asset_code"] != buy_currency
        #puts "d false"
        tf = false
      end  
    else
      if buy_currency != "XLM"
        #puts "e false"
        tf = false
      end
    end

    if tf == true
      puts "get_offer_id: #{row["id"]}"
      return row["id"]
    end
  }
  puts "get_offer_id: not found"
  return ""
end

def trade_peg(params)
  puts "trade_peg started"
  #this will trade a peged valued asset. It will sell_currency based on the value of a peg_base_asset * peg_multiple
  # this value will then be used to setup a trade set with a buy_currency with bid and ask above and bellow our peg value by profit_margin amount
  # example FUNT will be valued at 40 Baht or 40 THB and traded with XLM, we will trade 10 FUNTS with trade of profit .5%
  # trade_peg("FUNT",10,"THB",40, "XLM",0.5)
  # note the peg will alway be from fiat currency for now that starts from base of USD
  # peg_base_rate_usd: 1 USD = 34 THB
  # buy_currency_rate_usd: 1 USD = 341.629 XLM 
  # peg_rate_usd: 40 THB = 40/34.63 = 1.155 USD
  # 1 FUNT = 40 THB = 1.155 USD = peg_rate_usd
  # peg_rate_buy = 1.155 * 341.629 = 393.8 XLM = 1 FUNT  ask FUNT/XLM
  # peg_rate_sell = 1 / 393.8 =  0.0025373227850422875 bid  XLM/FUNT
  # amount_buy = amount * peg_rate_buy  ; to buy on XLM/FUNT side
  # amount_sell = amount
  #  note these values above are before we add and subtract profit margin spread but that's done within trade_offer_set(params)
  #params["trader_account"] = 
  #params["sell_currency"] = "FUNT"
  #params["sell_issuer"]  
  #params["buy_currency"] = "XLM"
  #params["buy_issuer"]
  #params["amount"] = 10
  #params["peg_base_asset"] = "THB"
  #params["peg_multiple"] = 40
  #params["profit_margin"] = 0.5
  #params["tx_array_in"]  = []; an empty array or an array of other tx we will add to and return with added tx from this run
  #params["tx_mode"] = true  ; don't perform the transaction just return a set to tx in an array [tx1,tx2], default is false
    # this is so we can collect all the tx and then perform a single transaction on all of them (much faster)
  #params["feed_poloniex"] = ["BTC","XLM","USDT","USD"]
  #params["feed_other"] = ["THB","USD"]
  #params["disable_record_feed"] = true
  #begin 

  if params["disable_trade_peg"] == true
    puts "disable_trade_get set true will not be trading here"
    return
  end
  peg_base_rate_usd = get_any_exchangerate(params["peg_base_asset"], "USD",params) 
  buy_currency_rate_usd = get_any_exchangerate(params["buy_currency"], "USD",params)
  if peg_base_rate_usd == 0 || buy_currency_rate_usd == 0
    puts "bad data from get_any_exchangerate,  will not trade this"
    return
  end
  puts "peg_base_rate_usd: #{peg_base_rate_usd}"
  puts "buy_currency_rate_usd: #{buy_currency_rate_usd}" 
  peg_rate_usd = params["peg_multiple"].to_f / peg_base_rate_usd.to_f  
  puts "peg_rate_usd: #{peg_rate_usd}"
  peg_rate_sell =  buy_currency_rate_usd * peg_rate_usd 
  puts "peg_rate_sell: #{peg_rate_sell}"
  amount_buy = params["amount"].to_f * peg_rate_sell
  puts "amount_buy: #{amount_buy}"   
  peg_rate_buy = 1.0 / peg_rate_sell
  puts "peg_rate_buy: #{peg_rate_buy}"
  amount_sell = params["amount"].to_f 
  puts "amount_sell: #{amount_sell}"

  params["market_ask_price"] = peg_rate_sell
  trade_offer_set(params)

  if params["tx_mode"] == "true" || params["tx_mode"] == true
    return
  end
  puts "continued after tx_mode check"

  if params["dual_trader"] == true
    params["trader_account"] = params["trader_account_buy"]
    send_tx_array(params,params["tx_buy_array_in"])
    params["trader_account"] = params["trader_account_sell"]
    send_tx_array(params,params["tx_sell_array_in"])              
  else
    send_tx_array(params)
  end

  return 

  #rescue
  #  puts "trade_peg failed, better luck next loop"
  #end
end

def check_feedable(currency,base,feed_array)
  puts "check_feedable"
  puts "feed_array: #{feed_array}"
  a = false
  b = false
  if currency == base
    puts "currency and base are the same so not feedable"
    return false
  end
  feed_array.each { |ccode|
    if ccode == currency
      a = true
    end
    if ccode == base
      b = true
    end
  }
  if a && b 
    return true
  else
    puts "no feed found for this set #{currency} and #{base} on this feed_array"
    return false
  end 
end

def get_any_exchangerate(currency_code, base_code,params)
  puts "get_any_exchangerate started"
  if currency_code == base_code
    puts "currency_code and base_code are the same, will return 1"
    return 1
  end
  timestamp = (Time.now.to_i - 240).to_s
  puts "timestamp: #{timestamp}"
  # check to see if we already collected this data within the last 60 sec (now 240 sec 4 min), if so give us that
  #result = get_mss_server_feed_exchangerate_min(currency_code,base_code,timestamp )
  #if result.to_f > 0
  #  return result.to_f
  #end
  #return the rate of currency_code exchange with base_code 
  # will auto pick needed feed determined by lists in params["feed_poloniex"] and params["feed_other"]
  $disable_record_feed = params["disable_record_feed"]
  if check_feedable(currency_code,base_code,params["feed_poloniex"])
    #puts "poloniex feed selected"
    puts "coinbase feed selected"
    #result_exch = get_poloniex_exchangerate(currency_code,base_code)
    #result = convert_polo_to_liquid(result_exch, 0.0)
    #result = get_poloniex_exchange_liquid(currency_code,base_code,params["min_liquid"])
    #result = get_poloniex_exchangerate(currency_code,base_code)
     #been having problems with poloniex feed will try coinbase but not sure how accurate coinbase is so add profit margin to 5% also instead of 2.5%
    result = get_coinbase_exchangerate(currency_code,base_code)
  else
    if check_feedable(currency_code,base_code,params["feed_other"])
      puts "feed_other: #{params["feed_other"]}"
      result = get_exchangerate(currency_code,base_code,params["exchange_feed_key"])
    else
      puts "feed_other: #{params["feed_other"]}"
      puts " we have no data feed for this currency pair #{currency_code}  and #{base_code} so can't trade"
      return
    end
  end
  puts "get_exchangerate result.keys: #{result.keys}"
  puts "get_exchangerate result: #{result}"
  if result["status"] == "fail"
     puts "get_exchangerate status fail,  will not trade this data in auto_trade_offer_set"
     return 0
  else
    puts "get_exchangerate status OK,  will trade"
  end
  #puts "last_rate: #{$last_rate}"
  return result["rate"].to_f
end

def get_exchangerate3(currency_code,base_code,key="")
 # this is now disabled due to yahoo discontinued feed. later we can fix this with new secound feed
  # this is used to get fiat currency rates from two sources, checks to verify they are close match with returned status
  # this is not used for crypto price lookups
  # set to default exchange rate feed source
  data_1 = get_yahoo_finance_exchangerate(currency_code,base_code)
  #data_1 = get_openexchangerates(currency_code,base_code,key)
  data_1["diff"] = "0.0"
  #puts "get_exch record_feed: #{data_1}"
  record_feed(data_1)
  data_2 = get_openexchangerates(currency_code,base_code,key)
  #data_2 = get_yahoo_finance_exchangerate(currency_code,base_code)
  #puts "data_2: #{data_2}"
  if data_1["status"] == "fail"
    data_2["status"] = "pass1"
    return data_2
  end
  rat = data_1["rate"].to_f/data_2["rate"].to_f
  if rat > 1
    diff = (rat -1)
  else
    diff = (1 - rat)
  end
  
  #puts "diff: " + diff.to_s
  data_2["diff"] = diff
  #data_2["status"] = "pass"
  record_feed(data_2)
  if diff > $max_diff
    data_2["status"] = "fail"
  else
    data_2["status"] = "pass"
  end 
  return data_2
end

def get_exchangerate(currency_code,base_code,key="")
  # this is used to get fiat currency rates from two sources, checks to verify they are close match with returned status
  # this is not used for crypto price lookups
  # set to default exchange rate feed source
  #  this version disables yahoo feed as it seems yahoo feed is broken at the moment
  data_2 = get_openexchangerates(currency_code,base_code,key)
  record_feed(data_2)
  data_2["status"] = "pass"
  return data_2
end

def get_yahoo_finance_exchangerate(currency_code,base_code)
 # note it seems USD/THB is delayed by about 30 minutes and in fact buy random time windows so be careful using this data
 # some others are delayed by much more like THB/USD can be 6 hours or more delayed  
 #https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20yahoo.finance.xchange%20where%20pair%20in%20(%22USDTHB%22)&format=json&diagnostics=true&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&callback=
    puts "get_yahoo_finance_exchangerate"
    puts "currency_code: #{currency_code}" 
    puts "base_code: #{base_code}"
    # if more than one currency is needed
    url_start_b = "https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20yahoo.finance.xchange%20where%20pair%20in%20"
    url_end_b = "&format=json&diagnostics=true&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&callback="
    # with just a single currency
    url_start = "https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20yahoo.finance.xchange%20where%20pair%20in%20(%22"
    url_end = "%22)&format=json&diagnostics=true&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&callback="
    #puts " currency_code: #{currency_code}"
    #puts " base_code: #{base_code}"
    send = url_start + base_code + currency_code + url_end
    #send = url_start_b +'(%22' + base_code + currency_code + '%22)' +  url_end_b
    # to lookup more than one currency at the same time
    #send = url_start_b +'(%22USDEUR%22,%20%22USDJPY%22)' +  url_end_b
    puts "yahoo sending:  #{send}"
    begin
      postdata = RestClient.get send
    rescue => e
      puts "fail in get_yahoo_finance_exchangerate at RestClient.get  error: #{e}"
      data_out = {}
      data_out["service"] = "yahoo"
      data_out["status"] = "fail"
      puts "yahoo data_out: #{data_out}"
      return  data_out
    end
    #puts "postdata: " + postdata
    data = JSON.parse(postdata)
    data_out = {}
    data_out["currency_code"] = currency_code
    data_out["rate"] = data["query"]["results"]["rate"]["Rate"].to_s
    data_out["datetime"] = data["query"]["results"]["rate"]["Date"].to_s + "T" + data["query"]["results"]["rate"]["Time"].to_s
    data_out["ask"] = data["query"]["results"]["rate"]["Ask"]
    data_out["bid"] = data["query"]["results"]["rate"]["Bid"]
    data_out["base"] = base_code
    data_out["service"] = "yahoo"
    puts "yahoo data_out: #{data_out}"
    return data_out
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
    #puts "sending:  #{send}"
    begin
      #postdata = RestClient.get send , :user_agent => "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:47.0) Gecko/20100101 Firefox/47.0"
      postdata = RestClient.get send , { :Accept => '*/*', 'accept-encoding' => "gzip, deflate", :user_agent => "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:47.0) Gecko/20100101 Firefox/47.0"}
    rescue => e
      puts "fail in get_currencylayer_exchangerate at RestClient.get  error: #{e}"
      data_out = {}
      data_out["service"] = "currencylayer"
      data_out["status"] = "fail"
      return  data_out
    end
    #puts "postdata: " + postdata
    data = JSON.parse(postdata)
    data["status"] = "pass"
    data["service"] = "currencylayer"
    return data
end

def get_funtracker_exchangerate(currency_code,base_code)
  #this gets the stellar.org exchange rate feed from funtracker.sites mss-server
  #{"action":"get_ticker_list","asset_pair":"THB_USD"}
  #curl -X POST b.funtracker.site:9495 -d '{"action":"get_ticker_list","asset_pair":"THB_USD"}'
  #RestClient.post 'http://b.funtracker.site:9495', '{"action":"get_ticker_list","asset_pair":"THB_USD"}'
  #{"action":"get_ticker_list","status":"success","asset_pairs":["THB","GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF","USD","GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF","34.80315"]}
  #send = "http://b.funtracker.site:9495"
  send = $mss_server_url
  post_package = '{"action":"get_ticker_list","asset_pair":"' + base_code + "_" +currency_code + '"}'
    puts "sending:  #{send}"
    begin
      postdata = RestClient.post send , post_package
    rescue => e
      puts "fail in get_funtracker_exchangerate at RestClient.get  error: #{e}"
      data_out = {}
      data_out["service"] = "funtracker.site"
      data_out["status"] = "fail"
      return  data_out
    end
    puts "postdata: " + postdata
    data = JSON.parse(postdata)
    #data["status"] = "pass"
    data["service"] = "funtracker.site"
    return data
end

def get_mss_server_feed_exchangerate(currency_code,base_code,before_timestamp = 0)
  #this gets the exchange rate feed data that was last recorded on the mss_server_url
  # with this we can reduce lookups on our feed services if we need the feed data more than one time in each loop.
  # with before_timestamp set to value other than 0 will return 0 if no marked data stamped before that time
  #  wtih this we can enter before_timestamp = (Time.now.to_i - 60).to_s that will return a value of >0 if we have new data less than 60 sec old
  #{"action":"get_feed_list","asset_pair":"THB_USD"}
  #curl -X POST b.funtracker.site:9495 -d '{"action":"get_feed_list","asset_pair":"THB_USD"}'
  #RestClient.post 'http://b.funtracker.site:9495', '{"action":"get_feed_list","asset_pair":"THB_USD"}'
  #{"action":"get_feed_list","status":"success","asset_pairs":["USD","THB","1475788307","0.028704898146409908","0.028704898146409908"]}
  #send = "http://b.funtracker.site:9495"
  send = $mss_server_url
  
    post_package = '{"action":"get_feed_list","asset_pair":"' + base_code + "_" +currency_code + '"}'

    puts "sending:  #{send}"
    begin
      postdata = RestClient.post send , post_package
    rescue => e
      puts "fail in get_funtracker_exchangerate at RestClient.get  error: #{e}"
      data_out = {}
      data_out["service"] = "mss_server"
      data_out["status"] = "fail"
      return  data_out
    end
    puts "postdata: " + postdata
    data = JSON.parse(postdata)
    if data["asset_pairs"].nil?
      data["asset_pairs"] = []
      data["status"] = "fail"
      data["asset_pairs"][3] = 0
      data["asset_pairs"][4] = 0
      return data
    end
    puts "json: #{data}"
    if data["asset_pairs"][2].to_i < before_timestamp.to_i && before_timestamp.to_i > 0
     data["status"] = "fail"
     data["asset_pairs"][3] = 0
     data["asset_pairs"][4] = 0
     return data
   end
    #data["status"] = "pass"
    data["service"] = "mss_server"
    return data
end

def get_mss_server_feed_exchangerate_min(currency_code,base_code,before_timestamp = 0)
  #min returns just last bid price,  if bad data status returns 0
  result = get_mss_server_feed_exchangerate(currency_code,base_code,before_timestamp)
  if result["status"] == "error" || result["status"] == "fail" || result["asset_pairs"].nil?
   return 0
  else
   return result["asset_pairs"][4]
  end 
end

  def get_funtracker_exchangerate_min(currency_code,base_code)
    result = get_funtracker_exchangerate(currency_code,base_code)
    if result["status"] == "error" || result["status"] == "fail" || result["asset_pairs"].nil?
     return 0
    else
     #averge bid ask price to return center bettween them
     avg =  (result["asset_pairs"][4].to_f + result["asset_pairs"][5].to_f)/2.0
     #return result["asset_pairs"][4] ; was just returning ask
     return avg
    end 
  end

def get_coinbase_exchangerate(currency_code,base_code)
  #note at present this only works with base_code = USD or BTC or must have USD or BTC as currency_code
  #https://api.coinmarketcap.com/v2/ticker/?convert=XLM&limit=1
    flag_invert = 0
    if base_code == "USD" || base_code == "BTC"
      puts "base_code ok"
    else
      if currency_code == "USD" || currency_code == "BTC"
        flag_invert = 1
        temp_base_code = base_code
        base_code = currency_code
        currency_code = temp_base_code
      else
        puts "base_code and currency_code not USD or BTC return 0"
        return 0
      end
    end
    url_start = "https://api.coinmarketcap.com/v2/ticker/?convert="
    url_end = "&limit=1"
    send = url_start + currency_code + url_end
  
    puts "coinbase sending:  #{send}"
    begin
      #postdata = RestClient.get send
      postdata = RestClient::Request.execute(method: :get, url: send,timeout: 10)
    rescue => e
      puts "fail in get_coinbase_exchangerate at RestClient.get  error: #{e}"
      data_out = {}
      data_out["service"] = "coinbase"
      data_out["status"] = "fail"
      puts "coinbase data_out: #{data_out}"
      return  data_out
    end
    #puts "postdata: " + postdata
    data = JSON.parse(postdata)
    puts "data:"
    #puts data["data"]["1"]["quotes"][currency_code]["price"]
    puts data["data"]["1"]["quotes"]["USD"]["price"]
    price_btc = data["data"]["1"]["quotes"][currency_code]["price"]
    price_btc_usd = data["data"]["1"]["quotes"]["USD"]["price"]

    if base_code == "USD"
      #price = price_btc_usd/price_btc
      price = price_btc/price_btc_usd
    else
      #price = price_btc
      price = price_btc
    end
    data_out = {}
    data_out["service"] = "coinbase"
    data_out["status"] = "pass"
    #data_out["rate"] = price
    if flag_invert == 0
      data_out["rate"] = sprintf('%.8f',price.to_f)
      data_out["base"] = base_code
      data_out["currency_code"] = currency_code
    else
      data_out["rate"] = sprintf('%.8f',1.0/price.to_f)
      data_out["base"] = currency_code
      data_out["currency_code"] = base_code
    end
    data_out["last_updated"] = data["data"]["1"]["last_updated"]
    puts "price: #{price}"
    puts data_out
    return data_out
end

def get_poloniex_exchangerate(currency_code,base_code)
  #https://poloniex.com/public?command=returnOrderBook&currencyPair=BTC_STR
  # see: https://www.poloniex.com/support/api/ for details
  puts "get_poloniex_exchangerate"
  puts "currency_code: #{currency_code}"
  puts "base_code: #{base_code}"
  if currency_code == "XLM" || currency_code == "native"
    currency_code_send = "STR"
  else
    currency_code_send = currency_code
  end
  if base_code == "XLM" || base_code == "native"
    base_code_send = "STR"
  else
    base_code_send = base_code
  end

  if currency_code == "USD" 
    currency_code_send = "USDT"
  end
    
  if base_code == "USD" 
    base_code_send = "USDT"
  end
  if base_code_send == currency_code_send
    puts "base_code_send == currency_code_send will return 1"
    return 1
  end
  #url_start = "https://poloniex.com/public?command=returnOrderBook&currencyPair="
  url_start = "https://poloniex.com/public?command=returnTicker"
  url_end = ""
  #send = url_start + base_code_send + "_" + currency_code_send 
  send = url_start 
  #puts "sending:  #{send}"
  begin
    postdata = RestClient.get send , { :Accept => '*/*', 'accept-encoding' => "gzip, deflate", :user_agent => "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:47.0) Gecko/20100101 Firefox/47.0"}
  rescue => e
    puts "fail in get_poloniex_exchangerate at RestClient.get  error: #{e}"
    data_out = {}
    data_out["service"] = "poloniex.com"
    data_out["status"] = "fail"
    return  data_out
  end
  #puts "postdata: " + postdata
  data = JSON.parse(postdata)
  #puts "data: #{data}"
  data_ret = {}
  data_ret["status"] = "pass"
  if base_code_send == "BTC" || base_code_send == "USDT"
    if base_code_send == "BTC" && currency_code_send == "USDT"
       obj_key = currency_code_send + "_" + base_code_send
       puts "obj_key: #{obj_key}"
       data_ret["rate"] = sprintf('%.8f',data[obj_key]["last"].to_f)
       data_ret["ask"] = sprintf('%.8f',data[obj_key]["lowestAsk"].to_f)
       data_ret["bid"] = sprintf('%.8f',data[obj_key]["highestBid"].to_f)
    else 
      obj_key = base_code_send + "_" + currency_code_send
      puts "obj_key: #{obj_key}"
      data_ret["rate"] = sprintf('%.8f',1.0/data[obj_key]["last"].to_f)
      data_ret["ask"] = sprintf('%.8f',1.0/data[obj_key]["highestBid"].to_f)
      data_ret["bid"] = sprintf('%.8f',1.0/data[obj_key]["lowestAsk"].to_f)
    end
  else
    obj_key = currency_code_send + "_" + base_code_send
    puts "obj_key: #{obj_key}"
    data_ret["rate"] = sprintf('%.8f',data[obj_key]["last"].to_f)
    data_ret["ask"] = sprintf('%.8f',data[obj_key]["lowestAsk"].to_f)
    data_ret["bid"] = sprintf('%.8f',data[obj_key]["highestBid"].to_f)
  end
  data_ret["service"] = "poloniex.com"
  data_ret["base"] = base_code
  data_ret["currency_code"] = currency_code
  data_ret["datetime"] = Time.now.to_s
  puts "data_ret: #{data_ret}"
  record_feed(data_ret)
  return data_ret
end

def get_poloniex_exchangerate_orderbook(currency_code,base_code)
  #https://poloniex.com/public?command=returnOrderBook&currencyPair=BTC_STR
  # see: https://www.poloniex.com/support/api/ for details
  
  if currency_code == "XLM" || currency_code == "native"
    currency_code_send = "STR"
  else
    currency_code_send = currency_code
  end
  if base_code == "XLM" || base_code == "native"
    base_code_send = "STR"
  else
    base_code_send = base_code
  end
  url_start = "https://poloniex.com/public?command=returnOrderBook&currencyPair="
  url_end = ""
  send = url_start + base_code_send + "_" + currency_code_send 
  #send = url_start + currency_code_send + "_" + base_code_send
  #puts "sending:  #{send}"
  begin
    postdata = RestClient.get send , { :Accept => '*/*', 'accept-encoding' => "gzip, deflate", :user_agent => "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:47.0) Gecko/20100101 Firefox/47.0"}
  rescue => e
    puts "fail in get_openexchangerate at RestClient.get  error: #{e}"
    data_out = {}
    data_out["service"] = "openexchangerates.org"
    data_out["status"] = "fail"
    return  data_out
  end
  #puts "postdata: " + postdata
  data = JSON.parse(postdata)
  data_out["status"] = "pass"
  data["service"] = "poloniex.com"
  data["base"] = base_code
  data["currency_code"] = currency_code
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
  puts "get_openexchangerates started"
  url_start = "https://openexchangerates.org/api/latest.json?app_id="
  url_end = ""
  send = url_start + key
  #puts "sending:  #{send}"
  begin
    #postdata = RestClient.get send , { :Accept => '*/*', 'accept-encoding' => "gzip, deflate", :user_agent => "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:47.0) Gecko/20100101 Firefox/47.0"}
    postdata = RestClient.get send , { :Accept => '*/*', 'accept-encoding' => "gzip, deflate"}
  rescue => e
    puts "fail in get_openexchangerate at RestClient.get  error: #{e}"
    data_out = {}
    data_out["service"] = "openexchangerates.org"
    data_out["status"] = "fail"
    return  data_out
  end
  #puts "postdata: " + postdata
  data = JSON.parse(postdata)
  data_out = {}
  data_out["status"] = "pass"
  if (base_code == "USD")
    #defaults to USD
    data_out["currency_code"] = currency_code
    data_out["base"] = base_code
    data_out["datetime"] = Time.at(data["timestamp"]).to_datetime.to_s
    #date["rate"] = data["rates"][currency_code]
    data_out["rate"] = (data["rates"][currency_code]).to_s
    data_out["ask"] = data_out["rate"]
    data_out["bid"] = data_out["rate"]
    data_out["service"] = "openexchangerates.org"
    puts "data_out: #{data_out}"
    return data_out
  end
  puts "here??"
  usd_base_rate = data["rates"][currency_code]
  base_rate = data["rates"][base_code]
  rate = base_rate / usd_base_rate
  data_out["currency_code"] = currency_code
  #data_out["rate"] = rate.to_s
  #data_out["ask"] = data_out["rate"]
  #data_out["bid"] = data_out["rate"]
  data_out["rate"] = (1.0 / rate.to_f)
  data_out["ask"] = data_out["rate"].to_f
  data_out["bid"] = data_out["rate"].to_f
  data_out["base"] = base_code
  data_out["datetime"] = Time.at(data["timestamp"]).to_datetime.to_s
  data_out["service"] = "openexchangerates.org"
  puts "data_out: #{data_out}"
  return data_out
end



def send_offer(sellers_account,sell_issuer,sell_currency, buy_issuer, buy_currency,amount,price,offerid="")
  if $disable_trade
    puts " $disable_trade active disable send_offer"
    return
  end
  
  tx = send_offer_tx(sellers_account,sell_issuer,sell_currency, buy_issuer, buy_currency,amount,price,offerid)
  b64 = tx.to_envelope(sellers_account).to_xdr(:base64)
  #result = Utils.send_tx(b64)
  result = send_tx(b64)
  #puts "send_tx result #{result}"
end

def send_offer_tx(sellers_account,sell_issuer,sell_currency, buy_issuer, buy_currency,amount,price,offerid="",next_seq=0)
  if $disable_trade
    puts " $disable_trade active disable send_offer"
    return
  end
  if next_seq == 0
    next_seq = Utils.next_sequence(sellers_account)
  end
  if sell_currency == "XLM"
    sell_currency = "native"
    sell_issuer = ""
  end
  if buy_currency == "XLM"
    buy_currency = "native"
    buy_issuer = ""
  end
  tx = Utils.offer_tx(sellers_account,sell_issuer,sell_currency, buy_issuer, buy_currency,amount,price,offerid,next_seq)
  return tx
end

def convert_polo_to_liquid(data_hash_in, min_liquid_shares)
  #this will convert our standard poloniex exchange api format to our
  # shrunken liquid data format:
  # this will return the price of a poloniex exchange book traded asset pair that
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
  #puts "convert_polo data_hash_in: #{data_hash_in}" 
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
  #puts "min_liquid_shares: #{min_liquid_shares}"
  result["asks"].each{ |row|
    #puts "price: #{row[0]}"
    #puts "volume: #{row[1]}"
    total_volume = total_volume + row[1].to_f
    #puts "total vol: #{total_volume}"
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
  #puts "out_result[ask][price]  #{out_result["ask"]["price"]}"
  out_result["ask"]["total_volume"] = format("%.8f",total_volume)
  if total_volume == 0
    out_result["ask"]["total_avg_price"] = out_result["ask"]["price"]
  else
    out_result["ask"]["total_avg_price"] = format("%.8f",(total_price / total_volume))
  end
  out_result["ask"]["total_offers"] = offer_count
  out_result["rate"] = out_result["ask"]["price"]
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
  if total_volume == 0 
    out_result["bid"]["total_avg_price"] = out_result["bid"]["price"]
  else
    out_result["bid"]["total_avg_price"] = format("%.8f",(total_price / total_volume))
  end
  out_result["bid"]["total_offers"] = offer_count
  #puts "out_result: #{out_result}"
  return out_result
end 

def get_poloniex_exchange_liquid(currency_code,base_code,min_liquid)
  #this will return the price of a poloniex exchange traded asset pair that
  # would be requied to bid or ask if you were to purchase or sell min_liquid_shares of that asset.
  # see: convert_polo_to_liquid(data_hash_in, min_liquid_shares) for details
  result = get_poloniex_exchangerate(currency_code,base_code)
  result_lqd = convert_polo_to_liquid(result,min_liquid)
  to_record_feed = {}
  to_record_feed["base"] = base_code
  to_record_feed["currency_code"] = currency_code
  to_record_feed["rate"] = result_lqd["ask"]["price"]
  to_record_feed["ask"] = result_lqd["ask"]["price"]
  to_record_feed["bid"] = result_lqd["bid"]["price"]
  to_record_feed["service"] = "poloniex.com"
  #to_record_feed["timestamp"] = Time.now.to_i
  to_record_feed["datetime"] = Time.now.to_s
  #puts "to_record_feed: #{to_record_feed}"
  record_feed(to_record_feed)
  return to_record_feed
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

 $try_count = 4
def delete_offers(account,delete_sets = "all")
  #if asset_code left blank or nil it will delete all open orders on this account
 begin
  result = Utils.get_account_offers_horizon(account)
  #puts "results: #{result["_embedded"]["records"][0]["id"]}"
  #puts "results: #{result["_embedded"]["records"]}"
  puts "delete_sets: #{delete_sets}"
  if (result["_embedded"]["records"][0].nil?)
    puts "no offers to delete, nothing done"
    return
  end
  if delete_sets.length == 0
    puts "no delete_set pairs in delete_sets, nothing to be done"
    return
  end
  next_seq = Utils.next_sequence(account)
  #puts "next_seq: #{next_seq}"
  tx_array = []
  puts "found: #{result["_embedded"]["records"].length} tx to delete"
  result["_embedded"]["records"].each{ |row|
    #puts "delete id: #{row["id"]}"
    #puts "selling"
    #puts "asset_issuer: #{row["selling"]["asset_issuer"]}"
    #puts "asset_code: #{row["selling"]["asset_code"]}"
    #puts "buying"
    #puts "asset_issuer: #{row["buying"]["asset_issuer"]}"
    #puts "asset_code: #{row["buying"]["asset_code"]}"
    #puts "amount: #{row["amount"].to_s}"
    #puts "price: #{row["price"].to_s}"
    #puts ""
    if row["selling"]["asset_type"] == "native"
      row["selling"]["asset_code"] = "XLM"
    end
    if row["buying"]["asset_type"] == "native"
      row["buying"]["asset_code"] = "XLM"
    end
    need_delete = false
    if delete_sets.to_s == "all"
      puts "delete all set"
      need_delete = true
    else
      delete_sets.each{ |set|
        #puts "set: #{set}"
        if set[0] == row["buying"]["asset_code"] && set[1] == row["selling"]["asset_code"]
          need_delete = true
        end
        if set[1] == row["buying"]["asset_code"] && set[0] == row["selling"]["asset_code"]
          need_delete = true
        end
      }
    end
    #puts "need_delete: #{need_delete}"
    if need_delete
    #if (asset_code == row["selling"]["asset_code"] || asset_code == row["buying"]["asset_code"] || asset_code == "")
      tx = Utils.offer_tx(account,row["selling"]["asset_issuer"],row["selling"]["asset_code"],row["buying"]["asset_issuer"], row["buying"]["asset_code"],"0",row["price"],row["id"],next_seq)
      tx_array.push(tx)
      puts "deleting id: #{row["id"]}"
    end
  }

  tx_all =  Utils.tx_merge(tx_array)
  b64 = tx_all.to_envelope(account).to_xdr(:base64)
  #if params["disable_trade"] == "true" || params["disable_trade"] == true
  #  puts "disable_trade is set true will not be trading b"
  #  return
  #end
  #result = Utils.send_tx(b64)
  result = send_tx(b64)
  return result
 rescue
   puts "delete_offers send_tx_array or other failed, will try again in 30 sec"
   $try_count = $try_count -1
   if $try_count == 0
     puts "delete_offers try_count exeeded, will exit to have admin check why"
     exit
   end
   sleep 30
   delete_offers(account,delete_sets)
 end
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
  if data_out["base"]["asset_type"] == "native"
    data_out["base"]["asset_code"] = "XLM"
  end
  if data_out["counter"]["asset_type"] == "native"
    data_out["counter"]["asset_code"] = "XLM"
  end

  count = 0
  str_data_in["bids"].each{ |row|
    #puts "price: #{row["price"]}"
    #puts "amount: #{row["amount"]}"
    data_out["bids"][count] = []
    data_out["bids"][count][0] = row["price"]
    data_out["bids"][count][1] = row["amount"]
    count = count + 1
  }

  count = 0
  str_data_in["asks"].each{ |row|
    #puts "price: #{row["price"]}"
    #puts "amount: #{row["amount"]}"
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

    #puts "timestamp_start: #{timestamp_start}"
    #puts "timestamp_end:  #{timestamp_end}"
  
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
      #puts "query_string: #{query_string}" 
      rs = con.query(query_string)
    end

    n_rows = rs.num_rows    
    #puts "There are #{n_rows} rows in the result set"

    array = []
    n_rows.times do
        #puts rs.fetch_row.join("\s")
        #puts "fetch_row: #{rs.fetch_hash}"
        row["timestamp"] = row["timestamp"].to_time.to_i.to_s
        #puts "row[timestamp]: #{row["timestamp"].to_time.to_i}"
        array.push(row)
        #array.push(rs.fetch_hash)
    end

    #puts "array: #{array}"
 
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
  # it will only iterate one level into the data hash at this time with added pre data to add Time.now and timestamp on each entry
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

  # this data will then be writen to a mysql database that will later be used in stellar.org custom api data feeds from the mss-server
  # or can be read with read_ticker() function.
  #data = {"ask"=>{"price"=>"35.66433570", "volume"=>"0.0", "avg_price"=>"35.60209427", "offer_count"=>2, "total_volume"=>0, "total_avg_price"=>"35.60209427", "total_offers"=>2}, "bid"=>{"price"=>"34.27944600", "volume"=>"100.00000000", "avg_price"=>"34.27944600", "offer_count"=>1, "total_volume"=>"200.00000000", "total_avg_price"=>"34.21972575", "total_offers"=>2}, "base"=>{"asset_type"=>"credit_alphanum4", "asset_code"=>"USD", "asset_issuer"=>"GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF"}, "counter"=>{"asset_type"=>"credit_alphanum4", "asset_code"=>"THB", "asset_issuer"=>"GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF"}, "array"=>[1,2,3,4]}

  puts "record_ticker start"
  #puts "data keys: #{data.keys}"
  #puts "data: #{data}"

  if $disable_record
    puts "$disable_record set true so no data saved to mysql for record_ticker data."
    return
  end
  
  if data["ask"]["price"].nil? || data["bid"]["price"].nil?
    puts "ask or bid is nill so must be bad data?"
    puts "ask nil?: #{data["ask"]["price"].nil?}"
    puts "bid nil?: #{data["bid"]["price"].nil?}"
    return
  end
  if data["ask"]["price"].to_f == 0  && data["bid"]["price"].to_f == 0 
    puts "seems ask bid price are zero so must be bad data feed, will not record"
    puts "ask price: #{data["ask"]["price"].to_f}"
    puts "bid price: #{data["bid"]["price"].to_f}"
    return
  end
  if data["base"]["asset_code"] == "XLM" || data["base"]["asset_code"] == "native" || data["base"]["asset_type"] == "native"
    data["base"]["asset_issuer"] = "..."
  end
  if data["counter"]["asset_code"] == "XLM" || data["base"]["asset_code"] == "native" || data["counter"]["asset_type"] == "native"
    data["counter"]["asset_issuer"] = "..."
  end
  #puts "data: #{data}"
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
      #puts "key: #{key}"
      #puts "array: #{array}"
      #puts " respond_to?(:each)  #{data[key].respond_to?(:each)}"
      #puts " respond_to?(:keys):  #{data[key].respond_to?(:keys)}"
      if data[key].respond_to?(:keys)
        data[key].each do |key2, array2|
          #puts "sub key: #{key2}"
          #puts "sub array: #{array2}"
          #puts " planed mysql field name: #{key + "_"+key2}"
          #puts " planed mysql field value: #{data[key][key2]}"
          field_string = field_string + "," + key + "_" + key2 
          value_string = value_string + "," +data[key][key2].to_s
          prep_value = prep_value + ",?"
          if (true if Float(data[key][key2]) rescue false)         
            #puts "type double"
            type = "double NOT NULL"
          else
            #puts "type text"
            type = "text NOT NULL"
          end
          create_table_string = create_table_string + ",`" + key + "_" + key2 + "` " + type
        end
      end    
    end
    create_table_string = create_table_string + ")"
    #puts "field_string: #{field_string}"
    #puts "value_string: #{value_string}"
    #puts "prep_value: #{prep_value}"
    #puts "create_table_string:  #{create_table_string}"
   
    sql = start_sql + field_string + mid_sql + prep_value + end_sql
    #puts " sql: #{sql}"
    con.query(create_table_string)
    pst = con.prepare(sql)
    array_execute = value_string.split(',')
    # puts "array_execute: #{array_execute}"
    pst.execute(*array_execute)
       
  rescue Mysql::Error => e
    puts e.errno
    puts e.error
    
  ensure
    con.close if con
    pst.close if pst
  end

end

def record_feed(data)
  # record_feed(data)
  # This will be writen to allow modifications to the data hash contents without need to modify the mysql sql part of this code.
  # it will parse the values in the data hash and create the needed sql create insert into the mysql database
  # it will only iterate one level into the data hash at this time with added pre data to add Time.now and timestamp on each entry
  # data hash seen for the first time will insert fields and will modify the mysql table on the fly if later data format changes
  # also note if the contents of the first level hash are not a hash in a hash it will be ignored and not added to the table at this time
  #
  # this will take a data_hash formated output from our currency api data feeds in stellar exchange format seen bellow
  # and record it into a table of mysql
  # the data we can get from feeds from several different sources
  # that come in looking like this if from polo:
  # {"ask"=>{"price"=>"0.00000383", "volume"=>"578679.19417415", "avg_price"=>"0.00000383", "offer_count"=>3, "total_volume"=>"10683552.18423253", "total_avg_price"=>"0.00000408", "total_offers"=>50}, "bid"=>{"price"=>"0.00000372", "volume"=>"333182.73763676", "avg_price"=>"0.00000372", "offer_count"=>2, "total_volume"=>"18066738.30346057", "total_avg_price"=>"0.00000341", "total_offers"=>50}}
  #   to be compatible with the stallar.org feed you would have to manually add base and counter to this feeds data object
  #
  # or this if from stellar exchange (note added asset_code and asset_issuer info if from this source):
  # {"ask"=>{"price"=>"35.66433570", "volume"=>"5.84460000", "avg_price"=>"35.60209427", "offer_count"=>2, "total_volume"=>"5.84460000", "total_avg_price"=>"35.60209427", "total_offers"=>2}, "bid"=>{"price"=>"34.27944600", "volume"=>"100.00000000", "avg_price"=>"34.27944600", "offer_count"=>1, "total_volume"=>"200.00000000", "total_avg_price"=>"34.21972575", "total_offers"=>2}, "base"=>{"asset_type"=>"credit_alphanum4", "asset_code"=>"USD", "asset_issuer"=>"GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF"}, "counter"=>{"asset_type"=>"credit_alphanum4", "asset_code"=>"THB", "asset_issuer"=>"GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF"}}
  # we will also add a feed name in the json object to ID the data source.

  # this data will then be writen to a mysql database that will later may be used into stellar.org custom api data feeds from the mss-server
  # or can be read with the read_feed() function.
  #data = {"ask"=>{"price"=>"35.66433570", "volume"=>"0.0", "avg_price"=>"35.60209427", "offer_count"=>2, "total_volume"=>0, "total_avg_price"=>"35.60209427", "total_offers"=>2}, "bid"=>{"price"=>"34.27944600", "volume"=>"100.00000000", "avg_price"=>"34.27944600", "offer_count"=>1, "total_volume"=>"200.00000000", "total_avg_price"=>"34.21972575", "total_offers"=>2}, "base"=>{"asset_type"=>"credit_alphanum4", "asset_code"=>"USD", "asset_issuer"=>"GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF"}, "counter"=>{"asset_type"=>"credit_alphanum4", "asset_code"=>"THB", "asset_issuer"=>"GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF"}, "array"=>[1,2,3,4]}

  puts "record_feed start"
  #puts "data: #{data.keys}"
   
  begin
    con = Mysql.new(Utils.configs["mysql_host"], Utils.configs["mysql_user"],Utils.configs["mysql_password"], Utils.configs["mysql_db"])
    field_string = 'datetime'
    value_string = "'" + Time.now.to_s + "'"   
    prep_value = '?'
    #prep_value = '?,?,?...'
    start_sql = 'insert into feed ('
    mid_sql = ') values ('
    end_sql = ')' 
    create_table_string = "CREATE TABLE IF NOT EXISTS `feed` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `datetime` text NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)"
    data.each do |key, array|
      #puts "key: #{key}"
      #puts "array: #{array}"
      #puts " respond_to?(:each)  #{data[key].respond_to?(:each)}"
      #puts " respond_to?(:keys):  #{data[key].respond_to?(:keys)}"
      #puts " respond_to?(:to_str) #{data[key].respond_to?(:to_str)}"
      #puts " check_float(data) : #{check_float(data[key])}"
      if key=="datetime"
        key_db = "datetime_feed"
      elsif
        key_db = key
      end
      if check_float(data[key])        
        type = "double NOT NULL"
        create_table_string = create_table_string + ",`" + key_db  + "` " + type
        prep_value = prep_value + ",?"
        field_string = field_string + "," + key_db  
        value_string = value_string + "," +data[key].to_s
      elsif data[key].respond_to?(:to_str)
        type = "text NOT NULL"
        create_table_string = create_table_string + ",`" + key_db  + "` " + type
        prep_value = prep_value + ",?"
        field_string = field_string + "," + key_db  
        value_string = value_string + "," + "'" + data[key].to_s + "'"
      elsif data[key].respond_to?(:keys)
        data[key].each do |key2, array2|
          #puts "sub key: #{key2}"
          #puts "sub array: #{array2}"
          #puts " planed mysql field name: #{key + "_"+key2}"
          #puts " planed mysql field value: #{data[key][key2]}"
          field_string = field_string + "," + key + "_" + key2 
          value_string = value_string + "," +data[key][key2].to_s
          prep_value = prep_value + ",?"
          if (true if Float(data[key][key2]) rescue false)         
            #puts "type double"
            type = "double NOT NULL"
          else
            #puts "type text"
            type = "text NOT NULL"
          end
          create_table_string = create_table_string + ",`" + key + "_" + key2 + "` " + type
        end
      end    
    end
    create_table_string = create_table_string + ")"
    #puts "field_string: #{field_string}"
    #puts "value_string: #{value_string}"
    #puts "prep_value: #{prep_value}"
    #puts "create_table_string:  #{create_table_string}"
   
    sql = start_sql + field_string + mid_sql + prep_value + end_sql
    #puts " sql: #{sql}"
    if $disable_record_feed
      puts "$disable_record_feed set true so no data saved to mysql for record_feed data."
      return
    end
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

def check_float(data)
  return true if Float(data) rescue false
end

def record_order_book(params)
  #params["sell_asset"] = "USD"
  #params["sell_issuer"] = "GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF"
  #params["buy_asset_type"] = "native"
  #params["buy_asset"] = "THB"
  #params["buy_issuer"] = "GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF"
  #params["min_liquid"] = 0
  #puts "book_horizon params: #{params}"
  result = Utils.get_order_book_horizon(params)
  if result["bids"].nil? && result["asks"].nil?
    puts "no bids asks for asset, will not record"
    return nil
  end
  #puts "input to record_order_book: #{result}"
  result2 = orderbook_convert_str_to_polo(result)
  #puts "result2: #{result2}"
  result3 = convert_polo_to_liquid(result2,params["min_liquid"])
  #puts "recorded to mysql db: #{result3}"
  record_ticker(result3)
end

def record_order_book_set(params)
  puts "record_order_book_set start"
  params_rec = {}
  params_rec["min_liquid"] = params["min_liquid"]
  params_rec["sell_asset"] =   params["sell_currency"]
  params_rec["sell_issuer"] =  params["sell_issuer"]
  params_rec["buy_asset"] =   params["buy_currency"]
  params_rec["buy_issuer"] =  params["buy_issuer"]
  #puts "params A: #{params_rec}"
  #puts "record data"
  #begin
    record_order_book(params_rec)
  #rescue
   # puts " record_order_book failed not sure why, check mysql user and passwords"
  #end

  params_rec["sell_asset"] =   params["buy_currency"]
  params_rec["sell_issuer"] =  params["buy_issuer"]
  params_rec["buy_asset"] =   params["sell_currency"]
  params_rec["buy_issuer"] =  params["sell_issuer"]
  #puts "params B: #{params_rec}"
  #puts "record data"
  #begin
    record_order_book(params_rec)
  #rescue
   # puts " record_order_book failed not sure why, check mysql user and passwords"
  #end
end

def record_order_book_list(params)
   backup_params = params.clone
   params["order_book_pairs"].each { |pair|
      puts "pair: #{pair}"
      params["sell_currency"] = pair[0]
      params["buy_currency"] = pair[1]
      if !pair[2].nil?    
        params["sell_issuer"] = pair[2]
        params["buy_issuer"] = pair[2]
      end
      if !pair[3].nil?
        params["buy_issuer"] = pair[3]
      end
      #params["amount"] = pair[2]
      #puts "params: #{params}"
      record_order_book_set(params)
      params = backup_params.clone
    }
end

def send_tx_array(params,array=nil)
  puts "send_tx_array"
  #begin
  if params["disable_trade"] == "true" || params["disable_trade"] == true
    puts "disable_trade is set true will not be trading b"
    return
  end
  if array.nil?
    if params["tx_array_in"].length == 0
       puts "tx_array length 0, nothing to send, nothing done"
       return
    end
    tx_all =  Utils.tx_merge(params["tx_array_in"])
  else
    if array.length == 0
       puts "tx_array length 0, nothing to send, nothing done"
       return
    end
    tx_all =  Utils.tx_merge(array)
  end
  b64 = tx_all.to_envelope(params["trader_account"]).to_xdr(:base64)
  puts "sending batch of tx"
  #result = Utils.send_tx(b64)
  result = send_tx(b64)
  #puts ("sent_tx result: #{result}") 
      
  if !(result["decoded_error"].nil?)
    puts "must have error must have cross trade clear offers"
    puts ("decoded_error.nil?: #{result["decoded_error"].nil?}") 
    puts ("decoded_error: #{result["decoded_error"]}")
    delete_offers(params["trader_account"],"all")
  end
  #rescue
  #  puts "send_tx_array failed,  try again next loop"
  #end
end

def trade_funtion_loop(params,backup_params)
  #begin  
    
  params["next_seq"] = Utils.next_sequence(params["trader_account"])
  #params["next_seq"] = 1

  params["traded"] = []

  if params["disable_trade_peg"] != true
    params["tx_array_in"] = []
    params["tx_buy_array_in"] = []
    params["tx_sell_array_in"] = []
    params["trade_peg_pairs"].each { |pair|
      puts "pair length #{pair.length}"
      params["sell_currency"] = pair[0]
      params["peg_base_asset"] = pair[1]
      params["peg_multiple"] = pair[2]
      params["buy_currency"] = pair[3]      
      params["amount"] = pair[4]
      if !pair[5].nil?
        params["sell_issuer"] = pair[5]
      end
      if !pair[6].nil?
        params["buy_issuer"] = pair[6]
      end    
      
      trade_peg(params)
    }
    puts "tx_array_in length #{params["tx_array_in"].length}"
    puts "tx_array_in[0]: #{params["tx_array_in"][0]}"

  end

  if params["trade_pairs"].nil? 
    puts " trade_pairs nil will trade params[sell_currency]  instead (if not also nil)"
    if !params["sell_currency"].nil?
      trade_offer_set(params)
      record_order_book_set(params)
    end
  else
    
    #params = backup_params.clone
    #params["tx_array_in"] = []
    #params["tx_buy_array_in"] = []
    #params["tx_sell_array_in"] = []
    params["market_ask_price"] = nil

    params["trade_pairs"].each { |pair|
      puts "pair: #{pair}"
      params["sell_currency"] = pair[0]
      params["buy_currency"] = pair[1]
      params["amount"] = pair[2]
      if !pair[3].nil?    
        params["sell_issuer"] = pair[3]
      else
        params["sell_issuer"] = backup_params["sell_issuer"].clone
      end
      if !pair[4].nil?
        params["buy_issuer"] = pair[4]
      else 
        params["buy_issuer"] = backup_params["buy_issuer"].clone
      end
      #puts "params: #{params}"
      trade_offer_set(params)
    }

    puts "traded: #{params["traded"]}"

    if params["tx_mode"] == true
      puts "tx_array_in length #{params["tx_array_in"].length}"
      puts "tx_array_in[0]: #{params["tx_array_in"][0]}"
      if params["dual_trader"] == true
        if params["disable_delete_offers"] != true
          puts "delete_offers disabled, nothing done"
          delete_offers(params["trader_account_buy"], params["traded"])
          delete_offers(params["trader_account_sell"], params["traded"])
        end 
        params["trader_account"] = params["trader_account_sell"]
        send_tx_array(params,params["tx_sell_array_in"])
        params["trader_account"] = params["trader_account_buy"]
        send_tx_array(params,params["tx_buy_array_in"])               
      else
        if params["disable_delete_offers"] != true
          puts "delete_offers disabled, nothing done"
          #delete_offers(params["trader_account"], params["traded"])
        end        
        send_tx_array(params)
      end
    end
    #params = backup_params.clone
    #puts "params at rec: #{params}"
    #record_order_book_list(params)
    #params = backup_params.clone
  end
  
 #rescue
 # puts "something failed on this loop, will try again later"
  #delete_offers(params["trader_account"],"all")
 #end
 # params["min_diff_margin_mult_trade"] = backup_params["min_diff_margin_mult_trade"]
end



#https://poloniex.com/public?command=returnOrderBook&currencyPair=BTC_STR
# params["trader_account"] public addressId = GBROAGZJGZSSQWJIIH2OHOPQUI4ZDZL4MOH7CSWLQBDGWBYDCDQT7CU4

  
  #params["trade_pairs"] = [["USD","THB",10],["BTC","XLM",0.01]]
  #params["trade_pairs"] = [["USD","THB",10]]
  #params["trader_account"] = Stellar::KeyPair.from_seed(Utils.configs["trader_account"])
  #params["trader_account_sell"] = params["trader_account"]
  #params["trader_account_buy"] = params["trader_account"]
  #params["sell_issuer"] = "GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF"
  #params["sell_currency"] = "USD"
  #params["buy_issuer"] = "GAX4CUJEOUA27MDHTLSQCFRGQPEXCC6GMO2P2TZCG7IEBZIEGPOD6HKF"
  #params["buy_currency"] = "THB"
  #params["peg_base_asset"] = "THB"
  #params["peg_multiple"] = 40
  #params["amount"] = 100
  #params["profit_margin"] = 0.5
  #params["exchange_feed_key"] = Utils.configs["openexchangerates_key"]  
  #params["min_liquid"] = 0
  #params["loop_time_sec"] = 3600
  #params["feed_poloniex"] = ["BTC","XLM"]
  #params["feed_other"] = ["THB","USD"]
  #params["trade_single_side_pair"] = false  ; not supported yet
  #params["tx_mode"] = true  ; is set true will run all transactions pairs as a single transaction , default is false
    # if this works it should be better and faster
  #params["disable_trade"] = true
  #params["disable_record_ticker"] = true
  #params["disable_record_feed"] = true
  #params["disable_delete_offers"] = true
  #params["disable_trade_peg"] = true  
  params["tx_array_in"] = []
  params["tx_buy_array_in"] = []
  params["tx_sell_array_in"] = []
  params["market_ask_price"] = nil

puts "started infinite loop on auto trader, hit ctl-c to exit"
puts "trade_pairs: #{params["trade_pairs"]}"
puts "trader_account: #{ params["trader_account"].address}"
puts "sell_currency: #{params["sell_currency"]}"
puts "buy_currency: #{params["buy_currency"]}"
puts "sell_issuer: #{params["sell_issuer"]}"
puts "buy_issuer:  #{params["buy_issuer"]}"
puts "profit_margin: #{ params["profit_margin"]["default"]}"
puts "amount: #{params["amount"]}"
puts "min_liquid: #{params["min_liquid"]}"

backup_params = params.clone
#puts "backup_params: #{backup_params}"





    puts "trading starts now" 
    delete_offers(params["trader_account"],"all")
    sleep 7
    puts "start trade_funtcion_loop"
    trade_funtion_loop(params,backup_params)
    puts "trade_function_loop exited"

    







