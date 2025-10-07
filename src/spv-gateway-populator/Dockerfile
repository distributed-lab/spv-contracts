FROM golang:1.20-alpine as buildbase

RUN apk add git build-base

WORKDIR /go/src/github.com/distributed-lab/spv-contract-populator
COPY vendor .
COPY . .

RUN GOOS=linux go build  -o /usr/local/bin/blocks-sync-svc /go/src/github.com/distributed-lab/spv-contract-populator


FROM alpine:3.9

COPY --from=buildbase /usr/local/bin/blocks-sync-svc /usr/local/bin/blocks-sync-svc
RUN apk add --no-cache ca-certificates

ENTRYPOINT ["blocks-sync-svc"]
