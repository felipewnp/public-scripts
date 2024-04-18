# make-swap-file.sh

How to install:

Read the script first! Then:
<br /><br />

To make a /swap_file with 2G:
```bash
curl -o- -sL https://raw.githubusercontent.com/felipewnp/public-scripts/make-swap-file.sh/make-swap-file.sh | sudo bash --
```
<br />

To make a /my_custom_swap with 8G:
```bash
curl -o- -sL https://raw.githubusercontent.com/felipewnp/public-scripts/make-swap-file.sh/make-swap-file.sh | sudo bash -s -- -p '/my_custom_swap' -s '8G'
```
