FROM ruby:2.5.0-slim-stretch as compiled-ruby
FROM debian:stretch-slim

MAINTAINER ixkaito <ixkaito@gmail.com>

RUN apt-get update \
  && apt-get clean \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    apache2 \
    ca-certificates \
    curl \
    less \
    libapache2-mod-php \
    libyaml-0-2 \
    mysql-server \
    mysql-client \
    nano \
    openssh-client \
    php7.0 \
    php7.0-bz \
    php7.0-cli \
    php7.0-curl \
    php7.0-gd \
    php7.0-mbstring \
    php7.0-mysql \
    php7.0-xdebug \
    php7.0-xml \
    sshpass \
    supervisor \
  && rm -rf /var/lib/apt/lists/*

#
# `mysqld_safe` patch
# @see https://github.com/wckr/wocker/pull/28#issuecomment-195945765
#
RUN sed -i -e 's/file) cmd="$cmd >> "`shell_quote_string "$err_log"`" 2>\&1" ;;/file) cmd="$cmd >> "`shell_quote_string "$err_log"`" 2>\&1 \& wait" ;;/' /usr/bin/mysqld_safe

#
# Apache settings
#
RUN adduser --uid 1000 --gecos '' --disabled-password wocker \
  && echo "ServerName localhost" >> /etc/apache2/apache2.conf \
  && sed -i -e '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf \
  && sed -i -e "s#DocumentRoot.*#DocumentRoot /var/www/wordpress#" /etc/apache2/sites-available/000-default.conf \
  && sed -i -e "s/export APACHE_RUN_USER=.*/export APACHE_RUN_USER=wocker/" /etc/apache2/envvars \
  && sed -i -e "s/export APACHE_RUN_GROUP=.*/export APACHE_RUN_GROUP=wocker/" /etc/apache2/envvars \
  && a2enmod rewrite

#
# php.ini settings
#
RUN sed -i -e "s/^upload_max_filesize.*/upload_max_filesize = 32M/" /etc/php/7.0/apache2/php.ini \
  && sed -i -e "s/^post_max_size.*/post_max_size = 64M/" /etc/php/7.0/apache2/php.ini \
  && sed -i -e "s/^display_errors.*/display_errors = On/" /etc/php/7.0/apache2/php.ini \
  && sed -i -e "s/^;mbstring.internal_encoding.*/mbstring.internal_encoding = UTF-8/" /etc/php/7.0/apache2/php.ini \
  && sed -i -e "s#^;sendmail_path.*#sendmail_path = /usr/local/bin/mailhog sendmail#" /etc/php/7.0/apache2/php.ini

#
# Copy Ruby and Gem binary
#
COPY --from=compiled-ruby /usr/local/lib/ /usr/local/lib/
COPY --from=compiled-ruby /usr/local/bin/ruby /usr/local/bin/ruby
COPY --from=compiled-ruby /usr/local/bin/gem /usr/local/bin/gem

#
# Install Gems
#
RUN gem install wordmove --no-document

#
# Install WP-CLI
#
RUN curl -o /usr/local/bin/wp -L https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
  && chmod +x /usr/local/bin/wp

#
# Install PHPUnit
#
RUN curl -o /usr/local/bin/phpunit -L https://phar.phpunit.de/phpunit.phar \
  && chmod +x /usr/local/bin/phpunit

#
# Install Mailhog
#
RUN curl -o /usr/local/bin/mailhog -L https://github.com/mailhog/MailHog/releases/download/v1.0.0/MailHog_linux_amd64 \
  && chmod +x /usr/local/bin/mailhog

#
# Xdebug settings
#
ADD xdebug.ini /etc/php/7.0/cli/conf.d/20-xdebug.ini

#
# MariaDB settings & install WordPress
#
RUN mkdir -p /var/www/wordpress
ADD wp-cli.yml /var/www
WORKDIR /var/www/wordpress
RUN sed -i -e "s/^bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf \
  && service mysql start \
  && mysqladmin -u root password root \
  && mysql -uroot -proot -e \
    "CREATE DATABASE wordpress DEFAULT CHARACTER SET utf8; grant all privileges on wordpress.* to wordpress@'%' identified by 'wordpress';" \
  && wp core download --allow-root \
  && wp core config --allow-root \
    --dbname=wordpress \
    --dbuser=wordpress \
    --dbpass=wordpress \
    --dbhost=localhost
RUN chown -R wocker:wocker /var/www/wordpress

#
# Open ports
#
EXPOSE 80 3306 8025

#
# Supervisor
#
RUN mkdir -p /var/log/supervisor
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

CMD ["/usr/bin/supervisord"]
