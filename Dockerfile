FROM centos:centos6
MAINTAINER ixkaito <ixkaito@gmail.com>

RUN yum -y update; yum clean all

#
# Repositories
#
RUN yum -y install epel-release rpmforge-release; yum clean all
RUN rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm

RUN yum -y update --enablerepo=rpmforge,epel,remi,remi-php54; yum clean all

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
    php-xml \
    python-setuptools \
    ; yum clean all

#
# Install WP-CLI
#
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
RUN chmod +x wp-cli.phar
RUN mv wp-cli.phar /usr/local/bin/wp

RUN echo "NETWORKING=yes" > /etc/sysconfig/network

#
# Make a WordPress folder
# Change Apache DocumentRoot to WordPress folder
# Create a Database for WordPress
# Install WordPress
#
RUN mkdir /var/www/wordpress
RUN sed -i 's/^DocumentRoot "\/var\/www\/html"$/DocumentRoot "\/var\/www\/wordpress"/' /etc/httpd/conf/httpd.conf
ADD wp-config-extra /wp-config-extra
WORKDIR /var/www/wordpress
RUN service mysqld start && \
    mysqladmin -u root password root && \
    mysql -uroot -proot -e \
      "CREATE DATABASE wordpress DEFAULT CHARACTER SET utf8; grant all privileges on wordpress.* to wordpress@localhost identified by 'wordpress';" && \
    wp core download \
      # --locale=ja \
      && \
    wp core config \
      --dbname=wordpress \
      --dbuser=wordpress \
      --dbpass=wordpress \
      --dbhost=localhost \
      # --locale=ja \
      --extra-php < /wp-config-extra \
      && \
    wp core install \
      --admin_name=admin \
      --admin_password=admin \
      --admin_email=admin@example.com \
      --url=http://vcdw.local \
      --title=WordPress \
      && \
    # wp plugin install --activate \
    #   wp-multibyte-patch \
    #   theme-check \
    #   plugin-check \
    #   && \
    wp theme update --all && wp plugin update --all
RUN chown -R apache:apache /var/www/wordpress
RUN rm -f /wp-config-extra
WORKDIR /

#
# Open ports
#
EXPOSE 22 80

#
# Create supervisord
#
RUN easy_install supervisor
RUN mkdir -p /var/log/supervisor
ADD ./supervisord.conf /etc/supervisord.conf

CMD ["/usr/bin/supervisord"]

#
# Optional packages
#
# RUN yum install -y --enablerepo=rpmforge,epel,remi,remi-php54 \
#     bash-completion \
#     wget \
#     tar \
#     sudo \
#     passwd \
#     php-opcache \
#     php-devel \
#     php-mcrypt \
#     php-phpunit-PHPUnit \
#     php-pecl-xdebug \
#     php-gd \
#     gd
