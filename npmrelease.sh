#!/bin/sh
set -e

# InternalScriptParameter
devBranch=develop
masterBranch=master
releaseBranch="release-tmp"
pathToPom="pom.xml"
remoteName="origin"

# Read level from input
versionLevel=$1

# Validate input
if [ -z $versionLevel ]; then
    # Set a default
    versionLevel="patch"
else
    if [ $versionLevel != "minor" ] && [ $versionLevel != "major" ] && [ $versionLevel != "patch" ]; then
        echo "######### Invalid input: Please use 'patch' or 'minor' or 'major'!"
        echo "######### No input defaults to 'patch'."
        exit 1
    fi
fi

# # Check or local changes
LocalStatus=$(git status --short)
if [ -z "$LocalStatus" ] ; then
    echo "######### No local changes! Proceeding.."
else
    echo "######### You have local changes.\n######### Please commit or revert them before you do a release!"
    echo "######### Use 'git status' to see them."
    exit 1
fi

# Check or local commits
git fetch
echo "######### Fetched remote state"
LocalCommits=$(git cherry $remoteName/$devBranch $devBranch)
if [ -z "$LocalCommits" ] ; then
    echo "######### No local commits! Proceeding.."
else
    echo "######### You have local commits which are not on the remote yet."
    echo "######### Please push them or reset your branch back to the remote state!"
    echo "######### Use 'git cherry $remoteName/$devBranch $devBranch' to see the commits."
    echo "######### Use 'git push' to push and 'git reset --hard $remoteName/$devBranch' to revert back to remote state."
    exit 1
fi

# Handle remote commits
RemoteCommits=$(git cherry $devBranch $remoteName/$devBranch)
if [ -z "$RemoteCommits" ] ; then
    echo "######### No remote commits! Proceeding.."
else
    echo "######### There are new commits on the remote branch. Going fast-forward..."
    git merge --ff-only
fi

echo "######### Going to increase ${versionLevel}Version!"

# Create the release branch from the develop branch
git checkout -b $releaseBranch $devBranch
echo "######### Created release branch $releaseBranch!"

npm version $versionLevel

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
git push $remoteName $masterBranch
git push $remoteName $devBranch
echo "######### Published changes"
echo "######### Finished successful"