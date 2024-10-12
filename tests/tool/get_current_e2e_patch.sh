#!/bin/sh

set -e

if [ -z "$1" ]
  then
    echo "No argument supplied. Pass the firebase package name to extract the commit from."
    exit 1
fi

FIREBASE_PACKAGE_NAME="$1"

ROOT_DIR=$(realpath .)
FLUTTERFIRE_REPO_E2E_PATH="$ROOT_DIR"/flutterfire_repo/tests
DART_REPO_E2E_PATH="$ROOT_DIR"

tool/clone_base_impl.sh $FIREBASE_PACKAGE_NAME


#### Create diff of e2e files #####
rm -rf diff
mkdir diff

PATCH_PATH="$ROOT_DIR"/patches/e2e-$FIREBASE_PACKAGE_NAME.patch

pushd diff
cp -r "$FLUTTERFIRE_REPO_E2E_PATH/integration_test/$FIREBASE_PACKAGE_NAME" flutterfire
cp -r "$DART_REPO_E2E_PATH/integration_test/$FIREBASE_PACKAGE_NAME" dart

# Update the modified date of all files to be diffed, so that the dates remain
# the same in the git history
find . -exec touch -m -d '1/1/2024' {} +

rm "$PATCH_PATH" || true
diff -x "flutterfire_repo" -ur flutterfire dart > "$PATCH_PATH" || true
popd
rm -rf diff
###################################
