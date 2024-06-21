<h1 align="center">Blockscout - 3Achain</h1>

Blockscout Repository: https://github.com/blockscout/blockscout

### Guide

There are two configs avaiable in the repository `testnet` and `mainnet`, both of them require traefik to be configured beforehand.
All of the configurations are properly set, however, there are some ENVs (secret keys) which needs to be manually set and are not preconfigured.

### Testnet guide

```sh
$ git clone https://github.com/noku-team/blockscout && cd blockscout # Clone the repository
$ git checkout testnet # checkout to the a3chain testnet config set.
$ cd docker && make start # Start all services
```

### Mainnet guide

```sh
$ git clone https://github.com/noku-team/blockscout && cd blockscout # Clone the repository
$ git checkout mainnet # checkout to the a3chain testnet config set.
$ cd docker && make start # Start all services
```

### Keys that need to be added manually

The following Keys needs to be manually set:
* SECRET_KEY_BASE: necessary to sign cookies
* RE_CAPTCHA_SECRET_KEY, RE_CAPTCHA_CLIENT_KEY: necessary both for frontend and backend, these are google captchas keys.
