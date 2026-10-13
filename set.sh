#!/bin/bash

set -e  #by using set -e the script will stop ececuting when an error occurs

trap 'echo "there is an error in $LINENO, commad is : $BASH_COMMAND"' ERR

 echo "hello 1"
 echo "hello 2"
 sdkjnsd
 echo "hello 3"
