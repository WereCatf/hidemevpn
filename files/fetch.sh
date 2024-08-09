#!/bin/bash
if [[ -z "${1}" || -z "${2}" ]]; then
    echo "Must supply platform (ie. arm, arm64, x86-64 etc.) and version tag!"
    exit 1
fi

platform="${1}"
version=$(echo -n "${2}" | sed 's/[ \t_-].*$//')

if [[ ! -e hide.me-linux-${platform}-${version}.tar.gz ]]; then
    wget -q "https://github.com/WereCatf/hide.client.linux/releases/download/${version}/hide.me-${version}-linux-${1}.tar.gz" -O hide.me-linux-${1}-${version}.tar.gz
    if [[ $? -ne 0 ]]; then
        exit 1
    fi
fi

if [[ ! -e CA.pem ]]; then
    if ! tar xfa hide.me-linux-${1}-${version}.tar.gz CA.pem; then
        exit 1
    fi
fi

if [[ ! -e hide.me ]]; then
    if ! tar xfa hide.me-linux-${1}-${version}.tar.gz hide.me; then
        exit 1
    fi
fi
