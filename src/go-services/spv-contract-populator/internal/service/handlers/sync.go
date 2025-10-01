package handlers

import (
	"bytes"
	"context"
	"encoding/hex"
	"encoding/json"
	"io"
	"log"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/distributed-lab/spv-contract-populator/internal/config"
	"github.com/distributed-lab/spv-contract-populator/internal/spvcontract"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
	"gitlab.com/distributed_lab/kit/kv"
)

const (
	BlockHeaderSize = 80
	OneReqCount     = 2000
)

type RPCRequest struct {
	Jsonrpc string        `json:"jsonrpc"`
	ID      int           `json:"id"`
	Method  string        `json:"method"`
	Params  []interface{} `json:"params"`
}

type RPCResponse struct {
	Result json.RawMessage `json:"result"`
	Error  interface{}     `json:"error"`
	ID     int             `json:"id"`
}

type Rpc struct {
	Url      string
	User     string
	Password string
}

func Sync() {
	// get required data form config
	cfg := config.New(kv.MustFromEnv())
	node := cfg.GetNode()
	key := cfg.GetPrivKey()
	address := common.HexToAddress(cfg.GetAddress())
	batchSize := cfg.GetBatchSize()
	interval := cfg.GetInterval()
	rpc := Rpc{Url: cfg.GetRpcUrl(), User: cfg.GetRpcUser(), Password: cfg.GetRpcPassword()}

	// connect to node
	client, err := ethclient.Dial(node)
	if err != nil {
		log.Fatalf("Error while connection to node: %v", err)
		return
	}

	// create object of existing contract
	contract, err := spvcontract.NewHistoricalSPVGateway(address, client)
	if err != nil {
		log.Fatalf("Error while creating contract: %v", err)
		return
	}

	privKey, err := crypto.HexToECDSA(key)
	if err != nil {
		log.Fatalf("Error parsing private key: %v", err)
		return
	}

	chainID, err := client.NetworkID(context.Background())
	if err != nil {
		log.Fatalf("Getting network error: %v", err)
		return
	}

	auth, err := bind.NewKeyedTransactorWithChainID(privKey, chainID)
	if err != nil {
		log.Fatalf("Error creating transactor: %v", err)
		return
	}

	limitForOneBlock := uint64(109000)
	auth.GasLimit = limitForOneBlock * uint64(batchSize)

	ticker := time.NewTicker(time.Duration(interval) * time.Minute)
	defer ticker.Stop()

	syncContractChain(contract, auth, client, batchSize, rpc)
	log.Printf("Wait till next sync after %d minutes\n", interval)

	for {
		select {
		case <-ticker.C:
			syncContractChain(contract, auth, client, batchSize, rpc)
			log.Printf("Wait till next sync after %d minutes\n", interval)
		}
	}
}

func syncContractChain(contract *spvcontract.HistoricalSPVGateway, auth *bind.TransactOpts, client *ethclient.Client, batchSize int, rpc Rpc) {
	height, err := contract.GetMainchainHeight(&bind.CallOpts{
		Context: context.Background(),
	})
	if err != nil {
		log.Fatalf("Cannot get height from contract: %v", err)
		return
	}

	// get new blocks
	blocksToAdd := getBlocksFromHeight(height+1, rpc)

	if blocksToAdd == nil {
		return
	}

	// add new blocks
	batchesAmount := len(blocksToAdd) / batchSize
	for i := 0; i < batchesAmount; i++ {
		tx, err := contract.AddBlockHeaderBatch(auth, blocksToAdd[(i*batchSize):((i+1)*batchSize)])
		if err != nil {
			log.Fatalf("Error adding batch of blocks: %v", err)
			return
		}

		log.Printf("Waiting mining...\n")
		receipt, err := bind.WaitMined(context.Background(), client, tx)
		if err != nil {
			log.Fatalf("Error mining block: %v", err)
			return
		}

		if receipt.Status == 0 {
			log.Fatalf("Transaction reverted!")
			return
		}

		log.Printf("Added blocks from %d to %d\n", int(height)+i*batchSize+1, int(height)+i*batchSize)
	}

	// Add one batch that less than batchSize
	if len(blocksToAdd)%batchSize != 0 {
		tx, err := contract.AddBlockHeaderBatch(auth, blocksToAdd[(batchesAmount*batchSize):])
		if err != nil {
			log.Fatalf("Error adding batch of blocks: %v", err)
			return
		}

		log.Printf("Waiting mining...\n")
		receipt, err := bind.WaitMined(context.Background(), client, tx)
		if err != nil {
			log.Fatalf("Error mining block: %v", err)
			return
		}

		if receipt.Status == 0 {
			log.Fatalf("Transaction reverted!")
			return
		}

		log.Printf("Added blocks from %d to %d\n", int(height)+batchesAmount*batchSize+1, int(height)+len(blocksToAdd))
	}
}

