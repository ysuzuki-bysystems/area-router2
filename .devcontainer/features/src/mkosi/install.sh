#!/bin/bash

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

apt_get_update()
{
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update -y
    fi
}

# Checks if packages are installed and installs them if not
check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        apt_get_update
        apt-get -y install --no-install-recommends "$@"
    fi
}

export DEBIAN_FRONTEND=noninteractive

check_packages curl ca-certificates cpio zstd systemd-repart systemd-ukify uidmap e2fsprogs dosfstools mtools

pbsurl="https://github.com/astral-sh/python-build-standalone/releases/download/20260901/cpython-3.14.7+20260901-x86_64-unknown-linux-gnu-install_only_stripped.tar.gz"
srcurl="https://github.com/systemd/mkosi/archive/refs/tags/v27.tar.gz"

root=/opt/mkosi
mkdir -p $root/mkosi/bin

curl -sSfL "$pbsurl" | tar -zvxf - -C$root

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

curl -sSfL "$srcurl" | tar -zvxf - --strip-components=1 -C"$tmpdir"
(cd "$tmpdir" && PATH="$root/python/bin:$PATH" tools/generate-zipapp.sh && cp "$tmpdir/builddir/mkosi" $root/mkosi/bin/mkosi)

$root/python/bin/pip3 install pefile

cat << EOF > /usr/local/bin/mkosi
#!/bin/bash
export PATH=$root/python/bin:\$PATH
exec $root/python/bin/python $root/mkosi/bin/mkosi "\$@"
EOF
chmod +x /usr/local/bin/mkosi
