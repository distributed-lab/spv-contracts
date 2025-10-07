package requests

import (
	"net/http"
	"strconv"

	"github.com/go-chi/chi"
)

type GetMerklePath struct {
	BlockHeight uint64 `url:"height"`
}

func NewGetMerklePath(r *http.Request) (GetMerklePath, error) {
	request := GetMerklePath{}

	var err error
	request.BlockHeight, err = strconv.ParseUint(chi.URLParam(r, "height"), 10, 64)

	return request, err
}
