# helper script

build:
	docker compose build

up:
	docker compose run -d postgres

load-data: up
	docker compose run --rm taop load-data

commitlog: up
	docker compose run --rm taop commitlog

psql: up
	docker compose run --rm -it --remove-orphans psql


.PHONY: build load-data commitlog psql
