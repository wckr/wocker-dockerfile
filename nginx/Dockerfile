FROM ruby:2.4.3-slim-stretch as compiled-ruby
FROM debian:stretch-slim

MAINTAINER ixkaito <ixkaito@gmail.com>

RUN apt-get update \
  && apt-get clean \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    less \
    levee \
    libyaml-0-2 \
    mysql-server \
    mysql-client \
    nginx \
    openssh-client \
    php7.0 \
    php7.0-cli \
    php7.0-curl \
    php7.0-fpm \
    php7.0-gd \
    php7.0-mysql \
    php7.0-xdebug \
    supervisor \
  && rm -rf /var/lib/apt/lists/*

#
# Copy Ruby and Gem binary
#
WORKDIR /usr/local/bin/
COPY --from=compiled-ruby /usr/local/lib/ /usr/local/lib/
COPY --from=compiled-ruby /usr/local/bin/ruby ruby
COPY --from=compiled-ruby /usr/local/bin/gem gem

#
# Install Gems
#
RUN gem install wordmove

#
# Install Mailhog
#
WORKDIR /usr/local/bin
RUN curl -o mailhog -L https://github.com/mailhog/MailHog/releases/download/v1.0.0/MailHog_linux_amd64 \
  && chmod +x mailhog

#
# `mysqld_safe` patch
# @see https://github.com/wckr/wocker/pull/28#issuecomment-195945765
#
RUN sed -i -e 's/file) cmd="$cmd >> "`shell_quote_string "$err_log"`" 2>\&1" ;;/file) cmd="$cmd >> "`shell_quote_string "$err_log"`" 2>\&1 \& wait" ;;/' /usr/bin/mysqld_safe

#
# nginx settings
#
RUN adduser --uid 1000 --gecos '' --disabled-password wocker
WORKDIR /etc/nginx/
RUN sed -i -e "s#root /var/www/html;#root /var/www/wordpress/;#" sites-available/default \
  && sed -i -e "s/index index.html/index index.php index.html/" sites-available/default \
  && sed -i -e "/location.*php/,/}/ s/#//" sites-available/default \
  && sed -i -e "/# With php-cgi.*/,/}/ s/fastcgi.*//" sites-available/default \
  && sed -i -e "s/server_name _;/server_name localhost;/" sites-available/default \
  && sed -i -e "s/user www-data/user wocker/" nginx.conf

#
# php-fpm settings
#
WORKDIR /etc/php/7.0/fpm/pool.d/
RUN sed -i -e "s/^user =.*/user = wocker/" www.conf \
  && sed -i -e "s/^group = .*/group = wocker/" www.conf \
  && sed -i -e "s/^listen.owner =.*/listen.owner = wocker/" www.conf \
  && sed -i -e "s/^listen.group =.*/listen.group = wocker/" www.conf

#
# php.ini settings
#
WORKDIR /etc/php/7.0/fpm/
RUN sed -i -e "s/^post_max_size.*/post_max_size = 64M/" php.ini \
  && sed -i -e "s/^display_errors.*/display_errors = On/" php.ini \
  && sed -i -e "s#^;sendmail_path.*#sendmail_path = /usr/local/bin/mailhog sendmail#" php.ini \
  && sed -i -e "s/^upload_max_filesize.*/upload_max_filesize = 32M/" php.ini
RUN service php7.0-fpm start

#
# Xdebug settings
#
ADD xdebug.ini /etc/php/7.0/cli/conf.d/20-xdebug.ini

#
# Install PHPUnit
#
RUN curl -OL https://phar.phpunit.de/phpunit.phar \
  && chmod +x phpunit.phar \
  && mv phpunit.phar /usr/local/bin/phpunit

#
# Install WP-CLI
#
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
  && chmod +x wp-cli.phar \
  && mv wp-cli.phar /usr/local/bin/wp

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
    --dbhost=localhost \
  && wordmove init
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