func getBlocksFromHeight(height uint64, rpc Rpc) [][]byte {
	var headers [][]byte

	url := "https://blockstream.info/api/blocks/tip/height"
	resp, err := http.Get(url)
	if err != nil {
		log.Print(err)
		return nil
	}

	defer resp.Body.Close()
	height_bytes, err := io.ReadAll(resp.Body)
	if err != nil {
		log.Print(err)
		return nil
	}
	maxHeigth, err := strconv.Atoi(strings.TrimSpace(string(height_bytes)))
	if err != nil {
		log.Print(err)
		return nil
	}

	if maxHeigth == int(height)-1 {
		log.Printf("The chain has an actuating height: %d\n", maxHeigth)
	} else {
		log.Printf("Chain will be synced till block #%d\n", maxHeigth)
	}

	client := &http.Client{}

	for i := 0; i <= (maxHeigth-int(height))/OneReqCount; i++ {
		count := min(OneReqCount, maxHeigth-int(height)-OneReqCount*i)
		start := int(height) + OneReqCount*i
		log.Printf("Pulling blocks (%d) from block #%d\n", count, start)

		var hashRequests []RPCRequest
		for h := start; h < start+count; h++ {
			hashRequests = append(hashRequests, RPCRequest{
				Jsonrpc: "1.0",
				ID:      h,
				Method:  "getblockhash",
				Params:  []interface{}{h},
			})
		}

		reqBytes, _ := json.Marshal(hashRequests)
		httpReq, _ := http.NewRequest("POST", rpc.Url, bytes.NewReader(reqBytes))
		httpReq.SetBasicAuth(rpc.User, rpc.Password)
		httpReq.Header.Set("Content-Type", "application/json")

		resp, err := client.Do(httpReq)
		if err != nil {
			log.Print(err)
			return nil
		}
		defer resp.Body.Close()

		var rpcResp []RPCResponse
		if err := json.NewDecoder(resp.Body).Decode(&rpcResp); err != nil {
			log.Print(err)
			return nil
		}

		var blockHashes []string
		for _, r := range rpcResp {
			var blockHash string

			if r.Error != nil {
				log.Printf("RPC error: %v\n", r.Error)
				return nil
			}

			if err := json.Unmarshal(r.Result, &blockHash); err != nil {
				log.Print(err)
				return nil
			}
			blockHashes = append(blockHashes, blockHash)
		}

		var reqHeaders []RPCRequest
		for _, h := range blockHashes {
			reqHeaders = append(reqHeaders, RPCRequest{
				Jsonrpc: "1.0",
				ID:      1,
				Method:  "getblockheader",
				Params:  []interface{}{h, false},
			})
		}

		reqBytes, _ = json.Marshal(reqHeaders)
		httpReq, _ = http.NewRequest("POST", rpc.Url, bytes.NewReader(reqBytes))
		httpReq.SetBasicAuth(rpc.User, rpc.Password)
		httpReq.Header.Set("Content-Type", "application/json")

		resp, err = client.Do(httpReq)
		if err != nil {
			log.Print(err)
			return nil
		}
		defer resp.Body.Close()

		if err := json.NewDecoder(resp.Body).Decode(&rpcResp); err != nil {
			log.Print(err)
			return nil
		}

		for _, r := range rpcResp {
			var hexStr string
			if err := json.Unmarshal(r.Result, &hexStr); err != nil {
				log.Print(err)
				return nil
			}

			headerBytes, err := hex.DecodeString(hexStr)
			if err != nil {
				log.Print(err)
				return nil
			}

			headers = append(headers, headerBytes)
		}
	}

	return headers
}
