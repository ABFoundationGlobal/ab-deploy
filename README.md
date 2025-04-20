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
  - Firewall: The firewall needs to open port 38311 of UDP and TCP, 8801 of TCP.
  - Firewall: Mining node should open port 38311 of UDP and TCP.

## 2. Installation and deployment

### 2.1 Create a working directory and enter it

```bash
mkdir -p ab && cd ab
```

### 2.2 Fetch the `ab.sh` script run it

```bash
# AB Core Mainnet
curl -fsSL https://raw.githubusercontent.com/ABFoundationGlobal/ab-deploy/main/ab.sh | sudo bash -s abcore mainnet
# AB IoT Mainnet
curl -fsSL https://raw.githubusercontent.com/ABFoundationGlobal/ab-deploy/main/ab.sh | sudo bash -s abiot mainnet
# AB Core Testnet
curl -fsSL https://raw.githubusercontent.com/ABFoundationGlobal/ab-deploy/main/ab.sh | sudo bash -s abcore testnet
# AB IoT Testnet
curl -fsSL https://raw.githubusercontent.com/ABFoundationGlobal/ab-deploy/main/ab.sh | sudo bash -s abiot testnet
```

### 2.3 View AB nodes logs

```bash
# AB Core Mainnet
sudo supervisorctl tail -f abcore stderr
# AB IoT Mainnet
sudo supervisorctl tail -f abiot stderr
# AB Core Testnet
sudo supervisorctl tail -f abcoretestnet stderr
# AB IoT Testnet
sudo supervisorctl tail -f abiottestnet stderr
```

## 3. Use AB nodes

- AB nodes's external service port is port 8801, HTTP protocol, which can be used as an RPC interface in AB SDK.

## 4. Operation and maintenance related operations

- Start AB nodes:

```bash
# AB Core Mainnet
sudo supervisorctl start abcore
# AB IoT Mainnet
sudo supervisorctl start abiot
# AB Core Testnet
sudo supervisorctl start abcoretestnet
# AB IoT Testnet
sudo supervisorctl start abiottestnet
```

- Stop AB nodes:

```bash
# AB Core Mainnet
sudo supervisorctl stop abcore
# AB IoT Mainnet
sudo supervisorctl stop abiot
# AB Core Testnet
sudo supervisorctl stop abcoretestnet
# AB IoT Testnet
sudo supervisorctl stop abiottestnet
```

