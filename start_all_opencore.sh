#configure stellar_utilities
rm ./stellar_utilityies.cfg
ln -sf ./stellar_utilities_opencore.cfg ./stellar_utilities.cfg

#start core
mate-terminal --working-directory=/home/sacarlson/github/stellar/stellar_utility/stellar-db-opencore -e ./start_stellar_core_opencore.sh

#start horizon
mate-terminal --working-directory=/home/sacarlson/github/stellar/horizon -e /home/sacarlson/github/stellar/horizon/start_horizon_opencore.sh
