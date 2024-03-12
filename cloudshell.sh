#!/bin/bash

curl -sOL https://github.com/getsops/sops/releases/download/v3.8.1/sops-v3.8.1.linux.amd64

mv sops-v3.8.1.linux.amd64 /usr/local/bin/sops

chmod +x /usr/local/bin/sops
