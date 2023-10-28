#!/bin/bash

# set -x

# make a new relaase
# "make_release 1.2.3 main" in order to create a git tag 1.2.3 on branch main
# "make_release --patch master" to increase the patch number of the latest tag and create a tag on branch main for the new version
# "make_release --minor master" to increase the minor number of the latest tag and create a tag on branch main for the new version
# "make_release --major master" to increase the major number of the latest tag and create a tag on branch main for the new version

function get_base_directory {
  local base_dir
  pushd "`dirname $0`/../.." >/dev/null
  base_dir=`pwd`
  popd >/dev/null
  echo $base_dir
}

function get_version_file {
   echo $(get_base_directory)/package.4th
}

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

function update_version_file {
  local new_version=$1
  local version_file=$(get_version_file)
  echo "$version_file" 
  sed -i "s/key-value version .*/key-value version $new_version/" "$version_file"
  git add "$version_file"
  git commit -m "Update version to $new_version"
}

function make_tag {
  local version=$1
  local branch=${2:-$(git branch --show-current)}
  git checkout $branch
  git tag $version
  git push origin $branch $version
}

function main {
  local new_version
  local current_version
  local branch=${2:-$(git branch --show-current)}
  
  if [[ $1 =~ ^([0-9]+\.){2}[0-9]+$ ]]; then
    new_version=$1
  elif [[ $1 == "--patch" || $1 == "--minor" || $1 == "--major" ]]; then
    local field_index
    case $1 in 
      "--patch") field_index=2;;
      "--minor") field_index=1;;
      "--major") field_index=0;;
    esac
    local latest_tag=$(get_latest_tag)
    new_version=$(increment_version $latest_tag $field_index)
  else
    echo "Usage: make_release.sh (version | --major | --minor | --patch) [branch]"
    exit 1
  fi
  
  current_version=$(grep "key-value version" $(get_version_file) | awk '{print $3}')
  
  if [[ $new_version != $current_version ]]; then
    update_version_file $new_version
  fi
  
  make_tag $new_version $branch
}

main $1 $2
