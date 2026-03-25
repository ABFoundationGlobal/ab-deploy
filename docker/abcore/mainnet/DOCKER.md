# Docker Compose for AB Core Mainnet

- Builds an image that downloads `geth` and the matching `ab-deploy` package
- Extracts `/data/abcore/mainnet` when required
- Runs `/opt/ab/ab.sh init` when initialization is needed
- Starts the AB Core mainnet node

## Start

```bash
docker compose build --no-cache
docker compose up -d abcore-mainnet
docker compose logs -f abcore-mainnet
```

## Optional Init Only

```bash
docker compose run --rm abcore-init
```

## Stop

```bash
docker compose down
```

## Optional Version Pinning

```bash
USE_AB_BLOCKCHAIN_VERSION=v1.13.15-abcore-1.1 \
USE_AB_DEPLOY_VERSION=v1.8.6 \
docker compose build --no-cache
```

## Notes

- `/data` is mounted from the host.
- The main service can be started directly with `docker compose up -d`; it runs `/opt/ab/ab.sh run` before starting `geth`.
- `geth init` is only executed when `/data/abcore/mainnet/nodedata/geth/chaindata` does not exist yet.
- If the deploy package version changes, the compose flow will re-extract the config package before startup.
