SRCS := mkosi.conf
SRCS += mkosi.env
SRCS += mkosi.extra/etc/systemd/system/rdp-relay@.service
SRCS += mkosi.extra/etc/systemd/user/up-vpn.service
SRCS += mkosi.extra/usr/local/bin/smss
SRCS += mkosi.extra/usr/local/bin/connect-vpn
SRCS += mkosi.extra/usr/local/bin/edit-vpn
SRCS += mkosi.extra/usr/local/bin/up-vpn
SRCS += mkosi.extra/usr/share/dbus-1/services/org.freedesktop.secrets.service
SRCS += mkosi.extra/var/lib/systemd/linger/router
SRCS += mkosi.postinst.d/10-useradd.chroot
SRCS += mkosi.postinst.d/20-systemd-preset
SRCS += mkosi.postinst.d/90-systemd-target.chroot
SRCS += mkosi.packages/forticlient_vpn_7.4.3.5411_amd64.deb

unshare := unshare --map-auto --map-current-user --setuid 0 --setgid 0
forticlient_vpn_version := 7.4.3.5411
forticlient_vpn_download_url := https://filestore.fortinet.com/forticlient/downloads/forticlient_vpn_${forticlient_vpn_version}_amd64.deb


.PHONY: build
build: build/image.raw

.PHONY: run
run: build/image.raw
	mkosi vm

build/image.raw: $(SRCS)
	mkdir -p mkosi.cache/ mkosi.pkgcache/
	$(unshare) mkosi
	$(unshare) chown -R $$(id -u):$$(id -g) build/

# https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=forticlient-vpn
mkosi.packages/forticlient_vpn_$(forticlient_vpn_version)_amd64.deb:
	curl -L -o$@ $(forticlient_vpn_download_url)

mkosi.extra/usr/local/bin/smss:
	CGO_ENABLED=0 GOBIN=$(CURDIR)/$(dir $@) go install github.com/yskszk63/smss/cmd/smss@latest

.PHONY: test
test:
	VPN_PROFILE=x VPN_HOST=example.com VPN_PORT=10443 VPN_USER=user VPN_PASSWORD=p PATH=./scripts/dummy-vpn/1:$$PATH ./mkosi.extra/usr/local/bin/up-vpn
	VPN_PROFILE=x VPN_HOST=example.com VPN_PORT=10443 VPN_USER=user VPN_PASSWORD=p PATH=./scripts/dummy-vpn/2:$$PATH ./mkosi.extra/usr/local/bin/up-vpn

.PHONY: clean-all
clean-all: clean
	$(unshare) $(RM) -r mkosi.cache/ mkosi.pkgcache/
	$(RM) mkosi.extra/usr/local/bin/smss
	$(RM) mkosi.packages/forticlient_vpn_$(forticlient_vpn_version)_amd64.deb

.PHONY: clean
clean:
	$(RM) -r build/
