all:
	@echo ""
	@echo "  init: Install glide dependencies. Assumes go and glide are installed already."
	@echo "  test: Run the unit tests and code style validation"
	@echo "  build: Build a linux binary which runs prebid-cache"
	@echo "  image: Build a docker which runs prebid-cache"
	@echo ""

.PHONY: init test build image

init:
	glide install

# Validates the code for style and unit tests
test:
	./validate.sh --nofmt

# Run the tests and make a linux binary for the app. For details about this strategy,
# see https://blog.codeship.com/building-minimal-docker-containers-for-go-applications/
build: test
	CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo  .

# Build a docker image which runs the binary
image:
	docker compose build

up:
	docker compose up

test/put:
	curl -X POST -H "Content-Type: application/json" -d '{"puts": [{"type": "xml", "value": "<VAST>test</VAST>"}]}' http://127.0.0.1:2424/cache

test/get: UUID:=
test/get:
	curl http://127.0.0.1:2424/cache?uuid=${UUID}
