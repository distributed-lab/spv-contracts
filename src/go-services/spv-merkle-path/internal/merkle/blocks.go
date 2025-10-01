package merkle

import (
	"encoding/hex"
	"encoding/json"
	"errors"
	"os"
)

type Headers struct {
	Amount         int64    `json:"amount"`
	HexHeadersData []string `json:"headers_hex"`
}

func (h *Headers) FromBytes(bytes [][]byte) {
	h.Amount = int64(len(bytes))
	h.HexHeadersData = make([]string, 0)
	for _, b := range bytes {
		h.HexHeadersData = append(h.HexHeadersData, hex.EncodeToString(b))
	}
}

func (h *Headers) LoadFromFile(path string) error {
	if _, err := os.Stat(path); os.IsNotExist(err) {
		return errors.New("file not exist")
	}

	file, err := os.Open(path)
	if err != nil {
		return err
	}

	decoder := json.NewDecoder(file)
	if err := decoder.Decode(h); err != nil {
		return err
	}

	return nil
}

func (h *Headers) SaveToFile(path string) error {
	file, err := os.Create(path)
	if err != nil {
		return err
	}

	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "  ")
	if err := encoder.Encode(h); err != nil {
		return err
	}

	return nil
}
