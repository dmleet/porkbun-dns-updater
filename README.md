# Porkbun DNS Updater
## A simple script to update Porkbun DNS records

### Notes:
* Multiple subdomains can be updated by providing comma-delimited list, **SUB_DOMAINS** = "@,www,api"
* Required ENV variables are **DOMAIN**, **API_KEY**, and **API_SECRET**
* Default of 600 used for **INTERVAL** if none specified (10 minutes)
* External IP is obtained from https://api.ipify.org/

## Docker run example
```
docker run -d \
  --name=porkbun-dns-updater \
  -e DOMAIN=example.com \
  -e SUB_DOMAINS='@,www,api' \
  -e API_KEY='pk1_xxxxxxx' \
  -e API_SECRET='sk1_xxxxxxx' \
  -e INTERVAL=600 \
  --restart unless-stopped \
  dmleet/porkbun-dns-updater:latest
```
