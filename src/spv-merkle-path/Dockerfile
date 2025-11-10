FROM golang:1.25-alpine as buildbase
ARG CI_JOB_TOKEN

RUN apk add git build-base ca-certificates

WORKDIR /go/src/github.com/distributed-lab/spv-merkle-path
COPY . .

RUN git config --global url."https://gitlab-ci-token:${CI_JOB_TOKEN}@gitlab.com".insteadOf https://gitlab.com
RUN git config --global url."https://${CI_JOB_TOKEN}@github.com/".insteadOf https://github.com/
RUN go env -w GOPRIVATE=github.com/*,gitlab.com/*

RUN go mod tidy && go mod vendor
RUN CGO_ENABLED=1 GO111MODULE=on GOOS=linux go build -o /usr/local/bin/spv-merkle-path /go/src/github.com/distributed-lab/spv-merkle-path

FROM scratch
COPY --from=alpine:3.9 /bin/sh /bin/sh
COPY --from=alpine:3.9 /usr /usr
COPY --from=alpine:3.9 /lib /lib

COPY --from=buildbase /usr/local/bin/spv-merkle-path /usr/local/bin/spv-merkle-path

ENTRYPOINT ["spv-merkle-path-svc"]