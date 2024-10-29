#!/bin/bash

set -exu

. $(dirname $0)/../commonvar.sh

# TODO: Remove it when v5 repository was deployed
sudo apt install -y curl ca-certificates
curl -O https://packages.treasuredata.com/4/${distribution}/${code_name}/pool/contrib/f/fluentd-apt-source/fluentd-apt-source_2020.8.25-1_all.deb
sudo apt install -y ./fluentd-apt-source_2020.8.25-1_all.deb

# Install v4
sudo apt clean all
# Uncomment when v5 repository was deployed
#apt_source_package=/host/${distribution}/pool/${code_name}/${channel}/*/*/fluent-apt-source*_all.deb
#sudo apt install -V -y ${apt_source_package} ca-certificates
sudo apt update
sudo apt install -V -y td-agent=${td_agent_version}-1

systemctl status --no-pager td-agent

# Install the current
curl -fsSL https://toolbelt.treasuredata.com/sh/install-${distribution}-${code_name}-fluent-package5-lts.sh | sh

# Test: service status
systemctl status --no-pager fluentd
(! systemctl status --no-pager td-agent)

# Test: restoring td-agent service alias
# sudo systemctl stop fluentd
# sudo systemctl unmask td-agent
# sudo systemctl enable --now fluentd

# systemctl status --no-pager td-agent
# systemctl status --no-pager fluentd

# Test: config migration
test -h /etc/td-agent
test -h /etc/fluent/fluentd.conf
test $(readlink "/etc/fluent/fluentd.conf") = "/etc/fluent/td-agent.conf"
test -e /etc/td-agent/td-agent.conf
test -e /etc/fluent/a\ b\ c
test -e /etc/fluent/plugin/in_fake.rb

# Test: log file migration
test -h /var/log/td-agent
test -e /var/log/td-agent/td-agent.log

# Test: bin file migration
test -h /usr/sbin/td-agent
test -h /usr/sbin/td-agent-gem

# Test: environmental variables
pid=$(systemctl show fluentd --property=MainPID --value)
env_vars=$(sudo sed -e 's/\x0/\n/g' /proc/$pid/environ)
test $(eval $env_vars && echo $HOME) = "/var/lib/fluent"
test $(eval $env_vars && echo $LOGNAME) = "_fluentd"
test $(eval $env_vars && echo $USER) = "_fluentd"
test $(eval $env_vars && echo $FLUENT_CONF) = "/etc/fluent/fluentd.conf"
test $(eval $env_vars && echo $FLUENT_PACKAGE_LOG_FILE) = "/var/log/fluent/fluentd.log"
test $(eval $env_vars && echo $FLUENT_PLUGIN) = "/etc/fluent/plugin"
test $(eval $env_vars && echo $FLUENT_SOCKET) = "/var/run/fluent/fluentd.sock"

# Uninstall
sudo apt remove -y fluent-package
(! systemctl status --no-pager td-agent)
(! systemctl status --no-pager fluentd)

test -h /etc/systemd/system/td-agent.service
(! test -s /etc/systemd/system/td-agent.service)
test -h /etc/systemd/system/fluentd.service
(! test -s /etc/systemd/system/fluentd.service)
test -h /etc/systemd/system/multi-user.target.wants/fluentd.service
(! test -s /etc/systemd/system/multi-user.target.wants/fluentd.service)
