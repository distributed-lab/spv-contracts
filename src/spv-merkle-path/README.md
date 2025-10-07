# SPV merkle Path

This service provides an API to get a Merkle path, which can be used to prove block inclusion in the verified chain.

## Usage

### 1. Build the service

```bash
go build main.go
```

### 2. Set the configuration file (see example in ../example.config.yaml)

```bash
export KV_VIPER_FILE=./config.yaml
```

### 3. Run the service
```bash
./main run service
```