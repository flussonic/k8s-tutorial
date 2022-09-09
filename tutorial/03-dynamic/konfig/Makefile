KONFIG_IMAGE=$$(grep ' image: ' ../01-konfig.yaml | awk '{print $$2}')

all:
	@echo "build ${KONFIG_IMAGE}"
	docker buildx create --name buildx-konfig --use || true
	docker buildx build \
	 --platform linux/arm64/v8,linux/amd64 \
    --push \
    --tag ${KONFIG_IMAGE} .

# 	minikube image load ${KONFIG_IMAGE}

