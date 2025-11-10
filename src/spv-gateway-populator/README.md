# SPV Gateway Populator

This service automatically fetches new Bitcoin blocks and adds them to the contract at a set time interval.

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