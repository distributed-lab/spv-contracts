package handlers

import (
	"context"
	"net/http"

	"github.com/distributed-lab/spv-merkle-path/internal/merkle"
	"gitlab.com/distributed_lab/kit/kv"
	"gitlab.com/distributed_lab/logan/v3"
)

type ctxKey int

const (
	logCtxKey ctxKey = iota
	treeCtxKey
	getterCtxKey
)

func CtxLog(entry *logan.Entry) func(context.Context) context.Context {
	return func(ctx context.Context) context.Context {
		return context.WithValue(ctx, logCtxKey, entry)
	}
}

func Log(r *http.Request) *logan.Entry {
	return r.Context().Value(logCtxKey).(*logan.Entry)
}

func CtxTree(entry *merkle.BTCMerkleTree) func(context.Context) context.Context {
	return func(ctx context.Context) context.Context {
		return context.WithValue(ctx, treeCtxKey, entry)
	}
}

func Tree(r *http.Request) *merkle.BTCMerkleTree {
	return r.Context().Value(treeCtxKey).(*merkle.BTCMerkleTree)
}

func CtxKVGetter(entry kv.Getter) func(context.Context) context.Context {
	return func(ctx context.Context) context.Context {
		return context.WithValue(ctx, getterCtxKey, entry)
	}
}

func KVGetter(r *http.Request) kv.Getter {
	return r.Context().Value(getterCtxKey).(kv.Getter)
}
