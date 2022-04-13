.PHONY: test
test: up curl-good curl-bad down
	@echo Test complete

.PHONY: up
up:
	docker-compose up --build --force-recreate -d --remove-orphans

.PHONY: down
down: up
	sleep 8
	docker-compose down

.PHONY: curl-good
curl-good: up
	sleep 2
	@echo GOOD request:
	curl -sSI localhost:8080/good.php

.PHONY: curl-bad
curl-bad: up
	sleep 2
	@echo BAD request:
	curl -sSI localhost:8080/bad.php
