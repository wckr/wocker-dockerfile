FROM debian:jessie
MAINTAINER ixkaito <ixkaito@gmail.com>

RUN apt-get update \
  && apt-get clean \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    apache2 \
    ca-certificates \
    curl \
    less \
    libapache2-mod-php5 \
    mysql-server \
    mysql-client \
    php5 \
    php5-cli \
    php5-curl \
    php5-gd \
    php5-mysql \
    supervisor \
    vim \
    ruby \
    lftp \
  && rm -rf /var/lib/apt/lists/*

#
# `mysqld_safe` patch
# @see https://github.com/wckr/wocker/pull/28#issuecomment-195945765
#
RUN sed -i -e 's/file) cmd="$cmd >> "`shell_quote_string "$err_log"`" 2>\&1" ;;/file) cmd="$cmd >> "`shell_quote_string "$err_log"`" 2>\&1 \& wait" ;;/' /usr/bin/mysqld_safe

#
# Ruby gems
#
RUN gem install wordmove

#
# Apache Settings
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
RUN sed -i -e "s/^upload_max_filesize.*/upload_max_filesize = 32M/" /etc/php5/apache2/php.ini \
  && sed -i -e "s/^post_max_size.*/post_max_size = 64M/" /etc/php5/apache2/php.ini \
  && sed -i -e "s/^display_errors.*/display_errors = On/" /etc/php5/apache2/php.ini \
  && sed -i -e "s/^;mbstring.internal_encoding.*/mbstring.internal_encoding = UTF-8/" /etc/php5/apache2/php.ini

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
    --url=http://wocker.dev \
    --title=WordPress \
  && wp theme update --allow-root --all \
  && wp plugin update --allow-root --all
RUN chown -R wocker:wocker /var/www/wordpress

#
# Open ports
#
EXPOSE 80 3306

#
# Supervisor
#
RUN mkdir -p /var/log/supervisor
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

CMD ["/usr/bin/supervisord"]
