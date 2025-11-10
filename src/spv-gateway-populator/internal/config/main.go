package config

import (
	"gitlab.com/distributed_lab/kit/comfig"
	"gitlab.com/distributed_lab/kit/copus"
	"gitlab.com/distributed_lab/kit/copus/types"
	"gitlab.com/distributed_lab/kit/kv"
)

type Config interface {
	comfig.Logger
	types.Copuser
	comfig.Listenerer
	GetNode() string
	GetPrivKey() string
	GetAddress() string
	GetBatchSize() int
	GetInterval() int
	GetRpcUrl() string
	GetRpcUser() string
	GetRpcPassword() string
}

type config struct {
	comfig.Logger
	types.Copuser
	comfig.Listenerer
	getter      kv.Getter
	node        string
	privateKey  string
	address     string
	batchSize   int
	interval    int
	rpcUrl      string
	rpcUser     string
	rpcPassword string
}

func (c *config) GetNode() string {
	return c.node
}

func (c *config) GetPrivKey() string {
	return c.privateKey
}

func (c *config) GetAddress() string {
	return c.address
}

func (c *config) GetBatchSize() int {
	return c.batchSize
}

func (c *config) GetInterval() int {
	return c.interval
}

func (c *config) GetRpcUrl() string {
	return c.rpcUrl
}

func (c *config) GetRpcUser() string {
	return c.rpcUser
}

func (c *config) GetRpcPassword() string {
	return c.rpcPassword
}

func New(getter kv.Getter) Config {
	contractConfig, err := getter.GetStringMap("contract")
	if err != nil {
		//
	}

	rpcConfig, err := getter.GetStringMap("rpc")
	if err != nil {
		//
	}

	return &config{
		getter:      getter,
		Copuser:     copus.NewCopuser(getter),
		Listenerer:  comfig.NewListenerer(getter),
		Logger:      comfig.NewLogger(getter, comfig.LoggerOpts{}),
		node:        contractConfig["node"].(string),
		privateKey:  contractConfig["private_key"].(string),
		address:     contractConfig["address"].(string),
		batchSize:   contractConfig["batch_size"].(int),
		interval:    contractConfig["interval"].(int),
		rpcUrl:      rpcConfig["url"].(string),
		rpcUser:     rpcConfig["user"].(string),
		rpcPassword: rpcConfig["password"].(string),
	}
}
