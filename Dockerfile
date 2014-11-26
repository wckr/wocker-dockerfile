FROM centos:centos7
MAINTAINER KITE <ixkaito@gmail.com>

RUN yum -y update; yum clean all

#
# Repositories
#
RUN yum -y install epel-release rpmforge-release; yum clean all
RUN rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm

RUN yum -y update --enablerepo=rpmforge,epel,remi,remi-php56

#
# Install libraries
#
RUN yum -y install --enablerepo=remi,remi-php56 httpd php php-opcache php-devel php-mbstring php-mcrypt php-mysqlnd php-phpunit-PHPUnit php-pecl-xdebug php-cli php-common php-gd gd phpMyAdmin sudo openssh-server mariadb mariadb-server bash-completion wget tar passwd

#
# Create a User
#
RUN useradd docker
RUN passwd -f -u docker

RUN echo "docker ALL=(ALL) ALL" >> /etc/sudoers.d/docker

#
# Install WP-CLI
#
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
RUN chmod +x wp-cli.phar
RUN mv wp-cli.phar /usr/local/bin/wp
