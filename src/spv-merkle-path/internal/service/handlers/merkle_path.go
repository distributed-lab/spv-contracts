package handlers

import (
	"encoding/hex"
	"net/http"

	"github.com/distributed-lab/spv-merkle-path/internal/service/requests"
	"github.com/distributed-lab/spv-merkle-path/resources"
	"gitlab.com/distributed_lab/ape"
	"gitlab.com/distributed_lab/ape/problems"
)

type MPResponse struct {
	Data resources.MerklePathResponse `json:"data"`
}

func reverse(array []string) []string {
	for i := 0; i < len(array)/2; i++ {
		j := len(array) - i - 1
		array[i], array[j] = array[j], array[i]
	}

	return array
}

func GetMerklePath(w http.ResponseWriter, r *http.Request) {
	request, err := requests.NewGetMerklePath(r)
	if err != nil {
		ape.RenderErr(w, problems.BadRequest(err)...)
		return
	}

	kvGetter, _ := KVGetter(r).GetStringMap("blocks")

	blockAmount := kvGetter["amount"].(int)
	if request.BlockHeight >= uint64(blockAmount) {
		ape.RenderErr(w, problems.NotFound())
		return
	}

	tree := Tree(r)
	pathLevel1, pathLevel2, err := tree.GetMerklePath(request.BlockHeight)
	if err != nil {
		ape.RenderErr(w, problems.NotFound())
		return
	}

	hexPath1 := make([]string, len(pathLevel1))
	for i, b := range pathLevel1 {
		hexPath1[i] = hex.EncodeToString(b[:])
	}

	hexPath2 := make([]string, len(pathLevel2))
	for i, b := range pathLevel2 {
		hexPath2[i] = hex.EncodeToString(b[:])
	}

	ape.Render(w, MPResponse{
		Data: resources.MerklePathResponse{
			MerklePathLevel1: reverse(hexPath1),
			MerklePathLevel2: reverse(hexPath2),
		},
	})
}
