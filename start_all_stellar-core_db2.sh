#configure stellar_utilities

ln -sf ./stellar_utilities_db2.cfg ./stellar_utilities.cfg

#start core
mate-terminal --working-directory=/home/sacarlson/github/stellar/stellar_utility/stellar-db2 -e ./start_stellar_core_testnet.sh

#start horizon
#mate-terminal --working-directory=/home/sacarlson/github/stellar/horizon -e /home/sacarlson/github/stellar/horizon/start_horizon.sh
