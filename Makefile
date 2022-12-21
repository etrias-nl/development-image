DOCKERFILE?=Dockerfile
DOCKER_PROGRESS?=auto
DOCKER_IMAGE=etriasnl/dev-php-fpm
PHP_VERSION=$(shell cat "${DOCKERFILE}" | grep 'FROM php:' | cut -f2 -d':' | cut -f1 -d '-')
NODE_VERSION=$(shell cat "${DOCKERFILE}" | grep 'FROM node:' | cut -f2 -d':' | cut -f1 -d '-')
PATCH_VERSION=$$(($(shell curl -sS "https://hub.docker.com/v2/repositories/${DOCKER_IMAGE}/tags/?page_size=1&page=1&name=${PHP_VERSION}-&ordering=last_updated" | jq -r '.results[0].name' | cut -f2 -d '-') + 1))
MAKEFLAGS += --warn-undefined-variables --always-make
.DEFAULT_GOAL := _

PHP_TAG=${DOCKER_IMAGE}:${PHP_VERSION}-${PATCH_VERSION}
PHP_NODE_TAG=${PHP_TAG}-node-${NODE_VERSION}

lint:
	docker run -it --rm -v "$(shell pwd):/app" -w /app hadolint/hadolint hadolint --ignore DL3059 "${DOCKERFILE}"
release: lint
	docker buildx build --progress "${DOCKER_PROGRESS}" --target php -f "${DOCKERFILE}" -t "${PHP_TAG}" --load .
	docker buildx build --progress "${DOCKER_PROGRESS}" --target php_node -f "${DOCKERFILE}" -t "${PHP_NODE_TAG}" --load .
publish: release
	docker push "${PHP_TAG}"
	docker push "${PHP_NODE_TAG}"
