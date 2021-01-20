#!/bin/sh
set -e

# InternalScriptParameter
devBranch=develop
masterBranch=master
releaseBranch="release-tmp"
pathToPom="pom.xml"

# Read level from input
versionLevel=$1

# Validate input
if [ -z $versionLevel ]; then 
    # Set a default
    versionLevel="patch"
else
    if [ $versionLevel != "minor" ] && [ $versionLevel != "major" ] && [ $versionLevel != "patch" ]; then
        echo "Invalid input: Please use 'patch' or 'minor' or 'major'!\nNo input defaults to 'patch'."
        exit 1
    fi
fi
echo "######### Going to increase ${versionLevel}Version!"

# Create the release branch from the develop branch
git checkout -b $releaseBranch $devBranch
echo "######### Created release branch $releaseBranch!"

# Construct Maven Command parameter to increase version on correct level
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

# Increase Version in pom.xml
mvn build-helper:parse-version versions:set -q -DnewVersion=$newVersionMvnParameter versions:commit
echo "######### Updated pom.xml"

# Read new Version for tag and commit message
newVersion=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)
echo "######### New version is $newVersion"

# Commit
git commit -o $pathToPom -m "Incrementing Version to $newVersion"
echo "######### Commit changes to pom.xml on release branch"

# Merge release branch with the new version into master
git checkout $masterBranch
git merge --no-ff --no-edit $releaseBranch
echo "######### Merge to master"

# Create tag from master
git tag $newVersion
echo "######### Created Release tag on Master"

# Merge release branch with back into develop
git checkout $devBranch
git merge --no-ff --no-edit $releaseBranch
echo "######### Merged to develop"

# Remove release branch
git branch -d $releaseBranch
echo "######### Deleted release branch"

# Publish changes
git push origin master
git push origin develop
echo "######### Published changes"
echo "######### Finished successful"