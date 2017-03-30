BUILD_DIR=$1
NAMESPACE=$2
NUGET_API_KEY=$3
IS_NEW_RELEASE=$4
VERSION=$5

echo "BUILD_DIR=$BUILD_DIR"
echo "NAMESPACE=$NAMESPACE"
echo "IS_NEW_RELEASE=$IS_NEW_RELEASE"
echo "VERSION=$VERSION"

if [ ! "$IS_NEW_RELEASE" = "true" ]
then
	echo "Skipping nuget publish"
	exit 0
fi

# CD to build dir
cd $BUILD_DIR

# Write nuspec file
echo '<?xml version="1.0" encoding="utf-8"?>'\
'<package xmlns="http://schemas.microsoft.com/packaging/2010/07/nuspec.xsd">'\
'	<metadata>'\
"		<id>$NAMESPACE</id>"\
'		<title>PureCloud API SDK</title>'\
'		<summary>A .NET library to interface with the PureCloud Public API</summary>'\
'		<projectUrl>https://github.com/MyPureCloud/platform-client-sdk-dotnet</projectUrl>'\
'		<copyright>Copyright © Genesys 2017</copyright>'\
'		<licenseUrl>https://github.com/MyPureCloud/platform-client-sdk-dotnet/blob/master/LICENSE</licenseUrl>'\
'		<iconUrl>https://raw.githubusercontent.com/MyPureCloud/platform-client-sdk-dotnet/master/ininlogo64.png</iconUrl>'\
'		<tags>genesys purecloud pure cloud public platform api sdk</tags>'\
'		<language>en-us</language>'\
"		<version>$VERSION</version>"\
'		<authors>Genesys Developer Evangelists</authors>'\
'		<requireLicenseAcceptance>false</requireLicenseAcceptance>'\
'		<description>PureCloud Platform Client SDK</description>'\
'		<dependencies>'\
'			<dependency id="Newtonsoft.Json" version="9.0.1" />'\
'			<dependency id="RestSharp" version="105.2.3" />'\
'		</dependencies>'\
'	</metadata>'\
'	<files>'\
'		<file src="ININ.PureCloudApi.dll" target="lib/ININ.PureCloudApi.dll" />'\
'		<file src="ININ.PureCloudApi.xml" target="lib/ININ.PureCloudApi.xml" />'\
'	</files>'\
'</package>' > $BUILD_DIR/bin/$NAMESPACE.nuspec

# Pack nuspec
mono nuget.exe pack $BUILD_DIR/bin/$NAMESPACE.nuspec -Verbosity detailed

# --WORKAROUND--
# There is an issue with mono/nuget and the nupkg file. Probably this: https://github.com/NuGet/Home/issues/2833
# This workaround simply unzips the nupkg file and rezips it. I think this makes it use '/' instead of '\'.
mkdir package
unzip $NAMESPACE.$VERSION.nupkg -d package
cd package
zip -r $NAMESPACE.$VERSION.repack.nupkg *
cd $WORKSPACE/repo
cp package/$NAMESPACE.$VERSION.repack.nupkg $NAMESPACE.$VERSION.repack.nupkg

# Publish to nuget
mono nuget.exe push $NAMESPACE.$VERSION.repack.nupkg $NUGET_API_KEY -source "https://www.nuget.org" -Verbosity detailed
