COREPATH='/home/sacarlson/github/stellar/stellar-core/src'
#CONFIGFILE='./stellar-core_standalone.cfg'
CONFIGFILE='./stellar-core_testnet.cfg'
MY_PATH="`dirname \"$0\"`"              # relative
MY_PATH="`( cd \"$MY_PATH\" && pwd )`"  # absolutized and normalized
if [ -z "$MY_PATH" ] ; then
  # error; for some reason, the path is not accessible
  # to the script (e.g. permissions re-evaled after suid)
  exit 1  # fail
fi
#echo "$MY_PATH"
cd $MY_PATH

$COREPATH/stellar-core -conf $CONFIGFILE -forcescp
sleep 3
$COREPATH/stellar-core -conf $CONFIGFILE

