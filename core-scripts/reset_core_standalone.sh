COREPATH='/home/sacarlson/github/stellar/buhrmi/network/src'
#COREPATH='/home/sacarlson/github/stellar/fred/stellar-core/src'
#CONFIGFILE='./stellar-core_standalone.cfg'
CONFIGFILE='./stellar-core_testnet.cfg'
rm ./stellar.db 
rm -r ./buckets
rm -r ./tmp
rm ./stellar.db-shm
rm ./stellar.db-wal
rm ./stellar-core.log
$COREPATH/stellar-core -conf $CONFIGFILE -newdb
sleep 3
$COREPATH/stellar-core -conf $CONFIGFILE -newhist vs
sleep 1
$COREPATH/stellar-core -conf $CONFIGFILE -forcescp
sleep 1
$COREPATH/stellar-core -conf $CONFIGFILE

