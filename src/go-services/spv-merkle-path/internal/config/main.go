package config

import (
	"encoding/hex"
	"log"

	"github.com/distributed-lab/spv-merkle-path/internal/merkle"
	"gitlab.com/distributed_lab/kit/comfig"
	"gitlab.com/distributed_lab/kit/copus"
	"gitlab.com/distributed_lab/kit/copus/types"
	"gitlab.com/distributed_lab/kit/kv"
)

type Config interface {
	comfig.Logger
	types.Copuser
	comfig.Listenerer
	GetTree() *merkle.BTCMerkleTree
	GetGetter() kv.Getter
}

type config struct {
	comfig.Logger
	types.Copuser
	comfig.Listenerer
	getter kv.Getter
	tree   *merkle.BTCMerkleTree
}

func (c *config) GetTree() *merkle.BTCMerkleTree {
	return c.tree
}

func (c *config) GetGetter() kv.Getter {
	return c.getter
}

func New(getter kv.Getter) Config {
	blocksConfig, err := getter.GetStringMap("blocks")
	if err != nil {
		log.Fatal("Incorrect config...")
	}
	rpcConfig, err := getter.GetStringMap("rpc")
	if err != nil {
		log.Fatal("Incorrect config...")
	}

	blocksAmount := uint64(blocksConfig["amount"].(int))
	chunkSize := uint64(blocksConfig["chunk_size"].(int))
	rpc := merkle.Rpc {Url: rpcConfig["url"].(string), User: rpcConfig["user"].(string), Password: rpcConfig["password"].(string)}
	tree := merkle.NewBTCMerkleTree(blocksAmount, chunkSize, rpc)

	root := tree.Tree.Root()
	log.Printf("Merkle root: %s\n", hex.EncodeToString(root[:]))

	return &config{
		getter:     getter,
		Copuser:    copus.NewCopuser(getter),
		Listenerer: comfig.NewListenerer(getter),
		Logger:     comfig.NewLogger(getter, comfig.LoggerOpts{}),
		tree:       &tree,
	}
}
