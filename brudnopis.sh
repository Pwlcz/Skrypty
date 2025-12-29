#!/bin/bash

HOME_BRUDNOPIS=false
while [[ $# -gt 0 ]]; do
  case $1 in 
    -g|--global)
      HOME_BRUDNOPIS=true
      shift
      ;;
    *)
      shift
      ;;
  esac
done

if [[ "${HOME_BRUDNOPIS}" == "true" ]] || [[ "$PWD" == "$HOME" ]];  then
  vim ~/Dokumenty/brudnopis_general.txt
else
  vim brudnopis.txt
fi
