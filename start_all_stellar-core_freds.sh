#configure stellar_utilities

ln -sf ./stellar_utilities_fred.cfg ./stellar_utilities.cfg

#start core
mate-terminal --working-directory=/home/sacarlson/github/stellar/stellar_utility/stellar-db_fred -e ./start_stellar_core.sh

#start horizon
#mate-terminal --working-directory=/home/sacarlson/github/stellar/horizon -e /home/sacarlson/github/stellar/horizon/start_horizon.sh
