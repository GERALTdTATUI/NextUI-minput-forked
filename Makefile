# Standalone minput builder and NextUI .pakz packager.
# Usage: make [PLATFORM=tg5040|tg5050|h700]

SUPPORTED_PLATFORMS := tg5040 tg5050 h700
PLATFORM ?= tg5040
CONTAINER_RUNTIME ?= $(shell command -v docker 2>/dev/null || command -v podman 2>/dev/null)
TOOLCHAIN_DIR := toolchains/$(PLATFORM)-toolchain
TOOLCHAIN_MARKER := $(TOOLCHAIN_DIR)/.build
IMAGE_NAME := ghcr.io/loveretro/$(PLATFORM)-toolchain:latest

# Platform-specific package template, stored beside platform sources.
PAK_TEMPLATE := workspace/$(PLATFORM)/Input.pak
BINARY := out/$(PLATFORM)/binaries/minput
DIST_DIR := out
PAKZ := $(DIST_DIR)/minput-$(PLATFORM).pakz
CONTAINER_BINARY := /root/out/$(PLATFORM)/binaries/minput

.PHONY: all build package clean clean-all clean-packages shell list all-platforms \
        check-platform check-packaging-tools

# Default: compile minput and create an installable NextUI package.
all: package

check-platform:
	@if ! printf '%s\n' $(SUPPORTED_PLATFORMS) | grep -qx '$(PLATFORM)'; then \
		echo 'Plataforma inválida: $(PLATFORM)'; \
		echo 'Plataformas suportadas: $(SUPPORTED_PLATFORMS)'; \
		exit 2; \
	fi

$(TOOLCHAIN_MARKER):
	@if [ -z "$(CONTAINER_RUNTIME)" ]; then echo "Erro: Docker ou Podman não encontrado no PATH"; exit 2; fi
	mkdir -p toolchains
	if [ ! -d "$(TOOLCHAIN_DIR)/.git" ]; then \
		git clone https://github.com/LoveRetro/$(PLATFORM)-toolchain/ "$(TOOLCHAIN_DIR)"; \
	fi
	$(CONTAINER_RUNTIME) pull $(IMAGE_NAME)
	touch "$@"

# Compile only minput. Mount out/ separately so the executable is written to
# out/<PLATFORM>/binaries/minput on the host.
build: check-platform $(TOOLCHAIN_MARKER)
	@mkdir -p "out/$(PLATFORM)/binaries"
	$(CONTAINER_RUNTIME) run --rm \
		-v "$(CURDIR)/workspace:/root/workspace" \
		-v "$(CURDIR)/out:/root/out" \
		-e PLATFORM=$(PLATFORM) -e UNION_PLATFORM=$(PLATFORM) \
		$(IMAGE_NAME) /bin/bash -c '. ~/.bashrc && export PLATFORM=$(PLATFORM) UNION_PLATFORM=$(PLATFORM) && \
		cd /root/workspace/$(PLATFORM)/libmsettings && make && \
		cd /root/workspace/all/minput && make clean PRODUCT=$(CONTAINER_BINARY) && make PRODUCT=$(CONTAINER_BINARY)'
	@echo
	@echo "Build concluído: $(BINARY)"

check-packaging-tools:
	@command -v zip >/dev/null 2>&1 || { echo "Erro: o comando 'zip' não foi encontrado. Instale o pacote zip."; exit 2; }

# Copy the selected platform's Input.pak template and add its matching binary.
# The resulting archive has Tools/ as its root, as expected by NextUI.
package: build check-packaging-tools
	@test -f "$(PAK_TEMPLATE)/launch.sh" || { \
		echo "Erro: launch.sh não encontrado em $(PAK_TEMPLATE)/launch.sh"; \
		echo "Adicione o launch.sh específico da plataforma nessa pasta."; \
		exit 2; \
	}
	@test -f "$(BINARY)" || { echo "Erro: binário não encontrado: $(BINARY)"; exit 2; }
	@tmpdir=$$(mktemp -d); \
	trap 'rm -rf "$$tmpdir"' EXIT INT TERM; \
	mkdir -p "$$tmpdir/Tools/$(PLATFORM)"; \
	cp -a "$(PAK_TEMPLATE)" "$$tmpdir/Tools/$(PLATFORM)/"; \
	rm -f "$$tmpdir/Tools/$(PLATFORM)/Input.pak/.gitkeep"; \
	chmod +x "$$tmpdir/Tools/$(PLATFORM)/Input.pak/launch.sh"; \
	install -m 755 "$(BINARY)" "$$tmpdir/Tools/$(PLATFORM)/Input.pak/minput.elf"; \
	(cd "$$tmpdir" && zip -qr "$(abspath $(PAKZ))" "Tools/$(PLATFORM)/Input.pak")
	@echo
	@echo "Pacote NextUI criado: $(PAKZ)"

shell: check-platform $(TOOLCHAIN_MARKER)
	$(CONTAINER_RUNTIME) run -it --rm \
		-v "$(CURDIR)/workspace:/root/workspace" \
		-v "$(CURDIR)/out:/root/out" \
		-e PLATFORM=$(PLATFORM) -e UNION_PLATFORM=$(PLATFORM) \
		$(IMAGE_NAME) /bin/bash

# Remove only the selected platform's binary output.
clean:
	rm -rf "out/$(PLATFORM)/binaries"

# Remove all binary outputs and generated packages.
clean-all:
	rm -rf out

clean-packages:
	rm -f out/*.pakz

list:
	@printf '%s\n' $(SUPPORTED_PLATFORMS)

all-platforms:
	@set -e; for platform in $(SUPPORTED_PLATFORMS); do \
		echo "===== Compilando e empacotando $$platform ====="; \
		$(MAKE) --no-print-directory PLATFORM=$$platform package; \
	done
