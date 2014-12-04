# Run a VCDW container named "vcdw" by default
vcdwrun() {
  docker run -d ${2:-ixkaito/vcdw} && \
  docker cp $(docker ps -l -q):/var/www/wordpress /home/core && \
  docker rm -f $(docker ps -l -q) && \
  docker run -d --name ${1:-vcdw} -p 80:80 -v /home/core/wordpress:/var/www/wordpress:rw ${2:-ixkaito/vcdw}
}

# Stop all running containers
dockerstopall() {
  docker stop $(docker ps -a -q);
}

# Force remove all containers
dockerrmall() {
  docker rm -f $(docker ps -a -q);
}
