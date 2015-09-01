#configure stellar_utilities
rm ./stellar_utilityies.cfg
ln -sf ./stellar_utilities_postgres.cfg ./stellar_utilities.cfg

#start core
mate-terminal --working-directory=/home/sacarlson/github/stellar/stellar_utility/stellar-db-postgres -e ./stellar-db-postgres/start_stellar_core_testnet.sh

#start horizon
mate-terminal --working-directory=/home/sacarlson/github/stellar/horizon -e /home/sacarlson/github/stellar/horizon/start_horizon.sh
