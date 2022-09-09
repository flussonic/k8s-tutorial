VERSION:=$(shell cat package.json | jq -r .version)

build:
	docker buildx create --name buildx-log2mongo --use || true
	[ ! -z "${DOCKERHUB_LOGIN}" ] && docker login -u ${DOCKERHUB_LOGIN} -p ${DOCKERHUB_PASSWORD} || true
	docker buildx build \
	 --platform linux/arm64/v8,linux/amd64 \
    --push \
    --build-arg VERSION=${VERSION} \
    --tag flussonic/log2mongo:${VERSION} .
