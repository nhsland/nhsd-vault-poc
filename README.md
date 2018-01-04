# nhsd-vault-poc
Proof of Concept of Vault use-case for NHS Digital

## Summary

These scripts demonstrate a use of [Hashicorp Vault](https://www.vaultproject.io/) [Transit secret backend](https://www.vaultproject.io/docs/secrets/transit/index.html) to encrypt/decrypt a simple CSV dataset.


## Usage

This PoC is linux/bash centric so YMWV in other environments.

To run thse scripts: clone the repo, pull and run the official Vault container in development mode, set some environment variables to interact with Vault, install Vault on your local machine and create a Transit secret backend.

### Vault container
```
docker pull vault
docker run --privileged --cap-add=IPC_LOCK -e 'VAULT_DEV_ROOT_TOKEN_ID=myroot' -e 'VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200' -p 8200:8200 vault
```

Download and install Vault in the same folder as the clone of the repo.

### Environment variables
```
export VAULT_ADDR="http://127.0.0.1:8200"
export VAULT_TOKEN="myroot"
```

### Create Transit backend
```
vault mount transit
vault write -f transit/keys/foo
```

### Scripts

`poc3.sh` will encrypt/decrypt every cell in a CSV using Vault Transit secret backend.

Encrypt: `./poc3.sh source_csv/patients_no_header_100.csv encrypt`

Decrypt: `./poc3.sh transit_files/cipher_patients_no_header_100.csv decrypt`

Single row decryption:
```
./poc3-row.sh transit_files/cipher_patients_no_header_100.csv 25
ENCRYPTED: 25,vault:v1:rIQa/p4HreKAMX0DGuf6hx0s27vLzB+1YSH3ax81WSpXXdKv/d00kLQ=,vault:v1:4mWKV9GQujLpFtmgwirkWI6bNP4e528lSHqUEkd54g==,vault:v1:ye3FQym4Npj1oDHg19kaI3x5NUW7PH/WATSyTo+wHKtSbg==,vault:v1:W26WVcRD9XSZPf4DOMO4FmhSrSmb9nTj8g5EjZbwWkgS,vault:v1:X2sSOZG8ivd+axTaRNIoDgb75cnfdFbZFnBmLRadRi4E,vault:v1:O0COKct+xik5N8EzmIsKv0YkoCK6AXK4WNausV10r0UtrQ==
DECRYPTED: 25,008 686 6281,no,15.54,7.91,13.3,32.57
```
