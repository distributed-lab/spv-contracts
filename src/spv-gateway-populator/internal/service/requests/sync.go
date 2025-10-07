package requests

import (
	"encoding/json"
	"net/http"

	"gitlab.com/distributed_lab/logan/v3/errors"

	"github.com/distributed-lab/spv-contract-populator/resources"
	validation "github.com/go-ozzo/ozzo-validation/v4"
)

type BlockSyncRequest struct {
	Data resources.BlocksSyncRequest
}

func NewBlockSyncRequest(r *http.Request) (BlockSyncRequest, error) {
	request := BlockSyncRequest{}

	if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
		return request, errors.Wrap(err, "failed to unmarshal")
	}

	return request, validate(request)
}

func validate(request BlockSyncRequest) error {
	return validation.ValidateStruct(&request.Data,
		validation.Field(&request.Data.Address, validation.Required, validation.Length(40, 40)),
		validation.Field(&request.Data.FromBlock, validation.Required),
	)
}
