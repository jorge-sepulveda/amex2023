# Check to see if we can use ash, in Alpine images, or default to BASH.
SHELL_PATH = /bin/ash
SHELL = $(if $(wildcard $(SHELL_PATH)),/bin/ash,/bin/bash)

run:
	go run app/services/sales-api/main.go | go run app/tooling/logfmt/main.go

run-21:
	go1.21.4 run app/services/sales-api/main.go | go1.21.4 run app/tooling/logfmt/main.go

install:
	go install golang.org/dl/go1.21.4@latest
	go1.21.4 download
