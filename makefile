HOST = 198.74.52.80
NODE_VERSION = 0.8.15
INSTALL_DIR = /root/node

help:
	@echo 'To set up on a simple Ubuntu 64-bit VPS:'
	@echo ''
	@echo '  `make start` -> make sure your app works'
	@echo '  `nano makefile` -> edit config'
	@echo '  `make deploy` -> rsync files to the remote machine'
	@echo '  `make remote-install` -> install environment, node binary, and service'
	@echo '  `make remote-start` -> start your server'

start:
	npm start

deploy:
	rsync -rv --exclude 'node_modules' --exclude '.git' ./* root@$(HOST):$(INSTALL_DIR)

remote-install:
	ssh root@$(HOST) "cd $(INSTALL_DIR) && sudo apt-get install --yes make && make install"

remote-start:
	ssh root@$(HOST) "cd $(INSTALL_DIR) && npm install && start node"



remote-stop:
	ssh root@$(HOST) "stop node"

remote-shell:
	ssh root@$(HOST)

install: install-env install-node install-service

install-env:
	apt-get update --yes
	apt-get upgrade --yes
	apt-get install --yes build-essential git-core libssl-dev curl
	apt-get install --yes python-setuptools sendmail upstart python-software-properties
	apt-get install --yes imagemagick libmagickcore-dev libmagickwand-dev
	apt-get install --yes graphicsmagick libgraphicsmagick1-dev
	apt-get install --yes ntpdate

install-node:
	cd /tmp && wget http://nodejs.org/dist/v$(NODE_VERSION)/node-v$(NODE_VERSION).tar.gz && tar xzvf node-v$(NODE_VERSION).tar.gz
	cd /tmp/node-v$(NODE_VERSION) && make install

install-service:
	@echo '' > /etc/init/node.conf
	@echo 'description "node service"' >> /etc/init/node.conf
	@echo 'start on filesystem or runlevel [2345]' >> /etc/init/node.conf
	@echo 'stop on runlevel [!2345]' >> /etc/init/node.conf
	@echo 'respawn' >> /etc/init/node.conf
	@echo 'respawn limit 10 5' >> /etc/init/node.conf
	@echo 'umask 022' >> /etc/init/node.conf
	@echo 'script' >> /etc/init/node.conf
	@echo 'cd $(INSTALL_DIR)' >> /etc/init/node.conf
	@echo 'npm start >> $(INSTALL_DIR).log 2>&1' >> /etc/init/node.conf
	@echo 'end script' >> /etc/init/node.conf
	@echo 'created /etc/init/node.conf'



.PHONY: help start deploy remote-install remote-start remote-shell install install-env install-node install-service

