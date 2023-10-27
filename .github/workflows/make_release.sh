#!/bin/bash

# set -x

# make a new relaase
# "make_release 1.2.3 main" in order to create a git tag 1.2.3 on branch main
# "make_release --patch master" to increase the patch number of the latest tag and create a tag on branch main for the new version
# "make_release --minor master" to increase the minor number of the latest tag and create a tag on branch main for the new version
# "make_release --major master" to increase the major number of the latest tag and create a tag on branch main for the new version

function get_latest_tag {
  git fetch --tags
  latest_tag=$(git describe --tags $(git rev-list --tags --max-count=1))
  echo $latest_tag
}

function increment_version {
  local version=$1
  local field=$2
  local fields=($(echo $version | tr '.' ' '))
  fields[$field]=$((fields[$field]+1))
  
  if [[ $field -eq 1 ]]; then
    fields[2]=0
  elif [[ $field -eq 0 ]]; then
    fields[1]=0
    fields[2]=0
  fi
  
  new_version="${fields[0]}.${fields[1]}.${fields[2]}"
  echo $new_version
}

function make_tag {
  local version=$1
  local branch=${2:-$(git branch --show-current)}
  git checkout $branch
  git tag $version
  git push origin $branch $version
}

if [[ $1 =~ ^([0-9]+\.){2}[0-9]+$ ]]; then
  make_tag $1 $2
elif [[ $1 == "--patch" ]]; then
  latest_tag=$(get_latest_tag)
  new_version=$(increment_version $latest_tag 2)
  make_tag $new_version $2
elif [[ $1 == "--minor" ]]; then
  latest_tag=$(get_latest_tag)
  new_version=$(increment_version $latest_tag 1)
  make_tag $new_version $2
elif [[ $1 == "--major" ]]; then
  latest_tag=$(get_latest_tag)
  new_version=$(increment_version $latest_tag 0)
  make_tag $new_version $2
else
  echo "Usage: make_release (version | --major | --minor | -patch) branch"
  exit 1
fi
