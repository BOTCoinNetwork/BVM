#!/bin/bash

# This script creates the config.toml configuration file for babble 

set -e

N=${1:-4}
DEST=${2:-"conf"}

l=$((N-1))

PFILE=$DEST/babble_config.toml
echo "[eth]" > $PFILE 
echo "db = \"/eth.db\"" >> $PFILE
echo "[babble]" >> $PFILE 
echo "store_type = \"inmem\"" >> $PFILE

for i in $(seq 0 $l) 
do
	dest=$DEST/node$i
	cp $DEST/babble_config.toml $dest/config.toml
	echo "node_addr = \"node$i:1337\"" >> $dest/config.toml
done