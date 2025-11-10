package service

import (
	"net"
	"net/http"

	"github.com/distributed-lab/spv-merkle-path/internal/config"
	"github.com/distributed-lab/spv-merkle-path/internal/merkle"
	"gitlab.com/distributed_lab/kit/copus/types"
	"gitlab.com/distributed_lab/kit/kv"
	"gitlab.com/distributed_lab/logan/v3"
	"gitlab.com/distributed_lab/logan/v3/errors"
)

type service struct {
	getter   kv.Getter
	log      *logan.Entry
	copus    types.Copus
	listener net.Listener
	tree     *merkle.BTCMerkleTree
}

func (s *service) run() error {
	s.log.Info("Service started")
	r := s.router()

	if err := s.copus.RegisterChi(r); err != nil {
		return errors.Wrap(err, "cop failed")
	}

	return http.Serve(s.listener, r)
}

func newService(cfg config.Config) *service {
	return &service{
		log:      cfg.Log(),
		copus:    cfg.Copus(),
		listener: cfg.Listener(),
		getter:   cfg.GetGetter(),
		tree:     cfg.GetTree(),
	}
}

func Run(cfg config.Config) {
	if err := newService(cfg).run(); err != nil {
		panic(err)
	}
}
