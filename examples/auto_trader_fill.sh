/bin/bash -lc 'cd /home/sacarlson/github/stellar/stellar_utility/examples; /home/sacarlson/.rbenv/shims/bundler exec ruby ./auto_trader_live_fill.rb &>> /home/sacarlson/logs/auto_trader_fill.log'
#to start: /home/sacarlson/github/stellar/stellar_utility/examples/auto_trader_fill.sh
# the above is needed to run from cron
# example crontab line: 00 8,20 * * * /home/sacarlson/github/stellar/stellar_utility/examples/auto_trader_fill.sh
