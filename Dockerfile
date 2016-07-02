FROM debian:jessie
MAINTAINER not important

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get clean \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      apache2 \
      libapache2-mod-php5 \
      php5 \
      php5-cli \
      php5-gd \
      php5-mysql \
      php5-curl \
      php5-dev \
      php5-xdebug \
      mysql-server \
      mysql-client \
      curl \
      supervisor \
      ca-certificates \
      vim \
      less \
      php5-dev \
      libsqlite3-dev \
      sqlite3 \
      ruby \
      ruby-dev \
      phpmyadmin \
      git \
      sudo \
      make \
      g++ \
      php-pear \
      
      && rm -rf /var/lib/apt/lists/*

#
# Xdebug remote host setup
#
RUN echo "zend_extension="/usr/lib/php5/20131226/xdebug.so"" >> /etc/php5/apache2/conf.d/20-xdebug.ini \
    && echo "xdebug.remote_host=10.0.23.1" >> /etc/php5/apache2/conf.d/20-xdebug.ini \
    && echo "xdebug.remote_port = 9000" >> /etc/php5/apache2/conf.d/20-xdebug.ini \
    && echo "xdebug.remote_enable = 1" >> /etc/php5/apache2/conf.d/20-xdebug.ini \
    && echo "xdebug.remote_autostart = 0" >> /etc/php5/apache2/conf.d/20-xdebug.ini \
    && echo "xdebug.profiler_enable_trigger = 1" >> /etc/php5/apache2/conf.d/20-xdebug.ini \
    && echo "xdebug.remote_handler = dbgp" >> /etc/php5/apache2/conf.d/20-xdebug.ini \
    && echo "xdebug.profiler_enable=0" >> /etc/php5/apache2/conf.d/20-xdebug.ini
    

#
# Install MailCatcher
#
RUN gem install mailcatcher

#
# Setup MailCatcher Apache proxy-pass
#
RUN sed -i -e '/<\/VirtualHost>/i \ProxyPass \/mailcatcher http:\/\/127.0.0.1:1080\/ \n' /etc/apache2/sites-enabled/000-default.conf
RUN sed -i -e '/<\/VirtualHost>/i \ProxyPass \/assets\/mailcatcher.css http:\/\/127.0.0.1:1080\/assets\/mailcatcher.css \n' /etc/apache2/sites-enabled/000-default.conf
RUN sed -i -e '/<\/VirtualHost>/i \ProxyPass \/assets\/mailcatcher.css http:\/\/127.0.0.1:1080\/assets\/mailcatcher.js \n' /etc/apache2/sites-enabled/000-default.conf

#
# `mysqld_safe` patch
# @see https://github.com/wckr/wocker/pull/28#issuecomment-195945765
#
RUN sed -i -e 's/file) cmd="$cmd >> "`shell_quote_string "$err_log"`" 2>\&1" ;;/file) cmd="$cmd >> "`shell_quote_string "$err_log"`" 2>\&1 \& wait" ;;/' /usr/bin/mysqld_safe

#
# Apache Settings
#
RUN adduser --uid 1000 --gecos '' --disabled-password wocker \
    && echo "ServerName localhost" >> /etc/apache2/apache2.conf \
    && sed -i -e '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf \
    && sed -i -e "s#DocumentRoot.*#DocumentRoot \/var\/www\/wordpress#" /etc/apache2/sites-enabled/000-default.conf \
    && sed -i -e "s/export APACHE_RUN_USER=.*/export APACHE_RUN_USER=wocker/" /etc/apache2/envvars \
    && sed -i -e "s/export APACHE_RUN_GROUP=.*/export APACHE_RUN_GROUP=wocker/" /etc/apache2/envvars \
    && a2enmod rewrite \
    && a2enmod vhost_alias \
    && a2enmod ssl \
    && a2enmod proxy \
    && a2enmod proxy_http
    

#
# php.ini settings
#
RUN sed -i -e "s/^upload_max_filesize.*/upload_max_filesize = 256M/" /etc/php5/apache2/php.ini \
    && sed -i -e "s/^post_max_size.*/post_max_size = 267M/" /etc/php5/apache2/php.ini \
    && sed -i -e "s/^display_errors.*/display_errors = On/" /etc/php5/apache2/php.ini \
    && sed -i -e "s/^;mbstring.internal_encoding.*/mbstring.internal_encoding = UTF-8/" /etc/php5/apache2/php.ini \
    && sed -i -e "s/^;sendmail_path.*/sendmail_path = \/usr\/bin\/env catchmail/" /etc/php5/apache2/php.ini
#
# phpmyadmin copy config to sites-enabled
#
RUN cp /etc/phpmyadmin/apache.conf /etc/apache2/sites-enabled/

#
# Install WP-CLI
#
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli-nightly.phar \
    && chmod +x wp-cli-nightly.phar \
    && mv wp-cli-nightly.phar /usr/local/bin/wp

#
# MySQL settings & Install WordPress
#
RUN mkdir -p /var/www/wordpress
ADD wp-cli.yml /var/www
WORKDIR /var/www/wordpress
RUN sed -i -e "s/^bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/my.cnf \
    && service mysql start \
    && mysqladmin -u root password root \
    && mysql -uroot -proot -e \
      "CREATE DATABASE wordpress DEFAULT CHARACTER SET utf8; grant all privileges on wordpress.* to wordpress@'%' identified by 'wordpress';" \
    && wp core download --allow-root \
    && wp core config --allow-root \
      --dbname=wordpress \
      --dbuser=wordpress \
      --dbpass=wordpress \
      --dbhost=localhost \
    && wp core install --allow-root \
      --admin_name=admin \
      --admin_password=admin \
      --admin_email=admin@example.com \
      --url=http://debugger.com \
      --title=WordPress \
    && wp theme update --allow-root --all \
    && wp plugin update --allow-root --all
RUN chown -R wocker:wocker /var/www/wordpress
RUN chown -R wocker:wocker /var/www

#
# Open ports
#
EXPOSE 80 443 3306 1080 9000

#
# Supervisor
#
RUN mkdir -p /var/log/supervisor
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf
ADD vhost /usr/local/bin/vhost
ADD wp-install /usr/local/bin/wp-install
ADD interface.php /var/www/html/interface.php
RUN chmod +x /usr/local/bin/vhost
RUN chmod +x /usr/local/bin/wp-install

RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer \
    && chmod +x /usr/local/bin/composer

CMD ["/usr/bin/supervisord"]
