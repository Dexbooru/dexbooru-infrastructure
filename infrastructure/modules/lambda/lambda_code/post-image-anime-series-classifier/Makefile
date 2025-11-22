BUILD_TARGET=bootstrap
GOOS=linux
GOARCH=amd64
CGO_ENABLED=1
BUILD_TAGS=lambda.norpc
BUILD_PACKAGE=./animeclassifier

build:
	GOOS=$(GOOS) GOARCH=$(GOARCH) CGO_ENABLED=$(CGO_ENABLED) go build -tags $(BUILD_TAGS) -o $(BUILD_TARGET) $(BUILD_PACKAGE)

run:
	GOOS=$(GOOS) GOARCH=$(GOARCH) CGO_ENABLED=$(CGO_ENABLED) go run ./animeclassifier/main.go

test:
	go test -v $(BUILD_PACKAGE)

run-endpoint:
	python run_local.py

clean:
	@rm -f $(BUILD_TARGET)

.PHONY: build clean
