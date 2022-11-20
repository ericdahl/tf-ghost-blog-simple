C = `date "+%Y%m%d-%H%M"`-`git rev-parse --short HEAD`

build:
	docker build -t ericdahl/ghost-proxy:$(C) -t ericdahl/ghost-proxy:latest .
	echo "Built ghost-proxy:$(C)"

deploy: build
	docker push ericdahl/ghost-proxy:$(C)
