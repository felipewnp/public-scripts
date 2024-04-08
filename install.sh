#!/bin/bash
set -eo pipefail

# Install nat script
wget -s https://raw.githubusercontent.com/felipewnp/public-scripts/nat.sh/nat.sh
mv ./nat.sh /usr/local/bin/nat.sh
chmod 0775 /usr/local/bin/nat.sh
##
#

# Install nat service
wget -s https://raw.githubusercontent.com/felipewnp/public-scripts/nat.sh/nat.service
mv ./nat.service /etc/systemd/system/nat.service
chmod 664 /etc/systemd/system/nat.service
systemctl daemon-reload
systemctl enable nat.service
systemctl start nat.service
##
#
