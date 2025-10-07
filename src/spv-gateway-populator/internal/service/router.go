package service

import (
	"github.com/distributed-lab/spv-contract-populator/internal/service/handlers"
	"github.com/go-chi/chi"
	"gitlab.com/distributed_lab/ape"
)

func (s *service) router() chi.Router {
	r := chi.NewRouter()

	r.Use(
		ape.RecoverMiddleware(s.log),
		ape.LoganMiddleware(s.log),
		ape.CtxMiddleware(
			handlers.CtxLog(s.log),
		),
	)
	// r.Route("/integrations/blocks-sync-svc", func(r chi.Router) {
	// 	r.Post("/sync", handlers.Sync)
	// })

	return r
}
