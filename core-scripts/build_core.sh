#!/bin/bash
#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
# this will git fetch all the latest commits of stellar-core, checkout desired commit and compile it
# if the commit hash already exsists then it will just create a binary link to the runner depending on "live" or "testnet"
# the first param is the commit hash to checkout and compile, if set to "auto" it will 
# find what version horizon is running with 2nd param "live" or "testnet" to get the version of that horzion site
# if no param is entered it will just build presenty checked out version of stellar-core in src
# 2nd param will also update the binary link to what will be running on "live" or "testnet"
# 2nd param can be ether "testnet" or "live" and will update the bin link file pointed to at TESTNET or LIVE path
# for the json parse function to work in "auto" you will need to sudo apt-get install jq
#   now that this just makes symbolic links to already existing builds this could be run in cron on a regular basis to keep updated
#   the other option is on sync fail we run this in my ruby stellar-core state checker that is already writen

#corepath is the path of the source code to update and compile 
COREPATH='/home/sacarlson/github/stellar/stellar-core'
#testnet path of were you plan to keep a link of the binary stellar-core that will be run for stellar test net
TESTNET='/home/sacarlson/github/stellar/stellar_utility/stellar-db-testnet'
# live is the path of where you plan to keep a link of the binary stellar-core that will be run for stellar live net
LIVE='/home/sacarlson/github/stellar/stellar_utility/stellar-live'

if [ "$1" = "auto" ]; then
  if [ "$2" = "live" ]; then
    echo "live will but updated compiled and linked"
    VERSION=`curl 'https://horizon.stellar.org' | jq -r '.core_version'`
    LIVETEST="live"
  else
    echo "testnet will be updated compiled and linked"    
    VERSION=`curl 'https://horizon-testnet.stellar.org' | jq -r '.core_version'`
    LIVETEST="testnet"
  fi
  echo "complete"
  echo $VERSION
  VERSION=`echo $VERSION | sed -n 's/^.*g//p'`
else
  VERSION=$1
  LIVETEST=$2
fi
echo $VERSION
echo $LIVETEST
echo $TESTNET/stellar-core_bin_$VERSION
if [ ! -f $TESTNET/stellar-core_bin_$VERSION ]; then
  echo "this version not exist so will build one"
  cd $COREPATH
  git fetch --all

  if [ "$VERSION" != "" ]; then
    git checkout $VERSION
    if [ $? -ne 0 ]; then
      echo "commit $1 not found, will exit now.  try git log to find what is available to checkout"
      exit -1
    fi
  fi
  echo "start config and compile, this takes some time"
  ./autogen.sh
  ./configure
  make
  if [ $? -ne 0 ]; then
    echo "make failed will exit and change nothing"
    exit -1
  else
    cp $COREPATH/src/stellar-core $TESTNET/stellar-core_bin_$VERSION
  fi
else
  echo "this version already exist so just setup links"

  if [ "$LIVETEST" = "live" ]; then
    echo "will copy bin to live and link"
    rm -f $LIVE/stellar-core
    ln -s $TESTNET/stellar-core_bin_$VERSION $LIVE/stellar-core
  fi
  if [ "$LIVETEST" = "testnet" ]; then
    echo "will copy bin to testnet and link"
    rm -f $TESTNET/stellar-core
    ln -s $TESTNET/stellar-core_bin_$VERSION $TESTNET/stellar-core
  fi
fi
