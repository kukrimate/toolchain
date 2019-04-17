# Configuration
include config.mk

# Package versions
BINUTILS_VERSION := 2.32
GCC_VERSION      := 8.3.0
MUSL_VERSION     := 1.1.22

# Directories
SRC   := $(PWD)/src
BUILD := $(PWD)/build
TMP   := $(BUILD)/tmp

# Add temporary location to PATH
export PATH := $(TMP)/bin:$(PATH)

###########
# general #
###########

all:
	;

clean:
	rm -rf build/

############
# binutils #
############

# Configure binutils
.PHONY: configure-binutils
configure-binutils: $(SRC)/binutils-$(BINUTILS_VERSION)
	@mkdir -p $(BUILD)/binutils
	@cd $(BUILD)/binutils; test -f .configured || \
		$</configure \
		--prefix=$(TMP) \
		--target=$(TARGET) \
		--disable-multilib \
		$(CONFIG)
	@touch $(BUILD)/binutils/.configured

# Compile binutils
.PHONY: build-binutils
build-binutils: configure-binutils
	@cd $(BUILD)/binutils; test -f .built || $(MAKE)
	@touch $(BUILD)/binutils/.built

# Install binutils
.PHONY: install-binutils
install-binutils: build-binutils
	@$(MAKE) -C $(BUILD)/binutils install

#######
# gcc #
#######

# Configure gcc
.PHONY: configure-gcc
configure-gcc: $(SRC)/gcc-$(GCC_VERSION) install-binutils
	@mkdir -p $(BUILD)/gcc
	@cd $(BUILD)/gcc; test -f .configured || \
		$</configure \
		--prefix=$(TMP) \
		--target=$(TARGET) \
		--enable-languages=c \
		--disable-multilib \
		--disable-libgomp \
		--disable-libatomic \
		--disable-libmpx \
		--disable-libssp \
		--disable-libquadmath \
		$(CONFIG)
	@touch $(BUILD)/gcc/.configured

# Build the compiler only
.PHONY: build-gcc-cc
build-gcc-cc: configure-gcc
	@$(MAKE) -C $(BUILD)/gcc all-gcc

# Install the compiler only
.PHONY: install-gcc-cc
install-gcc-cc: build-gcc-cc
	@$(MAKE) -C $(BUILD)/gcc install-gcc

# Build static libgcc
.PHONY: build-gcc-libgccstatic
build-gcc-libgccstatic: install-musl-headers
	@$(MAKE) enable_shared=no -e -C $(BUILD)/gcc all-target-libgcc

# Install static libgcc
.PHONY: install-gcc-libgccstatic
install-gcc-libgccstatic: build-gcc-libgccstatic
	@$(MAKE) enable_shared=no -e -C $(BUILD)/gcc install-target-libgcc

# Build final gcc
.PHONY: build-gcc
build-gcc: install-musl-libgccstatic
	@$(MAKE) enable_shared=yes -e -C $(BUILD)/gcc

# Install final gcc
.PHONY: install-gcc
install-gcc: build-gcc
	@$(MAKE) enable_shared=yes -e -C $(BUILD)/gcc install

#############
# musl libc #
#############

# Configure musl
# NOTE: there is no re-configure prevention here, as this *must* run twice
.PHONY: configure-musl
configure-musl: $(SRC)/musl-$(MUSL_VERSION) install-gcc-cc
	@mkdir -p $(BUILD)/musl
	@cd $(BUILD)/musl; $</configure \
		--prefix=$(TMP)/$(TARGET) \
		--host=$(TARGET)

# Install libc headers
.PHONY: install-musl-headers
install-musl-headers: configure-musl
	@cd $(BUILD)/musl; $(MAKE) install-headers

# Build musl linked against static libgcc
.PHONY: build-musl-libgccstatic
build-musl-libgccstatic: configure-musl install-gcc-libgccstatic
	cd $(BUILD)/musl; $(MAKE)

# Install musl linked against static libgcc
.PHONY: install-musl-libgccstatic
install-musl-libgccstatic: build-musl-libgccstatic
	cd $(BUILD)/musl; $(MAKE) install

# Build musl linked against proper libgcc
.PHONY: build-musl
build-musl: configure-musl install-gcc
	cd $(BUILD)/musl; $(MAKE) all

# Install musl linked against proper libgcc
.PHONY: install-musl
install-musl: build-musl
	cd $(BUILD)/musl; $(MAKE) -B install
