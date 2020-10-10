#!/bin/bash
# Script to setup nginx proxy and shared mysql docker images

# install docker and docker-compose if not available (Linux only) for Mac OS X or Windows refer to: https://www.docker.com/get-started
if [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    # Install on GNU/Linux platform
    if ! type "docker" > /dev/null; then
        # install docker
        sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
        sudo apt update
        apt-cache policy docker-ce
        sudo apt install -y docker-ce
        sudo usermod -aG docker ${USER}
    fi
    if ! type "docker-compose" > /dev/null; then
        # install docker-compose
        sudo curl -L https://github.com/docker/compose/releases/download/1.26.2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        docker-compose --version
    fi
fi

# preload docker images
sudo docker pull mysql:5.7
sudo docker pull jwilder/nginx-proxy

# docker nginx
sudo docker network create devbox

if ! type "wget" > /dev/null; then
    echo "Please install wget -> apt install wget or brew install wget";
    exit;
fi

mkdir -p ~/nginx/tmpl
mkdir -p ~/nginx/certs
wget -O ~/nginx/tmpl/nginx.tmpl https://gist.github.com/etessari/34ee535ab244428963f64782dc52bbff/raw/73962959d97278eec001200f000d0a1722548ac5/nginx.tmpl

sudo docker run -d -p 80:80 -p 443:443 \
    --name nginx-proxy \
    --net devbox \
    -v ~/nginx/certs:/etc/nginx/certs:ro \
    -v /etc/nginx/vhost.d \
    -v /usr/share/nginx/html \
    -v /var/run/docker.sock:/tmp/docker.sock:ro \
    -v ~/nginx/tmpl/nginx.tmpl:/app/nginx.tmpl:cached \
    --restart=unless-stopped \
    --label com.github.jrcs.letsencrypt_nginx_proxy_companion.nginx_proxy=true \
    jwilder/nginx-proxy

sudo docker run -d \
    --name nginx-letsencrypt \
    --net devbox \
    --volumes-from nginx-proxy \
    -v ~/nginx/certs:/etc/nginx/certs:rw \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    jrcs/letsencrypt-nginx-proxy-companion

# docker mysql & redis
sudo docker network create mysql
sudo docker network create redishost

sudo docker run --name mysqlhost --network="mysql" -e MYSQL_ROOT_PASSWORD=sqladm -p 3306:3306 --mount type=volume,src=mysql-data,dst=/var/lib/mysql --restart=unless-stopped -d mysql:5.7

sleep 5

sudo docker-compose up -d --build

echo '\033[1;33m All done! > ./start.sh to run containers. \033[0m'
exit