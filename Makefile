all: build

.PHONY: build
build:
	pub build

.PHONY: serve
serve:
	pub serve --mode=debug web

.PHONY: test
test:
	pub run test