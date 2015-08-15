MY_PATH="`dirname \"$0\"`"              # relative
MY_PATH="`( cd \"$MY_PATH\" && pwd )`"  # absolutized and normalized
if [ -z "$MY_PATH" ] ; then
  # error; for some reason, the path is not accessible
  # to the script (e.g. permissions re-evaled after suid)
  exit 1  # fail
fi
#echo "$MY_PATH"
cd $MY_PATH
#stellar-core -conf ./stellar.config
/home/sacarlson/github/stellar/stellar-core/src/stellar-core -conf ./stellar.config -forcescp
sleep 3
/home/sacarlson/github/stellar/stellar-core/src/stellar-core -conf ./stellar.config

