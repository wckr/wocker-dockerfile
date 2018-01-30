# WordPress Dockerfile

This is a really simple Dockerfile of WordPress including MySQL and [WP-CLI](http://wp-cli.org/). 

## Usage

### Docker

```shell
$ docker run -d -p 80:80 -p 3306:3306 -p 8025:8025 wocker/wordpress
```

### Wocker

```shell
$ wocker run wocker/wordpress
```
