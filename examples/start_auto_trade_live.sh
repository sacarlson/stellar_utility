
cd /home/sacarlson/github/stellar/stellar_utility/multi-sign-server
bundle exec ruby ./multi-sign-server.rb &

sleep 5

cd /home/sacarlson/github/stellar/stellar_utility/examples
bundler exec ruby ./auto_trader_live.rb
