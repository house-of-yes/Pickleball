SHELL := /data/data/com.termux/files/usr/bin/bash
export PATH := $(HOME)/Pickleball/bin:$(PATH)

.PHONY: bootstrap diag
bootstrap:
	@scripts/bootstrap_hotdrop.sh
diag:
	@diag || true
