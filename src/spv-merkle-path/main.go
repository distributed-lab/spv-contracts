package main

import (
	"os"

	"github.com/distributed-lab/spv-merkle-path/internal/cli"
)

func main() {
	if !cli.Run(os.Args) {
		os.Exit(1)
	}
}
