FROM centos:centos6
MAINTAINER ixkaito <ixkaito@gmail.com>

RUN yum -y update

#
# Repositories
#
RUN yum -y install epel-release rpmforge-release
RUN rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm

RUN yum -y update --enablerepo=rpmforge,epel,remi,remi-php54

#
# Install YUM packages
#
RUN yum install -y --enablerepo=rpmforge,epel,remi,remi-php54 \
    httpd \
    php \
    php-mbstring \
    mysql-server \
    mysql \
    mysql-devel \
    php-mysqlnd \
    python-setuptools \
    sudo \
    passwd

#
# Create supervisord
#
RUN easy_install supervisor
RUN mkdir -p /var/log/supervisor
ADD ./supervisord.conf /etc/supervisord.conf

#
# Install WP-CLI
#
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
RUN chmod +x wp-cli.phar
RUN mv wp-cli.phar /usr/local/bin/wp

RUN echo "NETWORKING=yes" > /etc/sysconfig/network

#
# Create a Database for WordPress
# Install WordPress
#
RUN service mysqld start && \
    mysqladmin -u root password root && \
    mysql -uroot -proot -e \
      "CREATE DATABASE wordpress DEFAULT CHARACTER SET utf8; grant all privileges on wordpress.* to wordpress@localhost identified by 'wordpress';" && \
    cd /var/www/html && \
    wp core download --locale=ja && \
    wp core config \
      --dbname=wordpress \
      --dbuser=wordpress \
      --dbpass=wordpress \
      --dbhost=localhost \
      --locale=ja && \
    wp core install \
      --admin_name=admin \
      --admin_password=admin \
      --admin_email=admin@example.com \
      --url=http://docker.local \
      --title=WordPress

VOLUME ["/share"]

#
# Open ports
#
EXPOSE 22 80

CMD ["/usr/bin/supervisord"]
