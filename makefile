# stuff you probably want to change
HOST = 74.207.227.169
SERVICE_NAME = simplenode
NODE_VERSION = 0.8.15

# stuff you probably want to leave alone
EXCLUDE_LIST = --exclude 'authorized_keys' --exclude 'config-*.json' --exclude 'node_modules' --exclude '.git' --exclude 'assets'
INSTALL_DIR = /root/$(SERVICE_NAME)
GET_PUBLIC_KEY = $(shell cat authorized_keys)
KEY_PATH = /root/.ssh
KEY_FILE = $(KEY_PATH)/authorized_keys
LOCAL_PATH = /root/node-$(NODE_VERSION)
BIN_PATH = $(LOCAL_PATH)/bin

################# commands you probably want to use

help:
	@echo 'Using locally:'
	@echo ''
	@echo '1. make setup                -> installs dependencies'
	@echo '2. make start                -> runs locally'
	@echo ''
	@echo 'First-time deploy:'
	@echo ''
	@echo '1. make getkey               -> create ./authorized_keys from your id_rsa.pub'
	@echo '2. make provision-staging    -> add ssh keys, update host, install node.js, create service'
	@echo '3. make deploy-staging       -> deploy application code and config, restart application'
	@echo ''
	@echo 'Continuous deployment:'
	@echo ''
	@echo '1. make deploy-staging'
	@echo ''
	@echo 'See makefile for: authorize, refresh, configure, restart, stop'
	@echo ''

setup: osx-setup
start: osx-start
getkey: osx-getkey

authorize-staging:
	ssh root@$(HOST) "mkdir -p $(KEY_PATH) && touch $(KEY_FILE) && echo '$(GET_PUBLIC_KEY)' >> $(KEY_FILE)"
	ssh root@$(HOST) "uniq $(KEY_FILE) /tmp/authorized_keys && cp /tmp/authorized_keys $(KEY_FILE)"

refresh-staging:
	rsync -rv ./makefile root@$(HOST):$(INSTALL_DIR)/

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
	rsync -rv $(EXCLUDE_LIST) ./* root@$(HOST):$(INSTALL_DIR)/
	make configure-staging
	make restart-staging

restart-staging:
	ssh root@$(HOST) "cd $(INSTALL_DIR) && make linode-restart"

stop-staging:
	ssh root@$(HOST) "cd $(INSTALL_DIR) && make linode-stop"





###################### Utilities you should probably leave alone

# osx

osx-setup:
	npm install

osx-start:
	node app

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

	mkdir -p $(LOCAL_PATH)
	if [ "`$(BIN_PATH)/node --version` 2>&1" != "v$(NODE_VERSION)" ]; then \
	cd /tmp \
	&& wget http://nodejs.org/dist/v$(NODE_VERSION)/node-v$(NODE_VERSION).tar.gz \
	&& tar xzvf node-v$(NODE_VERSION).tar.gz \
	&& cd /tmp/node-v$(NODE_VERSION) \
	&& ./configure --prefix=$(LOCAL_PATH) \
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
	@echo '$(BIN_PATH)/node app >> $(INSTALL_DIR).log 2>&1' >> /etc/init/$(SERVICE_NAME).conf
	@echo 'end script' >> /etc/init/$(SERVICE_NAME).conf
	@echo 'created /etc/init/$(SERVICE_NAME).conf'

linode-restart:
	-stop $(SERVICE_NAME)
	cd $(INSTALL_DIR) && $(BIN_PATH)/npm install
	start $(SERVICE_NAME)

linode-stop:
	-stop $(SERVICE_NAME)


# phony

.PHONY: help restart-local enable-staging provision-staging configure-staging deploy-staging restart-staging linode-provision linode-restart

