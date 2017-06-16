NPM_AUTH_TOKEN=$1
BUILD_DIR=$2
IS_NEW_RELEASE=$3

echo "BUILD_DIR=$BUILD_DIR"
echo "IS_NEW_RELEASE=$IS_NEW_RELEASE"


if [ ! "$IS_NEW_RELEASE" = "true" ]
then
	echo "Skipping npm deploy"
	exit 0
fi

cd $BUILD_DIR

echo "ca=null
//registry.npmjs.org/:_authToken=${NPM_AUTH_TOKEN}" > ./.npmrc

npm publish