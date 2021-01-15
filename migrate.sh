#!/bin/sh
set -e

#InternalScriptParameter
devBranch=develop
masterBranch=master
releaseBranch="release-tmp"
versionFile="pom.xml"

#Read level from input
versionLevel=$1

# Validate input
if [ -z $versionLevel ]; then 
    # Set a default
    versionLevel="patch"
else
    if [ $versionLevel != "minor" ] && [ $versionLevel != "major" ] && [ $versionLevel != "patch" ]; then
        echo "Invalid input"
        exit 1
    fi
fi
echo "Going to increase ${versionLevel}Version!"

# create the release branch from the -develop branch
git checkout -b $releaseBranch $devBranch
 
newVersionMvnParameter=
if [ $versionLevel = "patch" ] ; then
    newVersionMvnParameter="\${parsedVersion.majorVersion}.\${parsedVersion.minorVersion}.\${parsedVersion.nextIncrementalVersion}"
fi

if [ $versionLevel = "minor" ] ; then
    newVersionMvnParameter="\${parsedVersion.majorVersion}.\${parsedVersion.nextMinorVersion}.\${parsedVersion.incrementalVersion}"
fi

if [ $versionLevel = "major" ] ; then
    newVersionMvnParameter="\${parsedVersion.nextMajorVersion}.\${parsedVersion.minorVersion}.\${parsedVersion.incrementalVersion}"
fi

mvn build-helper:parse-version versions:set -q -DnewVersion=$newVersionMvnParameter versions:commit

newVersion=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)


# commit version number increment
git commit -am "Incrementing Version to $newVersion"
 
# merge release branch with the new version number into master
git checkout $masterBranch
git merge --no-ff --no-edit $releaseBranch
 
# create tag for new version from -master
git tag $newVersion
 
# merge release branch with the new version number back into develop
git checkout $devBranch
git merge --no-ff --no-edit $releaseBranch
 
# remove release branch
git branch -d $releaseBranch

git push origin master
git push origin develop