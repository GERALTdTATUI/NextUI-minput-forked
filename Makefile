# Standalone minput builder for the hardware platforms supported by NextUI.
# Usage: make [PLATFORM=tg5040|tg5050|h700]

SUPPORTED_PLATFORMS := tg5040 tg5050 h700
PLATFORM ?= tg5040
CONTAINER_RUNTIME ?= $(shell command -v docker 2>/dev/null || command -v podman 2>/dev/null)
TOOLCHAIN_DIR := toolchains/$(PLATFORM)-toolchain
TOOLCHAIN_MARKER := $(TOOLCHAIN_DIR)/.build
IMAGE_NAME := ghcr.io/loveretro/$(PLATFORM)-toolchain:latest

.PHONY: all build clean clean-all shell list all-platforms check-platform

all: build

check-platform:
	@if ! printf '%s\n' $(SUPPORTED_PLATFORMS) | grep -qx '$(PLATFORM)'; then \
		echo 'Plataforma inválida: $(PLATFORM)'; \
		echo 'Plataformas suportadas: $(SUPPORTED_PLATFORMS)'; \
		exit 2; \
	fi

$(TOOLCHAIN_MARKER): check-platform
	@if [ -z "$(CONTAINER_RUNTIME)" ]; then echo "Erro: Docker ou Podman não encontrado no PATH"; exit 2; fi
	mkdir -p toolchains
	if [ ! -d "$(TOOLCHAIN_DIR)/.git" ]; then \
		git clone https://github.com/LoveRetro/$(PLATFORM)-toolchain/ "$(TOOLCHAIN_DIR)"; \
	fi
	$(CONTAINER_RUNTIME) pull $(IMAGE_NAME)
	touch "$@"

build: $(TOOLCHAIN_MARKER)
	$(CONTAINER_RUNTIME) run --rm \
		-v "$(CURDIR)/workspace:/root/workspace" \
		-e PLATFORM=$(PLATFORM) -e UNION_PLATFORM=$(PLATFORM) \
		$(IMAGE_NAME) /bin/bash -c '. ~/.bashrc && export PLATFORM=$(PLATFORM) UNION_PLATFORM=$(PLATFORM) && \
		cd /root/workspace/$(PLATFORM)/libmsettings && make && \
		cd /root/workspace/all/minput && make clean && make'
	@echo
	@echo "Build concluído: workspace/all/minput/build/$(PLATFORM)/minput.elf"

shell: $(TOOLCHAIN_MARKER)
	$(CONTAINER_RUNTIME) run -it --rm \
		-v "$(CURDIR)/workspace:/root/workspace" \
		-e PLATFORM=$(PLATFORM) -e UNION_PLATFORM=$(PLATFORM) \
		$(IMAGE_NAME) /bin/bash

clean:
	rm -rf workspace/all/minput/build/$(PLATFORM)

clean-all:
	rm -rf workspace/all/minput/build

list:
	@printf '%s\n' $(SUPPORTED_PLATFORMS)

all-platforms:
	@set -e; for platform in $(SUPPORTED_PLATFORMS); do \
		echo "===== Compilando $$platform ====="; \
		$(MAKE) --no-print-directory PLATFORM=$$platform build; \
	done
