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
    wget -nv "$DOWNLOAD_URL" -O "$TMP_FILE"
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

function live_data() {

  NETWORK_NAME=$1
  DOWNLOAD_BASE_URL=$2 #Make sure it doesn't end with /
  ROOT_CHECKPOINT_EXPECTED_SHA256=$3

  INDEX_DIR="$DATA_DIR/live"
  ROOT_CHECKPOINT_FILE="$INDEX_DIR/root.checkpoint"
  PUBLIC_ROOT_INFO_DIR="$INDEX_DIR/public-root-information"
  NODE_INFOS_FILE="$PUBLIC_ROOT_INFO_DIR/node-infos.pub.json"
  ROOT_PROTOCOL_STATE_SNAPSHOT_FILE="$PUBLIC_ROOT_INFO_DIR/root-protocol-state-snapshot.json"

  ROOT_CHECKPOINT_DOWNLOAD_URL="$DOWNLOAD_BASE_URL/root.checkpoint"
  NODE_INFOS_DOWNLOAD_URL="$DOWNLOAD_BASE_URL/public-root-information/node-infos.pub.json"
  ROOT_PROTOCOL_STATE_SNAPSHOT_DOWNLOAD_URL="$DOWNLOAD_BASE_URL/public-root-information/root-protocol-state-snapshot.json"

  echo "Checking Live $NETWORK_NAME data"

  if [ ! -d "$INDEX_DIR" ]; then
      TMP_FILE=$(mktemp)
      wget -nv "$ROOT_CHECKPOINT_DOWNLOAD_URL" -O "$TMP_FILE"
      DOWNLOADED_SHA256=$(sha256sum "$TMP_FILE" | cut -d' ' -f1)

      if [ "$DOWNLOADED_SHA256" != "$ROOT_CHECKPOINT_EXPECTED_SHA256" ]; then
        echo "Live $NETWORK_NAME downloaded root.checkpoint checksum differs"
        exit 1
      fi

      mv "$TMP_FILE" "$ROOT_CHECKPOINT_FILE"

      # public root info
      mkdir "$PUBLIC_ROOT_INFO_DIR"

      wget -nv "$NODE_INFOS_DOWNLOAD_URL" -O "$NODE_INFOS_FILE"
      wget -nv "$ROOT_PROTOCOL_STATE_SNAPSHOT_DOWNLOAD_URL" -O "$ROOT_PROTOCOL_STATE_SNAPSHOT_FILE"

      echo "Live $NETWORK_NAME bootstrap data downloaded"

    else
      echo "Live $NETWORK_NAME bootstrap data already exists"
    fi

}


#mainnet_data "mainnet-3" "https://storage.googleapis.com/flow-genesis-bootstrap/dps/mainnet3-snapshot.gz" "d888cefcf1d390742c38be0efdfdcdbe4feb13c5900ed9463a0dc954078ff19d"
#mainnet_data "mainnet-4" "https://storage.googleapis.com/flow-genesis-bootstrap/dps/mainnet4-snapshot.gz" "c578baad49dd8058eac38dcdcc858d1e15fb9dd21af655366f8679ef5dc6f84d"
#mainnet_data "mainnet-5" "https://storage.googleapis.com/flow-genesis-bootstrap/dps/mainnet5-snapshot.gz" "2f20659821264ca0b05a608b48c1118e06bc2de3a87bc707a1295580e2bf34b5"
#mainnet_data "mainnet-6" "https://storage.googleapis.com/flow-genesis-bootstrap/dps/mainnet6-snapshot.gz" "198a38ca393e7feb7bd66a9dc23579e6c0ebd6470a76c3bfc32e13b3e64ab690"
#mainnet_data "mainnet-7" "https://storage.googleapis.com/flow-genesis-bootstrap/dps/mainnet7-snapshot.gz" "71df712108ca37cc03bfd7bb082195d445d13b45c3cb936778776683617b10cf"
live_data "canary-8v2"  "https://storage.googleapis.com/flow-genesis-bootstrap/canary-8v2" "1158db830b9addbc55c4e5248e427fca7e06ffb05714276fe6f8fe97e747b226"

/usr/bin/supervisord -c /supervisord.conf