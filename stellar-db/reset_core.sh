mv ./stellar.db ./stellar.db.org2
/home/sacarlson/github/stellar/stellar-core/src/stellar-core -conf ./stellar.config -newdb

sleep 3
/home/sacarlson/github/stellar/stellar-core/src/stellar-core -conf ./stellar.config -newhist vs
sleep 1
/home/sacarlson/github/stellar/stellar-core/src/stellar-core -conf ./stellar.config -forcescp
sleep 1
/home/sacarlson/github/stellar/stellar-core/src/stellar-core -conf ./stellar.config

