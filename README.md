# Graceful php-fpm shutdown

This repo tests php-fpm graceful shutdown configuration for https://github.com/uselagoon/lagoon-images/pull/445

It works by using `docker-compose` to run an nginx backed by two `php-fpm` instances.
One instance is patched for graceful shutdown, while the other is not.
Both instances run a php script which does a `sleep(20)` before returning a "hello world" and 200 response.

The `Makefile` brings up the services, kicks off a request to each of the "good" and "bad" backends, and then runs `docker-compose down`.
This causes the `sleep()` to be interrupted and the request to return.

In the case of the "good" backend the master `php-fpm` process waits gracefully for the response before exiting.
In the case of the "bad" backend the master `php-fpm` process kills the worker and exits immediately, returning a `502`.

## Usage

1. Check out the [php-fpm-graceful-shutdown branch](https://github.com/uselagoon/lagoon-images/tree/php-fpm-graceful-shutdown) of lagoon-images.
2. In that branch `make build/php-8.1-fpm` to produce a local tagged image `lagoon/php-8.1-fpm`.
3. Check out this repo, and run `make -j4 -O`
4. See the patched `lagoon/php-8.1-fpm` return a `200` while the unpatched `uselagoon/php-8.1-fpm:22.4.0` returns a `502`.

Example output:

```
$ make -j4 -O
docker-compose up --build --force-recreate -d --remove-orphans
Sending build context to Docker daemon     373B
Step 1/2 : FROM nginx:alpine
 ---> 51696c87e77e
Step 2/2 : COPY ./default.conf /etc/nginx/conf.d/
 ---> Using cache
 ---> 0ff2dbdda3c3
Successfully built 0ff2dbdda3c3
Successfully tagged php-fpm-test_nginx:latest
Sending build context to Docker daemon     282B
Step 1/2 : FROM lagoon/php-8.1-fpm:latest
 ---> 6f141144cc3a
Step 2/2 : COPY good.php /app/good.php
 ---> Using cache
 ---> 61d3a780688f
Successfully built 61d3a780688f
Successfully tagged php-fpm-test_good:latest
Sending build context to Docker daemon     285B
Step 1/2 : FROM uselagoon/php-8.1-fpm:22.4.0
 ---> d9cab44484a7
Step 2/2 : COPY bad.php /app/bad.php
 ---> Using cache
 ---> 5232b3d5d508
Successfully built 5232b3d5d508
Successfully tagged php-fpm-test_bad:latest

Use 'docker scan' to run Snyk tests against images to find vulnerabilities and learn how to fix them
Network php-fpm-test_default  Creating
Network php-fpm-test_default  Created
Container php-fpm-test-bad-1  Creating
Container php-fpm-test-nginx-1  Creating
Container php-fpm-test-good-1  Creating
Container php-fpm-test-nginx-1  Created
Container php-fpm-test-bad-1  Created
Container php-fpm-test-good-1  Created
Container php-fpm-test-nginx-1  Starting
Container php-fpm-test-bad-1  Starting
Container php-fpm-test-good-1  Starting
Container php-fpm-test-nginx-1  Started
Container php-fpm-test-bad-1  Started
Container php-fpm-test-good-1  Started
sleep 2
GOOD request:
curl -sSI localhost:8080/good.php
HTTP/1.1 200 OK
Server: nginx/1.21.6
Date: Wed, 13 Apr 2022 01:31:35 GMT
Content-Type: text/html; charset=UTF-8
Connection: close

sleep 2
BAD request:
curl -sSI localhost:8080/bad.php
HTTP/1.1 502 Bad Gateway
Server: nginx/1.21.6
Date: Wed, 13 Apr 2022 01:31:35 GMT
Content-Type: text/html
Content-Length: 157
Connection: close

sleep 8
docker-compose down
Container php-fpm-test-good-1  Stopping
Container php-fpm-test-good-1  Stopping
Container php-fpm-test-nginx-1  Stopping
Container php-fpm-test-nginx-1  Stopping
Container php-fpm-test-bad-1  Stopping
Container php-fpm-test-bad-1  Stopping
Container php-fpm-test-bad-1  Stopped
Container php-fpm-test-bad-1  Removing
Container php-fpm-test-nginx-1  Stopped
Container php-fpm-test-nginx-1  Removing
Container php-fpm-test-nginx-1  Removed
Container php-fpm-test-good-1  Stopped
Container php-fpm-test-good-1  Removing
Container php-fpm-test-bad-1  Removed
Container php-fpm-test-good-1  Removed
Network php-fpm-test_default  Removing
Network php-fpm-test_default  Removed
Test complete
```
