package main

import (
	// "os"

	// "github.com/distributed-lab/spv-contract-populator/internal/cli"
	"github.com/distributed-lab/spv-contract-populator/internal/service/handlers"
)

func main() {
	// if !cli.Run(os.Args) {
	// 	os.Exit(1)
	// }
	
	handlers.Sync()
}
