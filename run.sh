#!/bin/bash

# fail if anything fails
set -e

DATA_DIR="/data"

function mainnet_data() {

  MAINNET_NAME=$1
  DOWNLOAD_URL=$2
  EXPECTED_SHA256=$3

  INDEX_DIR="$DATA_DIR/$MAINNET_NAME"

  echo "Checking $MAINNET_NAME data"
  if [ ! -d "$INDEX_DIR" ]; then
    TMP_FILE=$(mktemp)
    wget "$DOWNLOAD_URL" -O "$TMP_FILE"
    DOWNLOADED_SHA256=$(sha256sum "$TMP_FILE" | cut -d' ' -f1)

    if [ "$DOWNLOADED_SHA256" != "$EXPECTED_SHA256" ]; then
      echo "$MAINNET_NAME downloaded index checksum differs"
      exit 1
    fi

    /bin/restore-index-snapshot -c gzip -i "$INDEX_DIR" < "$TMP_FILE"
    echo "$MAINNET_NAME data restored"

    rm "$TMP_FILE"
  else
    echo "$MAINNET_NAME data already exists"
  fi

}

#mainnet_data "mainnet-3" "https://storage.googleapis.com/flow-genesis-bootstrap/dps/mainnet3-snapshot.gz" "d888cefcf1d390742c38be0efdfdcdbe4feb13c5900ed9463a0dc954078ff19d"
#mainnet_data "mainnet-4" "https://storage.googleapis.com/flow-genesis-bootstrap/dps/mainnet4-snapshot.gz" ""
mainnet_data "mainnet-5" "https://storage.googleapis.com/flow-genesis-bootstrap/dps/mainnet5-snapshot.gz" "2f20659821264ca0b05a608b48c1118e06bc2de3a87bc707a1295580e2bf34b5"


/usr/bin/supervisord -c /supervisord.conf