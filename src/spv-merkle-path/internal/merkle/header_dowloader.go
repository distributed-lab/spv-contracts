package merkle

import (
	"bytes"
	"encoding/hex"
	"encoding/json"
	"log"
	"net/http"
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

func downloadBlocks(from uint64, amount uint64, rpc Rpc) [][]byte {
	var headers [][]byte
	log.Printf("Downloading %d block...\n", amount)

	client := &http.Client{}

	for i := 0; i <= int(amount)/OneReqCount; i++ {
		count := min(OneReqCount, int(amount)-OneReqCount*i)
		if count == 0 {
			return headers
		}
		start := int(from) + OneReqCount*i
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
