# nhsd-vault-poc
Proof of Concept of Vault use-case for NHS Digital

## Docker
```
docker pull vault
docker run --privileged --cap-add=IPC_LOCK -e 'VAULT_DEV_ROOT_TOKEN_ID=myroot' -e 'VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200' -p 8200:8200 vault
```

### Environment
```
export VAULT_ADDR="http://127.0.0.1:8200"
export VAULT_TOKEN="myroot"
```


### Backends
```
vault mount transit
vault write -f transit/keys/foo
```
