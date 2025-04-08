#!/bin/bash

confirm() {
  read -r -p "${1} [y/N] " response
  if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      echo true
  else
      echo false
  fi
}
file_contains() {
  if grep -wq "$1" $2; then 
    echo true
  else 
    echo false
  fi
}

# $1: String to replace
# $2: String that replace the found string
# $3: File where we should replace the occurance
replace_all() {
  sudo sed -i -e "s/$1/$2/g" "$3"
  #tr $1 $2 < $3 # TODO: needs testing
}

get_prop() {
  echo $(grep "${1}" $2|cut -d'=' -f2)
}
set_prop() {
  sed -i "/${1}/c\\${1}=${2}" $3
}

any_file_exists() {
  files=$(shopt -s nullglob dotglob; echo $1)
  if [ "${#files}" ]; then
    echo true
  else echo false
  fi
}
file_exists() {
  if [ -f $1 ]; then
    echo true
  else echo false
  fi
}