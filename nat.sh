#!/bin/bash

set -eo pipefail

# Configure the instance to run as a Port Address Translator (PAT) to provide
# Internet connectivity to private instances.
# Save as /usr/local/bin/nat.sh

function log { logger -t "vpc" -- $1; }

function die {
    [ -n "$1" ] && log "$1"
    log "Configuration of PAT failed!"
    exit 1
}

# Sanitize PATH
PATH="/usr/sbin:/sbin:/usr/bin:/bin"

log "Determining the MAC address on ens5..."
ENS5_MAC=$(cat /sys/class/net/ens5/address) ||
    die "Unable to determine MAC address on ens5."
log "Found MAC ${ENS5_MAC} for ens5."

VPC_CIDR_URI="http://169.254.169.254/latest/meta-data/network/interfaces/macs/${ENS5_MAC}/vpc-ipv4-cidr-block"
log "Metadata location for vpc ipv4 range: ${VPC_CIDR_URI}"

log "Getting IMDSv2 token..."
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600") ||
    die "Unable to get IMDSv2 token."
log "Got IMDSv2 token."

VPC_CIDR_RANGE=$(curl --header "X-aws-ec2-metadata-token: $TOKEN" --retry 3 --silent --fail ${VPC_CIDR_URI})
if [ $? -ne 0 ]; then
   log "Unable to retrive VPC CIDR range from meta-data, using 0.0.0.0/0 instead. PAT may be insecure!"
   VPC_CIDR_RANGE="0.0.0.0/0"
else
   log "Retrieved VPC CIDR range ${VPC_CIDR_RANGE} from meta-data."
fi

log "Enabling PAT..."
sysctl -q -w net.ipv4.ip_forward=1 net.ipv4.conf.ens5.send_redirects=0 && (
   iptables -t nat -C POSTROUTING -o ens5 -s ${VPC_CIDR_RANGE} -j MASQUERADE 2> /dev/null ||
   iptables -t nat -A POSTROUTING -o ens5 -s ${VPC_CIDR_RANGE} -j MASQUERADE ) ||
       die

sysctl net.ipv4.ip_forward net.ipv4.conf.ens5.send_redirects | log
iptables -n -t nat -L POSTROUTING | log

log "Configuration of PAT complete."
exit 0
