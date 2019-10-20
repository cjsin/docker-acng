TAG             := docker-acng
SOURCES         := $(shell ls *.conf *.sh )
TIMESTAMP       := $(shell stat -c '%Y' $(SOURCES) | sort -n | tail -n1 | cut -d' ' -f1)
EPOCH           := $(shell date +%s)
EPOCH           := $(TIMESTAMP)
VERSION         := $(shell date -d "@$(EPOCH)" +%Y%m%d-%H%M%S)
SERVICE         := $(shell ls *.service )
JSON            := $(TAG).json

DOCKER_BUILDKIT := 1
export DOCKER_BUILDKIT

ifeq ($(shell id -u),0)
SUDO            :=
else
SUDO            := sudo
endif

.PHONY: all install $(TAG)

all: $(TAG)

install: $(SERVICE)
	$(SUDO) install -m 0644 $(SERVICE) /etc/systemd/system/
	$(SUDO) systemctl enable $(SERVICE)
	$(SUDO) systemctl start $(SERVICE)

$(TAG): $(JSON)

$(JSON): $(SOURCES)
	echo $? are newer compared to $@
	docker build --tag $(TAG):$(VERSION) .
	docker tag $(TAG):$(VERSION) $(TAG):latest
	docker inspect $(TAG):$(VERSION) > $(JSON)
	@touch -d "@$$(( $(EPOCH) + 1))" $(JSON)

check:
	docker run -it $(TAG):latest /bin/bash

clean:
	rm -f $(JSON)
