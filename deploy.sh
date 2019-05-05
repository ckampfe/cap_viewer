#!/usr/bin/env sh


PROJECT="cap_viewer"

# see lib/mix/tasks/app/version.ex
VERSION=$(mix app.version)
echo "--------------------------------------------------"
echo "Upgrading to $VERSION"
echo "--------------------------------------------------"
echo

MIX_ENV=prod mix compile

MIX_ENV=prod mix release --env=prod --upgrade

echo "--------------------------------------------------"
echo "Built release $VERSION"
echo "--------------------------------------------------"
echo

mkdir -p "deploy/releases/$VERSION"
DEPLOY_TARGET="deploy/releases/$VERSION/"
cp "_build/prod/rel/$PROJECT/releases/$VERSION/$PROJECT.tar.gz" $DEPLOY_TARGET

echo "--------------------------------------------------"
echo "Copied release to deploy target directory: $DEPLOY_TARGET"
echo "--------------------------------------------------"

PORT=5000 deploy/bin/$PROJECT upgrade $VERSION
