#!/bin/sh

set -e

if [ -z "$1" ]
  then
    echo "No argument supplied. Pass the firebase package name to extract the commit from."
    exit 1
fi

FIREBASE_PACKAGE_NAME="$1"

ROOT_DIR=$(realpath .)
DART_E2E_BAK="$ROOT_DIR"/e2e-$FIREBASE_PACKAGE_NAME.bak
FLUTTERFIRE_REPO_PATH="$ROOT_DIR"/flutterfire_repo
DART_REPO_E2E_PATH="$ROOT_DIR"/integration_test/"$FIREBASE_PACKAGE_NAME"

rm -rf "$DART_E2E_BAK"
mv "$DART_REPO_E2E_PATH" "$DART_E2E_BAK"

tool/clone_base_impl.sh $FIREBASE_PACKAGE_NAME

# Start with the base e2e from flutter fire package implementation
cp -r "$FLUTTERFIRE_REPO_PATH"/tests/integration_test/"$FIREBASE_PACKAGE_NAME" "$DART_REPO_E2E_PATH"

pushd "$DART_REPO_E2E_PATH"
# Apply patch ignoring first level (p1) from the diff (electric and dart subfolders)
# --merge is used so that it creates a "git compatible" merge conflict
# --no-backup-if-mismatch is used so that it doesn't create .orig files
patch -p1 --merge --no-backup-if-mismatch < "$ROOT_DIR"/patches/e2e-$FIREBASE_PACKAGE_NAME.patch
popd
