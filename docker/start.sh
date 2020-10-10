#!/bin/bash
# Script to start docker containers

sudo docker-compose up -d  

HOST_DOMAIN=$(grep VIRTUAL_HOST ./.env)
HOST_DOMAIN=${VIRTUAL_HOST//VIRTUAL_HOST=/''}

echo "\033[1;33m All done! > you can visit https://$VIRTUAL_HOST \033[0m"
exit