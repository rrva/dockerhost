#!/bin/bash

SSH_USER=${SSH_USERNAME:-vagrant}
export SSH_USER

if [[ $PACKER_BUILDER_TYPE =~ vmware ]]; then
    echo "==> Installing VMware open-vm-tools"
    apt-get install -y open-vm-tools
fi

if [[ $PACKER_BUILDER_TYPE =~ virtualbox ]]; then
    echo "==> Installing VirtualBox guest additions"
    VERSION=$(dpkg -l | awk '$2=="linux-image-generic" { print $3 }')
    apt-get install -y linux-headers-generic=${VERSION} build-essential perl
    apt-get install -y dkms

    mv /bin/uname /bin/uname.orig
    cp -a /fake/uname /bin/uname
    mv /sbin/modprobe /sbin/modprobe.orig
    ln -s /bin/true /sbin/modprobe
    sh /mnt/VBoxLinuxAdditions.run
    mv /bin/uname.orig /bin/uname
    mv /sbin/modprobe.orig /sbin/modprobe

    if [[ $VBOX_VERSION = "4.3.10" ]]; then
        ln -s /opt/VBoxGuestAdditions-4.3.10/lib/VBoxGuestAdditions /usr/lib/VBoxGuestAdditions
    fi

    apt-get remove -y --purge build-essential linux-headers-generic=${VERSION}
fi
