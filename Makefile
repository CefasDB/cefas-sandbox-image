CEFAS_VERSION ?= latest
OUT          := out

.PHONY: all kernel initramfs clean publish

all: kernel initramfs

kernel: $(OUT)/bzImage

$(OUT)/bzImage:
	mkdir -p $(OUT)
	bash scripts/build-kernel.sh $(OUT)

initramfs: $(OUT)/initramfs.cpio.gz

$(OUT)/initramfs.cpio.gz:
	mkdir -p $(OUT)
	CEFAS_VERSION=$(CEFAS_VERSION) bash scripts/build-initramfs.sh $(OUT)

publish: all
	bash scripts/publish.sh $(OUT)

clean:
	rm -rf $(OUT) build/
