package merkle

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"math"

	"gitlab.com/distributed_lab/logan/v3/errors"
)

type BTCMerkleTree struct {
	chunkSize uint64
	chunks    []*MerkleTree
	Tree      *MerkleTree
}

func reverseBytes(data [32]byte) [32]byte {
	for i := 0; i < 16; i++ {
		tmp := data[i]
		data[i] = data[31-i]
		data[31-i] = tmp
	}

	return data
}

func NewBTCMerkleTree(blocksAmount uint64, chunkSize uint64, rpc Rpc) BTCMerkleTree {
	topTree := NewMerkleTree("leaf2", "node2")
	merkleTree := BTCMerkleTree{chunkSize: chunkSize, chunks: make([]*MerkleTree, 0), Tree: &topTree}

	blocksHeaders := getBlocks(blocksAmount, rpc)
	blocks := make([][32]byte, len(blocksHeaders))
	for i := 0; i < len(blocksHeaders); i++ {
		one := sha256.Sum256(blocksHeaders[i])
		blocks[i] = reverseBytes(sha256.Sum256(one[:]))
	}

	for i := 0; i < int(blocksAmount); i += int(chunkSize) {
		amount := min(chunkSize, blocksAmount-uint64(i))
		tree := NewMerkleTree("leaf1", "node1")
		for j := 0; j < int(amount); j++ {
			tree.AddLeaf(blocks[i+j][:])
		}
		merkleTree.chunks = append(merkleTree.chunks, &tree)
	}

	chunksAmount := len(merkleTree.chunks)

	for i := 0; i < chunksAmount; i++ {
		chunkRoot := merkleTree.chunks[i].Root()
		merkleTree.Tree.AddLeaf(chunkRoot[:])
	}

	nextPow := int(math.Pow(2, math.Ceil(math.Log2(float64(chunksAmount)))))

	for i := chunksAmount; i < nextPow; i++ {
		merkleTree.Tree.AddLeaf(make([]byte, 32))
	}

	merkleTree.Tree.BuildTree()

	return merkleTree
}

func (btcmt *BTCMerkleTree) GetMerklePath(blockHeight uint64) ([][32]byte, [][32]byte, error) {
	tree := btcmt.chunks[blockHeight/btcmt.chunkSize]
	merklePath1 := tree.MerklePath(blockHeight % btcmt.chunkSize)
	chunkRoot := tree.Root()
	chunkRoot = btcmt.Tree.HashLeaf(chunkRoot[:])
	chunkIndex := index(chunkRoot, btcmt.Tree.levels[0])
	if chunkIndex == -1 {
		return nil, nil, errors.Errorf("Element not found")
	}
	merklePath2 := btcmt.Tree.MerklePath(uint64(chunkIndex))

	return merklePath1, merklePath2, nil
}

func index(elem [32]byte, collection [][32]byte) int {
	for i, e := range collection {
		if bytes.Equal(e[:], elem[:]) {
			return i
		}
	}

	return -1
}

func getBlocks(amount uint64, rpc Rpc) [][]byte {
	filename := "internal/merkle/headers.json"
	download := false
	var headersBytes [][]byte

	headers := Headers{}
	err := headers.LoadFromFile(filename)
	if err != nil {
		download = true
	}
	
	if headers.Amount < int64(amount) {
		download = true
	}

	for _, h := range headers.HexHeadersData {
		value, err := hex.DecodeString(h)
		if err != nil {
			download = true
			break
		}
		headersBytes = append(headersBytes, value)
	}

	if download {
		headersBytes = append(headersBytes, downloadBlocks(uint64(headers.Amount), amount - uint64(headers.Amount), rpc)...)
		headers.FromBytes(headersBytes)
		headers.SaveToFile(filename)
	}

	return headersBytes
}
