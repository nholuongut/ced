#!/bin/bash
###
# Colors
###
RED="\\e[1;31m"
GREEN="\\e[1;32m"
CYAN="\\e[1;36m"
YELLOW="\\e[1;33m"
BLUE="\\e[1;34m"
BLACK="\\e[1;35m"
ENDCOLOR="\e[0m"


log() {
  
  config_log_level=$(get_conf "log_level")
  log_level=${config_log_level:-2}
  
  case $2 in
    DEBUG)
      if [[ $(get_conf "log_level") -lt 1 ]]; then
        printf "${BLACK}[DEBUG]${ENDCOLOR} $1\\n" | tee -a $outputlog
      fi
      ;;
    VERBOSE)
      if [[ $(get_conf "log_level") -lt 2 ]]; then
        printf "${BLUE}[VERBOSE]${ENDCOLOR} $1\\n" | tee -a $outputlog
      fi
      ;;
    INFO)
      if [[ $(get_conf "log_level") -lt 3 ]]; then
        printf "${CYAN}[INFO]${ENDCOLOR} $1\\n" | tee -a $outputlog
      fi
      ;;
    WARN)
      if [[ $(get_conf "log_level") -lt 4 ]]; then
      printf "${YELLOW}[WARN] $1${ENDCOLOR}\\n" | tee -a $outputlog
      fi
      ;;
    ERROR)
      printf "${RED}[ERROR] $1${ENDCOLOR}\\n" | tee -a $errorlog
      exit 1
      ;;
    *)
      printf "Wrong call! $2" | tee -a $errorlog
      exit 1
      ;;
  esac
}

print_help() {
  echo "
    $cli_use_name
    CED CLI
    Version: $(cat $cwd/VERSION)
    Usage: $cli_use_name $1 <options>
    Options: 
      $2
  "
}

get_conf() {
  echo $(get_prop $1 $config_path)
}
set_conf() {
  set_prop $1 $2 $config_path
}
command_exists() {
  if [ -x "$(command -v $1)" ]; then
    echo true
  else echo false
  fi
}