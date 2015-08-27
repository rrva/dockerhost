all: http/postinstall/wily-core-amd64.tar.gz Fedora-Server-netinst-x86_64-22.iso
	packer build dockerhost.json

Fedora-Server-netinst-x86_64-22.iso:
	curl -O http://dl.fedoraproject.org/pub/fedora/linux/releases/22/Server/x86_64/iso/Fedora-Server-netinst-x86_64-22.iso

http/postinstall/wily-core-amd64.tar.gz:
	curl -o http/postinstall/wily-core-amd64.tar.gz http://cdimage.ubuntu.com/ubuntu-core/daily/current/wily-core-amd64.tar.gz
