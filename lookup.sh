#!/bin/bash

dodig() {
    dig +short "$1" | tail -1
}

dohost() {
    host "$1" | awk '{print $NF}'
}

main() {
    if [ -x "$(command -v dig)" ] ; then
        dodig "$1"
    elif [ -x "$(command -v host)" ] ; then
        dohost "$1"
    else
        echo "Can't find a resolver like dig or nslookup"
    fi
}

ip_address=$(main $1)
echo "{\"ip_address\": \"$ip_address/32\"}"