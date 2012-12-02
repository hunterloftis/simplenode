HOST = 50.116.43.128
SERVICE_NAME = simplenode

NODE_VERSION = 0.8.15
EXCLUDE_LIST = --exclude 'authorized_keys' --exclude 'config-*.json' --exclude 'node_modules' --exclude '.git' --exclude 'assets'
INSTALL_DIR = /root/simplenode/

help:
	@echo ''
	@echo '1. make getkey-local         -> create authorized_keys from your id_rsa.pub'
	@echo '2. make provision-staging    -> add ssh keys, update host, install node.js, create service'
	@echo '3. make deploy-staging       -> deploy application code and config, restart application'
	@echo ''
	@echo 'see makefile for: authorize, refresh, configure, restart, stop'
	@echo ''

# local

start-local: osx-start
getkey-local: osx-getkey

# staging

authorize-staging:
	rsync -v ./authorized_keys root@$(HOST):/root/.ssh/

refresh-staging:
	rsync -v ./makefile root@$(HOST):$(INSTALL_DIR)

configure-staging:
	scp config-default.json root@$(HOST):$(INSTALL_DIR)/config-default.json
	scp config-staging.json root@$(HOST):$(INSTALL_DIR)/config-private.json

provision-staging:
	make authorize-staging
	make refresh-staging
	ssh root@$(HOST) "sudo apt-get install --yes make && cd $(INSTALL_DIR) && make linode-provision"

deploy-staging:
	make refresh-staging
	make stop-staging
	rsync -rv $(EXCLUDE_LIST) ./* root@$(HOST):$(INSTALL_DIR)
	make configure-staging
	make restart-staging

restart-staging:
	ssh root@$(HOST) "cd $(INSTALL_DIR) && make linode-restart"

stop-staging:
	ssh root@$(HOST) "cd $(INSTALL_DIR) && make linode-stop"





################################## Utilities

# osx

osx-start:
	npm start

osx-getkey:
	cp -i ~/.ssh/id_rsa.pub ./authorized_keys
	chmod 0700 ./authorized_keys;


# linode

linode-provision:
	apt-get update --yes
	apt-get upgrade --yes
	apt-get install --yes build-essential git-core libssl-dev curl
	apt-get install --yes python-setuptools sendmail upstart python-software-properties
	apt-get install --yes imagemagick libmagickcore-dev libmagickwand-dev
	apt-get install --yes graphicsmagick libgraphicsmagick1-dev
	apt-get install --yes ntpdate

	if [ `node --version` != "v$(NODE_VERSION)" ]; then \
	cd /tmp \
	&& wget http://nodejs.org/dist/v$(NODE_VERSION)/node-v$(NODE_VERSION).tar.gz \
	&& tar xzvf node-v$(NODE_VERSION).tar.gz \
	&& cd /tmp/node-v$(NODE_VERSION) \
	&& make install; fi

	@echo '' > /etc/init/$(SERVICE_NAME).conf
	@echo 'description "$(SERVICE_NAME) service"' >> /etc/init/$(SERVICE_NAME).conf
	@echo 'start on filesystem or runlevel [2345]' >> /etc/init/$(SERVICE_NAME).conf
	@echo 'stop on runlevel [!2345]' >> /etc/init/$(SERVICE_NAME).conf
	@echo 'respawn' >> /etc/init/$(SERVICE_NAME).conf
	@echo 'respawn limit 60 60' >> /etc/init/$(SERVICE_NAME).conf
	@echo 'umask 022' >> /etc/init/$(SERVICE_NAME).conf
	@echo 'script' >> /etc/init/$(SERVICE_NAME).conf
	@echo 'cd $(INSTALL_DIR)' >> /etc/init/$(SERVICE_NAME).conf
	@echo 'npm start >> $(INSTALL_DIR).log 2>&1' >> /etc/init/$(SERVICE_NAME).conf
	@echo 'end script' >> /etc/init/$(SERVICE_NAME).conf
	@echo 'created /etc/init/$(SERVICE_NAME).conf'

linode-restart:
	stop $(SERVICE_NAME) &2>1
	npm install
	start $(SERVICE_NAME)

linode-stop:
	stop $(SERVICE_NAME) &2>1


# phony

.PHONY: help restart-local enable-staging provision-staging configure-staging deploy-staging restart-staging linode-provision linode-restart

