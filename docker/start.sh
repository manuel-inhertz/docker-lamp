#!/bin/bash
# Script to start docker containers

if [ "$(uname)" == "Darwin" ]; then
    # Build compose for Mac OS X platform
    sudo docker-compose -f ./docker-compose-osx.yml up -d  
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    # Build compose for GNU/Linux platform
    sudo docker-compose -f ./docker-compose-linux.yml up -d 
fi

HOST_DOMAIN=$(grep HOST_DOMAIN ./.env)
HOST_DOMAIN=${HOST_DOMAIN//HOST_DOMAIN=/''}

echo "\033[1;33m All done! > you can visit http://$HOST_DOMAIN \033[0m"
exit