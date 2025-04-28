# AB node deployment guide

## 1. System requirements

### 1.1 Recommended specifications
  - System OS: Ubuntu 24.04 LTS x86_64
  - Processor: 2-core CPU
  - Memory: 16GB RAM
  - Storage: 200GB available space SSD
  - Internet: Public IP

For server requirements, please refer to AWS r7a.large or r7i.large.

### 1.2 System Configuration
  - System data disk: /data directory is the mount point of the system data disk

## 2. Installation and deployment

### 2.1 Create a working directory and enter it

```bash
mkdir -p ab && cd ab
```

### 2.2 Fetch the `ab.sh` script run it

```bash
# AB Core Mainnet
curl -fsSL https://raw.githubusercontent.com/ABFoundationGlobal/ab-deploy/main/ab.sh | sudo bash -s abcore mainnet
```
```bash
# AB IoT Mainnet
curl -fsSL https://raw.githubusercontent.com/ABFoundationGlobal/ab-deploy/main/ab.sh | sudo bash -s abiot mainnet
```
```bash
# AB Core Testnet
curl -fsSL https://raw.githubusercontent.com/ABFoundationGlobal/ab-deploy/main/ab.sh | sudo bash -s abcore testnet
```
```bash
# AB IoT Testnet
curl -fsSL https://raw.githubusercontent.com/ABFoundationGlobal/ab-deploy/main/ab.sh | sudo bash -s abiot testnet
```

### 2.3 View AB nodes logs

```bash
# AB Core Mainnet
sudo supervisorctl tail -f abcore stderr
```
```bash
# AB IoT Mainnet
sudo supervisorctl tail -f abiot stderr
```
```bash
# AB Core Testnet
sudo supervisorctl tail -f abcoretestnet stderr
```
```bash
# AB IoT Testnet
sudo supervisorctl tail -f abiottestnet stderr
```

## 3. Use AB nodes
  
| Network | RPC Port           | P2P Port      | notes |
| ------- | ------------------ | ------------- | ----- |
| AB Core | http 8545, ws 8546 | tcp/udp 33333 |       |
| AB IoT  | http 8801          | tcp/udp 38311 |       |

## 4. Operation and maintenance related operations

- Start AB nodes:

```bash
# AB Core Mainnet
sudo supervisorctl start abcore
```
```bash
# AB IoT Mainnet
sudo supervisorctl start abiot
```
```bash
# AB Core Testnet
sudo supervisorctl start abcoretestnet
```
```bash
# AB IoT Testnet
sudo supervisorctl start abiottestnet
```

- Stop AB nodes:

```bash
# AB Core Mainnet
sudo supervisorctl stop abcore
```
```bash
# AB IoT Mainnet
sudo supervisorctl stop abiot
```
```bash
# AB Core Testnet
sudo supervisorctl stop abcoretestnet
```
```bash
# AB IoT Testnet
sudo supervisorctl stop abiottestnet
```

