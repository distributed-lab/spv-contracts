package service

import (
	"github.com/distributed-lab/spv-merkle-path/internal/service/handlers"
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
			handlers.CtxTree(s.tree),
			handlers.CtxKVGetter(s.getter),
		),
	)
	r.Route("/integrations/merkle-path", func(r chi.Router) {
		r.Get("/{height}", handlers.GetMerklePath)
	})

	return r
}
