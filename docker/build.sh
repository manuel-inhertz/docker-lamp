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

if [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then

    # ca-gen
    sudo wget -O /usr/bin/ca-gen https://github.com/devilbox/cert-gen/raw/master/bin/ca-gen
    sudo chmod +x /usr/bin/ca-gen

    # cert-gen
    sudo wget -O /usr/bin/cert-gen https://github.com/devilbox/cert-gen/raw/master/bin/cert-gen
    sudo chmod +x /usr/bin/cert-gen

    # certificates
    mkdir -p ~/nginx/certs

    sudo ca-gen -v -c IT -s Padova -l Padova -o company -u company -n company.com \
        -e ca@company.com ~/nginx/certs/company-rootCA.key ~/nginx/certs/company-rootCA.crt

    sudo cert-gen -v -n website.loc -a "*.website.loc" \
            ~/nginx/certs/company-rootCA.key \
            ~/nginx/certs/company-rootCA.crt \
            ~/nginx/certs/default.key \
            ~/nginx/certs/default.csr \
            ~/nginx/certs/default.crt
            
    sudo mkdir -p /usr/share/ca-certificates/company

    sudo cp ~/nginx/certs/company-rootCA.key /usr/share/ca-certificates/company
    sudo cp ~/nginx/certs/company-rootCA.crt /usr/share/ca-certificates/company

    sudo dpkg-reconfigure ca-certificates

    if [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
        sudo apt-get install -y libnss3-tools
    fi

    ### Script installs root.cert.pem to certificate trust store of applications using NSS
    ### (e.g. Firefox, Thunderbird, Chromium)
    ### Mozilla uses cert8, Chromium and Chrome use cert9

    ###
    ### Requirement: apt install libnss3-tools
    ###

    ###
    ### CA file to install
    ###

    certfile="${HOME}/nginx/certs/company-rootCA.crt"
    certname="company CA"

    ###
    ### For cert8 (legacy - DBM)
    ###

    for certDB in $(find ~/ -name "cert8.db")
    do
        certdir=$(dirname ${certDB});
        certutil -A -n "${certname}" -t "TCu,Cu,Tu" -i ${certfile} -d dbm:${certdir}
    done


    ###
    ### For cert9 (SQL)
    ###

    for certDB in $(find ~/ -name "cert9.db")
    do
        certdir=$(dirname ${certDB});
        certutil -A -n "${certname}" -t "TCu,Cu,Tu" -i ${certfile} -d sql:${certdir}
    done

    # docker nginx
    sudo docker network create devbox

    mkdir -p ~/nginx/tmpl
    wget -O ~/nginx/tmpl/nginx.tmpl https://gist.github.com/etessari/34ee535ab244428963f64782dc52bbff/raw/73962959d97278eec001200f000d0a1722548ac5/nginx.tmpl

    sudo docker run --name nginx --network="devbox" -d -p 80:80 -p 443:443 -v /var/run/docker.sock:/tmp/docker.sock:ro -v ~/nginx/certs:/etc/nginx/certs:cached -v ~/nginx/tmpl/nginx.tmpl:/app/nginx.tmpl:cached --restart=unless-stopped -d jwilder/nginx-proxy

fi

# docker mysql & redis
sudo docker network create mysql
sudo docker network create redishost

sudo docker run --name mysqlhost --network="mysql" -e MYSQL_ROOT_PASSWORD=sqladm -p 3306:3306 --mount type=volume,src=mysql-data,dst=/var/lib/mysql --restart=unless-stopped -d mysql:5.7

sleep 5

if [ "$(uname)" == "Darwin" ]; then
    # Build compose for Mac OS X platform
    sudo docker-compose -f ./docker-compose-osx.yml up -d --build  
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    # Build compose for GNU/Linux platform
    sudo docker-compose -f ./docker-compose-linux.yml up -d --build 
fi

echo '\033[1;33m All done! > ./start.sh to run containers. \033[0m'
exit