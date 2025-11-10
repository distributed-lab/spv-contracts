package cli

import (
	"github.com/distributed-lab/spv-contract-populator/internal/config"
	"github.com/distributed-lab/spv-contract-populator/internal/service/handlers"
	"gitlab.com/distributed_lab/kit/kv"
	"gitlab.com/distributed_lab/logan/v3"
)

func Run(args []string) bool {
	log := logan.New()

	defer func() {
		if rvr := recover(); rvr != nil {
			log.WithRecover(rvr).Error("app panicked")
		}
	}()

	cfg := config.New(kv.MustFromEnv())
	log = cfg.Log()

	handlers.Sync(cfg)

	return true
}
