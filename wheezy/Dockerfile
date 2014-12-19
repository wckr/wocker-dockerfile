FROM debian:wheezy
MAINTAINER ixkaito <ixkaito@gmail.com>

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get clean \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      apache2 \
      php5 \
      libapache2-mod-php5 \
      php5-cli \
      php5-mysql \
      mysql-server \
      mysql-client \
      curl \
      supervisor \
      ca-certificates \
      vim \
    && rm -rf /var/lib/apt/lists/*

#
# Apache Settings
#
RUN mv /etc/apache2/sites-available/default /etc/apache2/sites-available/default.dist
ADD apache2-default /etc/apache2/sites-available/default
RUN a2enmod rewrite

#
# Install WP-CLI
#
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

#
# Install WordPress
#
RUN mkdir /var/www/wordpress
ADD wp-config-extra /wp-config-extra
WORKDIR /var/www/wordpress
RUN service mysql start \
    && mysqladmin -u root password root \
    && mysql -uroot -proot -e \
      "CREATE DATABASE wordpress DEFAULT CHARACTER SET utf8; grant all privileges on wordpress.* to wordpress@localhost identified by 'wordpress';" \
    && wp core download --allow-root \
    && wp core config --allow-root \
      --dbname=wordpress \
      --dbuser=wordpress \
      --dbpass=wordpress \
      --dbhost=localhost \
      --extra-php < /wp-config-extra \
    && wp core install --allow-root \
      --admin_name=admin \
      --admin_password=admin \
      --admin_email=admin@example.com \
      --url=http://vcdw.local \
      --title=WordPress \
    && wp theme update --allow-root --all \
    && wp plugin update --allow-root --all \
    && rm -rf /wp-config-extra
RUN chown -R www-data:www-data /var/www/wordpress

#
# Open ports
#
EXPOSE 80

#
# Supervisor
#
RUN mkdir -p /var/log/supervisor
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

CMD ["/usr/bin/supervisord"]
