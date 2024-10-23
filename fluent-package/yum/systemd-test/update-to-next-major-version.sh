#!/bin/bash

set -exu

. $(dirname $0)/commonvar.sh

# Install the current
package="/host/${distribution}/${DISTRIBUTION_VERSION}/x86_64/Packages/fluent-package-*.rpm"
sudo $DNF install -y $package

# Install plugin manually (plugin and gem)
sudo /opt/fluent/bin/fluent-gem install --no-document fluent-plugin-concat
sudo /opt/fluent/bin/fluent-gem install --no-document linux-utmpx

# Install next major version
package="/host/v6repositories/${distribution}/${DISTRIBUTION_VERSION}/x86_64/Packages/fluent-package-*.rpm"
sudo $DNF install -y $package

# Test: Check whether plugin/gem were installed during upgrading
/opt/fluent/bin/fluent-gem list | grep fluent-plugin-concat
/opt/fluent/bin/fluent-gem list | grep linux-utmpx
