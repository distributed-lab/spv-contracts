// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package spvcontract

import (
	"errors"
	"math/big"
	"strings"

	ethereum "github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/event"
)

// Reference imports to suppress errors if they are not otherwise used.
var (
	_ = errors.New
	_ = big.NewInt
	_ = strings.NewReader
	_ = ethereum.NotFound
	_ = bind.Bind
	_ = common.Big1
	_ = types.BloomLookup
	_ = event.NewSubscription
	_ = abi.ConvertType
)

// BlockHeaderHeaderData is an auto generated low-level Go binding around an user-defined struct.
type BlockHeaderHeaderData struct {
	PrevBlockHash [32]byte
	MerkleRoot    [32]byte
	Version       uint32
	Time          uint32
	Nonce         uint32
	Bits          [4]byte
}

// BlockHistoryHistoryProofData is an auto generated low-level Go binding around an user-defined struct.
type BlockHistoryHistoryProofData struct {
	Verifier     common.Address
	PublicInputs [][32]byte
	Proof        []byte
}

// IHistoricalSPVGatewayHistoryBlockInclusionProofData is an auto generated low-level Go binding around an user-defined struct.
type IHistoricalSPVGatewayHistoryBlockInclusionProofData struct {
	Level1MerkleProof [][32]byte
	Level2MerkleProof [][32]byte
	BlockHash         [32]byte
	BlockHeight       *big.Int
}

// ISPVGatewayBlockData is an auto generated low-level Go binding around an user-defined struct.
type ISPVGatewayBlockData struct {
	PrevBlockHash [32]byte
	MerkleRoot    [32]byte
	Version       uint32
	Time          uint32
	Nonce         uint32
	Bits          [4]byte
	BlockHeight   uint64
}

// ISPVGatewayBlockInfo is an auto generated low-level Go binding around an user-defined struct.
type ISPVGatewayBlockInfo struct {
	MainBlockData  ISPVGatewayBlockData
	IsInMainchain  bool
	CumulativeWork *big.Int
}

// HistoricalSPVGatewayMetaData contains all meta data concerning the HistoricalSPVGateway contract.
var HistoricalSPVGatewayMetaData = &bind.MetaData{
	ABI: "[{\"inputs\":[{\"internalType\":\"bytes32\",\"name\":\"blockHash\",\"type\":\"bytes32\"}],\"name\":\"BlockAlreadyExists\",\"type\":\"error\"},{\"inputs\":[{\"internalType\":\"bytes32\",\"name\":\"blockHash\",\"type\":\"bytes32\"}],\"name\":\"BlockHashNotInHistory\",\"type\":\"error\"},{\"inputs\":[],\"name\":\"BufferOverflow\",\"type\":\"error\"},{\"inputs\":[{\"internalType\":\"bytes32\",\"name\":\"blockHeaderHash\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"inclusionProofHash\",\"type\":\"bytes32\"}],\"name\":\"DifferentBlockHashes\",\"type\":\"error\"},{\"inputs\":[],\"name\":\"EmptyBlockHeaderArray\",\"type\":\"error\"},{\"inputs\":[{\"internalType\":\"bytes32\",\"name\":\"actualBlockHash\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"blockTarget\",\"type\":\"bytes32\"}],\"name\":\"InvalidBlockHash\",\"type\":\"error\"},{\"inputs\":[],\"name\":\"InvalidBlockHeaderDataLength\",\"type\":\"error\"},{\"inputs\":[],\"name\":\"InvalidBlockHeadersOrder\",\"type\":\"error\"},{\"inputs\":[{\"internalType\":\"uint32\",\"name\":\"blockTime\",\"type\":\"uint32\"},{\"internalType\":\"uint32\",\"name\":\"medianTime\",\"type\":\"uint32\"}],\"name\":\"InvalidBlockTime\",\"type\":\"error\"},{\"inputs\":[],\"name\":\"InvalidHistoryBlocksTreeRoot\",\"type\":\"error\"},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"blockHeight\",\"type\":\"uint64\"}],\"name\":\"InvalidInitialBlockHeight\",\"type\":\"error\"},{\"inputs\":[],\"name\":\"InvalidInitialization\",\"type\":\"error\"},{\"inputs\":[],\"name\":\"InvalidMerkleNode\",\"type\":\"error\"},{\"inputs\":[],\"name\":\"InvalidProof\",\"type\":\"error\"},{\"inputs\":[],\"name\":\"InvalidProofBlockHash\",\"type\":\"error\"},{\"inputs\":[],\"name\":\"InvalidProofBlockHeight\",\"type\":\"error\"},{\"inputs\":[],\"name\":\"InvalidProofCumulativeWork\",\"type\":\"error\"},{\"inputs\":[{\"internalType\":\"bytes32\",\"name\":\"blockTarget\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"networkTarget\",\"type\":\"bytes32\"}],\"name\":\"InvalidTarget\",\"type\":\"error\"},{\"inputs\":[],\"name\":\"NotInitializing\",\"type\":\"error\"},{\"inputs\":[{\"internalType\":\"bytes32\",\"name\":\"prevBlockHash\",\"type\":\"bytes32\"}],\"name\":\"PrevBlockDoesNotExist\",\"type\":\"error\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"uint64\",\"name\":\"blockHeight\",\"type\":\"uint64\"},{\"indexed\":true,\"internalType\":\"bytes32\",\"name\":\"blockHash\",\"type\":\"bytes32\"}],\"name\":\"BlockHeaderAdded\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":false,\"internalType\":\"uint64\",\"name\":\"version\",\"type\":\"uint64\"}],\"name\":\"Initialized\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"uint64\",\"name\":\"newMainchainHeight\",\"type\":\"uint64\"},{\"indexed\":true,\"internalType\":\"bytes32\",\"name\":\"newMainchainHead\",\"type\":\"bytes32\"}],\"name\":\"MainchainHeadUpdated\",\"type\":\"event\"},{\"inputs\":[],\"name\":\"HISTORICAL_SPV_GATEWAY_STORAGE_SLOT\",\"outputs\":[{\"internalType\":\"bytes32\",\"name\":\"\",\"type\":\"bytes32\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"MEDIAN_PAST_BLOCKS\",\"outputs\":[{\"internalType\":\"uint8\",\"name\":\"\",\"type\":\"uint8\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"SPV_GATEWAY_STORAGE_SLOT\",\"outputs\":[{\"internalType\":\"bytes32\",\"name\":\"\",\"type\":\"bytes32\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"bytes\",\"name\":\"blockHeaderRaw_\",\"type\":\"bytes\"},{\"internalType\":\"uint64\",\"name\":\"blockHeight_\",\"type\":\"uint64\"},{\"internalType\":\"uint256\",\"name\":\"cumulativeWork_\",\"type\":\"uint256\"},{\"internalType\":\"bytes32\",\"name\":\"historyBlocksTreeRoot_\",\"type\":\"bytes32\"},{\"components\":[{\"internalType\":\"address\",\"name\":\"verifier\",\"type\":\"address\"},{\"internalType\":\"bytes32[]\",\"name\":\"publicInputs\",\"type\":\"bytes32[]\"},{\"internalType\":\"bytes\",\"name\":\"proof\",\"type\":\"bytes\"}],\"internalType\":\"structBlockHistory.HistoryProofData\",\"name\":\"proofData_\",\"type\":\"tuple\"}],\"name\":\"__HistoricalSPVGateway_init\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"bytes\",\"name\":\"blockHeaderRaw_\",\"type\":\"bytes\"},{\"internalType\":\"uint64\",\"name\":\"blockHeight_\",\"type\":\"uint64\"},{\"internalType\":\"uint256\",\"name\":\"cumulativeWork_\",\"type\":\"uint256\"}],\"name\":\"__SPVGateway_init\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"__SPVGateway_init_genesis\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"bytes\",\"name\":\"blockHeaderRaw_\",\"type\":\"bytes\"}],\"name\":\"addBlockHeader\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"bytes[]\",\"name\":\"blockHeaderRawArray_\",\"type\":\"bytes[]\"}],\"name\":\"addBlockHeaderBatch\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"bytes32\",\"name\":\"blockHash_\",\"type\":\"bytes32\"}],\"name\":\"blockExists\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"\",\"type\":\"bool\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"components\":[{\"internalType\":\"bytes32[]\",\"name\":\"level1MerkleProof\",\"type\":\"bytes32[]\"},{\"internalType\":\"bytes32[]\",\"name\":\"level2MerkleProof\",\"type\":\"bytes32[]\"},{\"internalType\":\"bytes32\",\"name\":\"blockHash\",\"type\":\"bytes32\"},{\"internalType\":\"uint256\",\"name\":\"blockHeight\",\"type\":\"uint256\"}],\"internalType\":\"structIHistoricalSPVGateway.HistoryBlockInclusionProofData\",\"name\":\"inclusionProofData_\",\"type\":\"tuple\"}],\"name\":\"checkHistoryBlockInclusion\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"\",\"type\":\"bool\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"bytes32[]\",\"name\":\"merkleProof_\",\"type\":\"bytes32[]\"},{\"internalType\":\"bytes\",\"name\":\"blockHeaderRaw_\",\"type\":\"bytes\"},{\"internalType\":\"bytes32\",\"name\":\"txId_\",\"type\":\"bytes32\"},{\"internalType\":\"uint256\",\"name\":\"txIndex_\",\"type\":\"uint256\"},{\"components\":[{\"internalType\":\"bytes32[]\",\"name\":\"level1MerkleProof\",\"type\":\"bytes32[]\"},{\"internalType\":\"bytes32[]\",\"name\":\"level2MerkleProof\",\"type\":\"bytes32[]\"},{\"internalType\":\"bytes32\",\"name\":\"blockHash\",\"type\":\"bytes32\"},{\"internalType\":\"uint256\",\"name\":\"blockHeight\",\"type\":\"uint256\"}],\"internalType\":\"structIHistoricalSPVGateway.HistoryBlockInclusionProofData\",\"name\":\"blockInclusionProofData_\",\"type\":\"tuple\"}],\"name\":\"checkHistoryTxInclusion\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"\",\"type\":\"bool\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"bytes32[]\",\"name\":\"merkleProof_\",\"type\":\"bytes32[]\"},{\"internalType\":\"bytes32\",\"name\":\"blockHash_\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"txId_\",\"type\":\"bytes32\"},{\"internalType\":\"uint256\",\"name\":\"txIndex_\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"minConfirmationsCount_\",\"type\":\"uint256\"}],\"name\":\"checkTxInclusion\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"\",\"type\":\"bool\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"blockHeight_\",\"type\":\"uint64\"}],\"name\":\"getBlockHash\",\"outputs\":[{\"internalType\":\"bytes32\",\"name\":\"\",\"type\":\"bytes32\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"bytes32\",\"name\":\"blockHash_\",\"type\":\"bytes32\"}],\"name\":\"getBlockHeader\",\"outputs\":[{\"components\":[{\"internalType\":\"bytes32\",\"name\":\"prevBlockHash\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"merkleRoot\",\"type\":\"bytes32\"},{\"internalType\":\"uint32\",\"name\":\"version\",\"type\":\"uint32\"},{\"internalType\":\"uint32\",\"name\":\"time\",\"type\":\"uint32\"},{\"internalType\":\"uint32\",\"name\":\"nonce\",\"type\":\"uint32\"},{\"internalType\":\"bytes4\",\"name\":\"bits\",\"type\":\"bytes4\"}],\"internalType\":\"structBlockHeader.HeaderData\",\"name\":\"\",\"type\":\"tuple\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"bytes32\",\"name\":\"blockHash_\",\"type\":\"bytes32\"}],\"name\":\"getBlockHeight\",\"outputs\":[{\"internalType\":\"uint64\",\"name\":\"\",\"type\":\"uint64\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"bytes32\",\"name\":\"blockHash_\",\"type\":\"bytes32\"}],\"name\":\"getBlockInfo\",\"outputs\":[{\"components\":[{\"components\":[{\"internalType\":\"bytes32\",\"name\":\"prevBlockHash\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"merkleRoot\",\"type\":\"bytes32\"},{\"internalType\":\"uint32\",\"name\":\"version\",\"type\":\"uint32\"},{\"internalType\":\"uint32\",\"name\":\"time\",\"type\":\"uint32\"},{\"internalType\":\"uint32\",\"name\":\"nonce\",\"type\":\"uint32\"},{\"internalType\":\"bytes4\",\"name\":\"bits\",\"type\":\"bytes4\"},{\"internalType\":\"uint64\",\"name\":\"blockHeight\",\"type\":\"uint64\"}],\"internalType\":\"structISPVGateway.BlockData\",\"name\":\"mainBlockData\",\"type\":\"tuple\"},{\"internalType\":\"bool\",\"name\":\"isInMainchain\",\"type\":\"bool\"},{\"internalType\":\"uint256\",\"name\":\"cumulativeWork\",\"type\":\"uint256\"}],\"internalType\":\"structISPVGateway.BlockInfo\",\"name\":\"blockInfo_\",\"type\":\"tuple\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"bytes32\",\"name\":\"blockHash_\",\"type\":\"bytes32\"}],\"name\":\"getBlockMerkleRoot\",\"outputs\":[{\"internalType\":\"bytes32\",\"name\":\"\",\"type\":\"bytes32\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"bytes32\",\"name\":\"blockHash_\",\"type\":\"bytes32\"}],\"name\":\"getBlockStatus\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"\",\"type\":\"bool\"},{\"internalType\":\"uint64\",\"name\":\"\",\"type\":\"uint64\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"bytes32\",\"name\":\"blockHash_\",\"type\":\"bytes32\"}],\"name\":\"getBlockTarget\",\"outputs\":[{\"internalType\":\"bytes32\",\"name\":\"\",\"type\":\"bytes32\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"getHistoryBlocksCount\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"getHistoryBlocksTreeRoot\",\"outputs\":[{\"internalType\":\"bytes32\",\"name\":\"\",\"type\":\"bytes32\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"getLastEpochCumulativeWork\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"getMainchainHead\",\"outputs\":[{\"internalType\":\"bytes32\",\"name\":\"\",\"type\":\"bytes32\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"getMainchainHeight\",\"outputs\":[{\"internalType\":\"uint64\",\"name\":\"\",\"type\":\"uint64\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"bytes32\",\"name\":\"blockHash_\",\"type\":\"bytes32\"}],\"name\":\"isInMainchain\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"\",\"type\":\"bool\"}],\"stateMutability\":\"view\",\"type\":\"function\"}]",
}

// HistoricalSPVGatewayABI is the input ABI used to generate the binding from.
// Deprecated: Use HistoricalSPVGatewayMetaData.ABI instead.
var HistoricalSPVGatewayABI = HistoricalSPVGatewayMetaData.ABI

// HistoricalSPVGateway is an auto generated Go binding around an Ethereum contract.
type HistoricalSPVGateway struct {
	HistoricalSPVGatewayCaller     // Read-only binding to the contract
	HistoricalSPVGatewayTransactor // Write-only binding to the contract
	HistoricalSPVGatewayFilterer   // Log filterer for contract events
}

// HistoricalSPVGatewayCaller is an auto generated read-only Go binding around an Ethereum contract.
type HistoricalSPVGatewayCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// HistoricalSPVGatewayTransactor is an auto generated write-only Go binding around an Ethereum contract.
type HistoricalSPVGatewayTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// HistoricalSPVGatewayFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type HistoricalSPVGatewayFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// HistoricalSPVGatewaySession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type HistoricalSPVGatewaySession struct {
	Contract     *HistoricalSPVGateway // Generic contract binding to set the session for
	CallOpts     bind.CallOpts         // Call options to use throughout this session
	TransactOpts bind.TransactOpts     // Transaction auth options to use throughout this session
}

// HistoricalSPVGatewayCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type HistoricalSPVGatewayCallerSession struct {
	Contract *HistoricalSPVGatewayCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts               // Call options to use throughout this session
}

// HistoricalSPVGatewayTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type HistoricalSPVGatewayTransactorSession struct {
	Contract     *HistoricalSPVGatewayTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts               // Transaction auth options to use throughout this session
}

// HistoricalSPVGatewayRaw is an auto generated low-level Go binding around an Ethereum contract.
type HistoricalSPVGatewayRaw struct {
	Contract *HistoricalSPVGateway // Generic contract binding to access the raw methods on
}

// HistoricalSPVGatewayCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type HistoricalSPVGatewayCallerRaw struct {
	Contract *HistoricalSPVGatewayCaller // Generic read-only contract binding to access the raw methods on
}

// HistoricalSPVGatewayTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type HistoricalSPVGatewayTransactorRaw struct {
	Contract *HistoricalSPVGatewayTransactor // Generic write-only contract binding to access the raw methods on
}

// NewHistoricalSPVGateway creates a new instance of HistoricalSPVGateway, bound to a specific deployed contract.
func NewHistoricalSPVGateway(address common.Address, backend bind.ContractBackend) (*HistoricalSPVGateway, error) {
	contract, err := bindHistoricalSPVGateway(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &HistoricalSPVGateway{HistoricalSPVGatewayCaller: HistoricalSPVGatewayCaller{contract: contract}, HistoricalSPVGatewayTransactor: HistoricalSPVGatewayTransactor{contract: contract}, HistoricalSPVGatewayFilterer: HistoricalSPVGatewayFilterer{contract: contract}}, nil
}

// NewHistoricalSPVGatewayCaller creates a new read-only instance of HistoricalSPVGateway, bound to a specific deployed contract.
func NewHistoricalSPVGatewayCaller(address common.Address, caller bind.ContractCaller) (*HistoricalSPVGatewayCaller, error) {
	contract, err := bindHistoricalSPVGateway(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &HistoricalSPVGatewayCaller{contract: contract}, nil
}

// NewHistoricalSPVGatewayTransactor creates a new write-only instance of HistoricalSPVGateway, bound to a specific deployed contract.
func NewHistoricalSPVGatewayTransactor(address common.Address, transactor bind.ContractTransactor) (*HistoricalSPVGatewayTransactor, error) {
	contract, err := bindHistoricalSPVGateway(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &HistoricalSPVGatewayTransactor{contract: contract}, nil
}

// NewHistoricalSPVGatewayFilterer creates a new log filterer instance of HistoricalSPVGateway, bound to a specific deployed contract.
func NewHistoricalSPVGatewayFilterer(address common.Address, filterer bind.ContractFilterer) (*HistoricalSPVGatewayFilterer, error) {
	contract, err := bindHistoricalSPVGateway(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &HistoricalSPVGatewayFilterer{contract: contract}, nil
}

// bindHistoricalSPVGateway binds a generic wrapper to an already deployed contract.
func bindHistoricalSPVGateway(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := HistoricalSPVGatewayMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_HistoricalSPVGateway *HistoricalSPVGatewayRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _HistoricalSPVGateway.Contract.HistoricalSPVGatewayCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_HistoricalSPVGateway *HistoricalSPVGatewayRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _HistoricalSPVGateway.Contract.HistoricalSPVGatewayTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_HistoricalSPVGateway *HistoricalSPVGatewayRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _HistoricalSPVGateway.Contract.HistoricalSPVGatewayTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_HistoricalSPVGateway *HistoricalSPVGatewayCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _HistoricalSPVGateway.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_HistoricalSPVGateway *HistoricalSPVGatewayTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _HistoricalSPVGateway.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_HistoricalSPVGateway *HistoricalSPVGatewayTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _HistoricalSPVGateway.Contract.contract.Transact(opts, method, params...)
}

// HISTORICALSPVGATEWAYSTORAGESLOT is a free data retrieval call binding the contract method 0xfdcde997.
//
// Solidity: function HISTORICAL_SPV_GATEWAY_STORAGE_SLOT() view returns(bytes32)
func (_HistoricalSPVGateway *HistoricalSPVGatewayCaller) HISTORICALSPVGATEWAYSTORAGESLOT(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _HistoricalSPVGateway.contract.Call(opts, &out, "HISTORICAL_SPV_GATEWAY_STORAGE_SLOT")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// HISTORICALSPVGATEWAYSTORAGESLOT is a free data retrieval call binding the contract method 0xfdcde997.
//
// Solidity: function HISTORICAL_SPV_GATEWAY_STORAGE_SLOT() view returns(bytes32)
func (_HistoricalSPVGateway *HistoricalSPVGatewaySession) HISTORICALSPVGATEWAYSTORAGESLOT() ([32]byte, error) {
	return _HistoricalSPVGateway.Contract.HISTORICALSPVGATEWAYSTORAGESLOT(&_HistoricalSPVGateway.CallOpts)
}

// HISTORICALSPVGATEWAYSTORAGESLOT is a free data retrieval call binding the contract method 0xfdcde997.
//
// Solidity: function HISTORICAL_SPV_GATEWAY_STORAGE_SLOT() view returns(bytes32)
func (_HistoricalSPVGateway *HistoricalSPVGatewayCallerSession) HISTORICALSPVGATEWAYSTORAGESLOT() ([32]byte, error) {
	return _HistoricalSPVGateway.Contract.HISTORICALSPVGATEWAYSTORAGESLOT(&_HistoricalSPVGateway.CallOpts)
}

// MEDIANPASTBLOCKS is a free data retrieval call binding the contract method 0xe0686a04.
//
// Solidity: function MEDIAN_PAST_BLOCKS() view returns(uint8)
func (_HistoricalSPVGateway *HistoricalSPVGatewayCaller) MEDIANPASTBLOCKS(opts *bind.CallOpts) (uint8, error) {
	var out []interface{}
	err := _HistoricalSPVGateway.contract.Call(opts, &out, "MEDIAN_PAST_BLOCKS")

	if err != nil {
		return *new(uint8), err
	}

	out0 := *abi.ConvertType(out[0], new(uint8)).(*uint8)

	return out0, err

}

// MEDIANPASTBLOCKS is a free data retrieval call binding the contract method 0xe0686a04.
//
// Solidity: function MEDIAN_PAST_BLOCKS() view returns(uint8)
func (_HistoricalSPVGateway *HistoricalSPVGatewaySession) MEDIANPASTBLOCKS() (uint8, error) {
	return _HistoricalSPVGateway.Contract.MEDIANPASTBLOCKS(&_HistoricalSPVGateway.CallOpts)
}

// MEDIANPASTBLOCKS is a free data retrieval call binding the contract method 0xe0686a04.
//
// Solidity: function MEDIAN_PAST_BLOCKS() view returns(uint8)
func (_HistoricalSPVGateway *HistoricalSPVGatewayCallerSession) MEDIANPASTBLOCKS() (uint8, error) {
	return _HistoricalSPVGateway.Contract.MEDIANPASTBLOCKS(&_HistoricalSPVGateway.CallOpts)
}

// SPVGATEWAYSTORAGESLOT is a free data retrieval call binding the contract method 0xc82aa45e.
//
// Solidity: function SPV_GATEWAY_STORAGE_SLOT() view returns(bytes32)
func (_HistoricalSPVGateway *HistoricalSPVGatewayCaller) SPVGATEWAYSTORAGESLOT(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _HistoricalSPVGateway.contract.Call(opts, &out, "SPV_GATEWAY_STORAGE_SLOT")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// SPVGATEWAYSTORAGESLOT is a free data retrieval call binding the contract method 0xc82aa45e.
//
// Solidity: function SPV_GATEWAY_STORAGE_SLOT() view returns(bytes32)
func (_HistoricalSPVGateway *HistoricalSPVGatewaySession) SPVGATEWAYSTORAGESLOT() ([32]byte, error) {
	return _HistoricalSPVGateway.Contract.SPVGATEWAYSTORAGESLOT(&_HistoricalSPVGateway.CallOpts)
}

// SPVGATEWAYSTORAGESLOT is a free data retrieval call binding the contract method 0xc82aa45e.
//
// Solidity: function SPV_GATEWAY_STORAGE_SLOT() view returns(bytes32)
func (_HistoricalSPVGateway *HistoricalSPVGatewayCallerSession) SPVGATEWAYSTORAGESLOT() ([32]byte, error) {
	return _HistoricalSPVGateway.Contract.SPVGATEWAYSTORAGESLOT(&_HistoricalSPVGateway.CallOpts)
}

// BlockExists is a free data retrieval call binding the contract method 0x9739ec58.
//
// Solidity: function blockExists(bytes32 blockHash_) view returns(bool)
func (_HistoricalSPVGateway *HistoricalSPVGatewayCaller) BlockExists(opts *bind.CallOpts, blockHash_ [32]byte) (bool, error) {
	var out []interface{}
	err := _HistoricalSPVGateway.contract.Call(opts, &out, "blockExists", blockHash_)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// BlockExists is a free data retrieval call binding the contract method 0x9739ec58.
//
// Solidity: function blockExists(bytes32 blockHash_) view returns(bool)
func (_HistoricalSPVGateway *HistoricalSPVGatewaySession) BlockExists(blockHash_ [32]byte) (bool, error) {
	return _HistoricalSPVGateway.Contract.BlockExists(&_HistoricalSPVGateway.CallOpts, blockHash_)
}

// BlockExists is a free data retrieval call binding the contract method 0x9739ec58.
//
// Solidity: function blockExists(bytes32 blockHash_) view returns(bool)
func (_HistoricalSPVGateway *HistoricalSPVGatewayCallerSession) BlockExists(blockHash_ [32]byte) (bool, error) {
	return _HistoricalSPVGateway.Contract.BlockExists(&_HistoricalSPVGateway.CallOpts, blockHash_)
}

// CheckHistoryBlockInclusion is a free data retrieval call binding the contract method 0xb174856f.
//
// Solidity: function checkHistoryBlockInclusion((bytes32[],bytes32[],bytes32,uint256) inclusionProofData_) view returns(bool)
func (_HistoricalSPVGateway *HistoricalSPVGatewayCaller) CheckHistoryBlockInclusion(opts *bind.CallOpts, inclusionProofData_ IHistoricalSPVGatewayHistoryBlockInclusionProofData) (bool, error) {
	var out []interface{}
	err := _HistoricalSPVGateway.contract.Call(opts, &out, "checkHistoryBlockInclusion", inclusionProofData_)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// CheckHistoryBlockInclusion is a free data retrieval call binding the contract method 0xb174856f.
//
// Solidity: function checkHistoryBlockInclusion((bytes32[],bytes32[],bytes32,uint256) inclusionProofData_) view returns(bool)
func (_HistoricalSPVGateway *HistoricalSPVGatewaySession) CheckHistoryBlockInclusion(inclusionProofData_ IHistoricalSPVGatewayHistoryBlockInclusionProofData) (bool, error) {
	return _HistoricalSPVGateway.Contract.CheckHistoryBlockInclusion(&_HistoricalSPVGateway.CallOpts, inclusionProofData_)
}

// CheckHistoryBlockInclusion is a free data retrieval call binding the contract method 0xb174856f.
//
// Solidity: function checkHistoryBlockInclusion((bytes32[],bytes32[],bytes32,uint256) inclusionProofData_) view returns(bool)
func (_HistoricalSPVGateway *HistoricalSPVGatewayCallerSession) CheckHistoryBlockInclusion(inclusionProofData_ IHistoricalSPVGatewayHistoryBlockInclusionProofData) (bool, error) {
	return _HistoricalSPVGateway.Contract.CheckHistoryBlockInclusion(&_HistoricalSPVGateway.CallOpts, inclusionProofData_)
}

// CheckHistoryTxInclusion is a free data retrieval call binding the contract method 0x4de6ca20.
//
// Solidity: function checkHistoryTxInclusion(bytes32[] merkleProof_, bytes blockHeaderRaw_, bytes32 txId_, uint256 txIndex_, (bytes32[],bytes32[],bytes32,uint256) blockInclusionProofData_) view returns(bool)
func (_HistoricalSPVGateway *HistoricalSPVGatewayCaller) CheckHistoryTxInclusion(opts *bind.CallOpts, merkleProof_ [][32]byte, blockHeaderRaw_ []byte, txId_ [32]byte, txIndex_ *big.Int, blockInclusionProofData_ IHistoricalSPVGatewayHistoryBlockInclusionProofData) (bool, error) {
	var out []interface{}
	err := _HistoricalSPVGateway.contract.Call(opts, &out, "checkHistoryTxInclusion", merkleProof_, blockHeaderRaw_, txId_, txIndex_, blockInclusionProofData_)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// CheckHistoryTxInclusion is a free data retrieval call binding the contract method 0x4de6ca20.
//
// Solidity: function checkHistoryTxInclusion(bytes32[] merkleProof_, bytes blockHeaderRaw_, bytes32 txId_, uint256 txIndex_, (bytes32[],bytes32[],bytes32,uint256) blockInclusionProofData_) view returns(bool)
func (_HistoricalSPVGateway *HistoricalSPVGatewaySession) CheckHistoryTxInclusion(merkleProof_ [][32]byte, blockHeaderRaw_ []byte, txId_ [32]byte, txIndex_ *big.Int, blockInclusionProofData_ IHistoricalSPVGatewayHistoryBlockInclusionProofData) (bool, error) {
	return _HistoricalSPVGateway.Contract.CheckHistoryTxInclusion(&_HistoricalSPVGateway.CallOpts, merkleProof_, blockHeaderRaw_, txId_, txIndex_, blockInclusionProofData_)
}

// CheckHistoryTxInclusion is a free data retrieval call binding the contract method 0x4de6ca20.
//
// Solidity: function checkHistoryTxInclusion(bytes32[] merkleProof_, bytes blockHeaderRaw_, bytes32 txId_, uint256 txIndex_, (bytes32[],bytes32[],bytes32,uint256) blockInclusionProofData_) view returns(bool)
func (_HistoricalSPVGateway *HistoricalSPVGatewayCallerSession) CheckHistoryTxInclusion(merkleProof_ [][32]byte, blockHeaderRaw_ []byte, txId_ [32]byte, txIndex_ *big.Int, blockInclusionProofData_ IHistoricalSPVGatewayHistoryBlockInclusionProofData) (bool, error) {
	return _HistoricalSPVGateway.Contract.CheckHistoryTxInclusion(&_HistoricalSPVGateway.CallOpts, merkleProof_, blockHeaderRaw_, txId_, txIndex_, blockInclusionProofData_)
}

// CheckTxInclusion is a free data retrieval call binding the contract method 0xb85b36fb.
//
// Solidity: function checkTxInclusion(bytes32[] merkleProof_, bytes32 blockHash_, bytes32 txId_, uint256 txIndex_, uint256 minConfirmationsCount_) view returns(bool)
func (_HistoricalSPVGateway *HistoricalSPVGatewayCaller) CheckTxInclusion(opts *bind.CallOpts, merkleProof_ [][32]byte, blockHash_ [32]byte, txId_ [32]byte, txIndex_ *big.Int, minConfirmationsCount_ *big.Int) (bool, error) {
	var out []interface{}
	err := _HistoricalSPVGateway.contract.Call(opts, &out, "checkTxInclusion", merkleProof_, blockHash_, txId_, txIndex_, minConfirmationsCount_)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// CheckTxInclusion is a free data retrieval call binding the contract method 0xb85b36fb.
//
// Solidity: function checkTxInclusion(bytes32[] merkleProof_, bytes32 blockHash_, bytes32 txId_, uint256 txIndex_, uint256 minConfirmationsCount_) view returns(bool)
func (_HistoricalSPVGateway *HistoricalSPVGatewaySession) CheckTxInclusion(merkleProof_ [][32]byte, blockHash_ [32]byte, txId_ [32]byte, txIndex_ *big.Int, minConfirmationsCount_ *big.Int) (bool, error) {
	return _HistoricalSPVGateway.Contract.CheckTxInclusion(&_HistoricalSPVGateway.CallOpts, merkleProof_, blockHash_, txId_, txIndex_, minConfirmationsCount_)
}

// CheckTxInclusion is a free data retrieval call binding the contract method 0xb85b36fb.
//
// Solidity: function checkTxInclusion(bytes32[] merkleProof_, bytes32 blockHash_, bytes32 txId_, uint256 txIndex_, uint256 minConfirmationsCount_) view returns(bool)
func (_HistoricalSPVGateway *HistoricalSPVGatewayCallerSession) CheckTxInclusion(merkleProof_ [][32]byte, blockHash_ [32]byte, txId_ [32]byte, txIndex_ *big.Int, minConfirmationsCount_ *big.Int) (bool, error) {
	return _HistoricalSPVGateway.Contract.CheckTxInclusion(&_HistoricalSPVGateway.CallOpts, merkleProof_, blockHash_, txId_, txIndex_, minConfirmationsCount_)
}

// GetBlockHash is a free data retrieval call binding the contract method 0x23ac7136.
//
// Solidity: function getBlockHash(uint64 blockHeight_) view returns(bytes32)
func (_HistoricalSPVGateway *HistoricalSPVGatewayCaller) GetBlockHash(opts *bind.CallOpts, blockHeight_ uint64) ([32]byte, error) {
	var out []interface{}
	err := _HistoricalSPVGateway.contract.Call(opts, &out, "getBlockHash", blockHeight_)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GetBlockHash is a free data retrieval call binding the contract method 0x23ac7136.
//
// Solidity: function getBlockHash(uint64 blockHeight_) view returns(bytes32)
func (_HistoricalSPVGateway *HistoricalSPVGatewaySession) GetBlockHash(blockHeight_ uint64) ([32]byte, error) {
	return _HistoricalSPVGateway.Contract.GetBlockHash(&_HistoricalSPVGateway.CallOpts, blockHeight_)
}

// GetBlockHash is a free data retrieval call binding the contract method 0x23ac7136.
//
// Solidity: function getBlockHash(uint64 blockHeight_) view returns(bytes32)
func (_HistoricalSPVGateway *HistoricalSPVGatewayCallerSession) GetBlockHash(blockHeight_ uint64) ([32]byte, error) {
	return _HistoricalSPVGateway.Contract.GetBlockHash(&_HistoricalSPVGateway.CallOpts, blockHeight_)
}

// GetBlockHeader is a free data retrieval call binding the contract method 0x6b4f9b9d.
//
// Solidity: function getBlockHeader(bytes32 blockHash_) view returns((bytes32,bytes32,uint32,uint32,uint32,bytes4))
func (_HistoricalSPVGateway *HistoricalSPVGatewayCaller) GetBlockHeader(opts *bind.CallOpts, blockHash_ [32]byte) (BlockHeaderHeaderData, error) {
	var out []interface{}
	err := _HistoricalSPVGateway.contract.Call(opts, &out, "getBlockHeader", blockHash_)

	if err != nil {
		return *new(BlockHeaderHeaderData), err
	}

	out0 := *abi.ConvertType(out[0], new(BlockHeaderHeaderData)).(*BlockHeaderHeaderData)

	return out0, err

}

// GetBlockHeader is a free data retrieval call binding the contract method 0x6b4f9b9d.
//
// Solidity: function getBlockHeader(bytes32 blockHash_) view returns((bytes32,bytes32,uint32,uint32,uint32,bytes4))
func (_HistoricalSPVGateway *HistoricalSPVGatewaySession) GetBlockHeader(blockHash_ [32]byte) (BlockHeaderHeaderData, error) {
	return _HistoricalSPVGateway.Contract.GetBlockHeader(&_HistoricalSPVGateway.CallOpts, blockHash_)
}

// GetBlockHeader is a free data retrieval call binding the contract method 0x6b4f9b9d.
//
// Solidity: function getBlockHeader(bytes32 blockHash_) view returns((bytes32,bytes32,uint32,uint32,uint32,bytes4))
func (_HistoricalSPVGateway *HistoricalSPVGatewayCallerSession) GetBlockHeader(blockHash_ [32]byte) (BlockHeaderHeaderData, error) {
	return _HistoricalSPVGateway.Contract.GetBlockHeader(&_HistoricalSPVGateway.CallOpts, blockHash_)
}

// GetBlockHeight is a free data retrieval call binding the contract method 0x2df0696c.
//
// Solidity: function getBlockHeight(bytes32 blockHash_) view returns(uint64)
func (_HistoricalSPVGateway *HistoricalSPVGatewayCaller) GetBlockHeight(opts *bind.CallOpts, blockHash_ [32]byte) (uint64, error) {
	var out []interface{}
	err := _HistoricalSPVGateway.contract.Call(opts, &out, "getBlockHeight", blockHash_)

	if err != nil {
		return *new(uint64), err
	}

	out0 := *abi.ConvertType(out[0], new(uint64)).(*uint64)

	return out0, err

}

// GetBlockHeight is a free data retrieval call binding the contract method 0x2df0696c.
//
// Solidity: function getBlockHeight(bytes32 blockHash_) view returns(uint64)
func (_HistoricalSPVGateway *HistoricalSPVGatewaySession) GetBlockHeight(blockHash_ [32]byte) (uint64, error) {
	return _HistoricalSPVGateway.Contract.GetBlockHeight(&_HistoricalSPVGateway.CallOpts, blockHash_)
}

// GetBlockHeight is a free data retrieval call binding the contract method 0x2df0696c.
//
// Solidity: function getBlockHeight(bytes32 blockHash_) view returns(uint64)
func (_HistoricalSPVGateway *HistoricalSPVGatewayCallerSession) GetBlockHeight(blockHash_ [32]byte) (uint64, error) {
	return _HistoricalSPVGateway.Contract.GetBlockHeight(&_HistoricalSPVGateway.CallOpts, blockHash_)
}

// GetBlockInfo is a free data retrieval call binding the contract method 0xe2c18e6e.
//
// Solidity: function getBlockInfo(bytes32 blockHash_) view returns(((bytes32,bytes32,uint32,uint32,uint32,bytes4,uint64),bool,uint256) blockInfo_)
func (_HistoricalSPVGateway *HistoricalSPVGatewayCaller) GetBlockInfo(opts *bind.CallOpts, blockHash_ [32]byte) (ISPVGatewayBlockInfo, error) {
	var out []interface{}
	err := _HistoricalSPVGateway.contract.Call(opts, &out, "getBlockInfo", blockHash_)

	if err != nil {
		return *new(ISPVGatewayBlockInfo), err
	}

	out0 := *abi.ConvertType(out[0], new(ISPVGatewayBlockInfo)).(*ISPVGatewayBlockInfo)

	return out0, err

}

// GetBlockInfo is a free data retrieval call binding the contract method 0xe2c18e6e.
//
// Solidity: function getBlockInfo(bytes32 blockHash_) view returns(((bytes32,bytes32,uint32,uint32,uint32,bytes4,uint64),bool,uint256) blockInfo_)
func (_HistoricalSPVGateway *HistoricalSPVGatewaySession) GetBlockInfo(blockHash_ [32]byte) (ISPVGatewayBlockInfo, error) {
	return _HistoricalSPVGateway.Contract.GetBlockInfo(&_HistoricalSPVGateway.CallOpts, blockHash_)
}

// GetBlockInfo is a free data retrieval call binding the contract method 0xe2c18e6e.
//
// Solidity: function getBlockInfo(bytes32 blockHash_) view returns(((bytes32,bytes32,uint32,uint32,uint32,bytes4,uint64),bool,uint256) blockInfo_)
func (_HistoricalSPVGateway *HistoricalSPVGatewayCallerSession) GetBlockInfo(blockHash_ [32]byte) (ISPVGatewayBlockInfo, error) {
	return _HistoricalSPVGateway.Contract.GetBlockInfo(&_HistoricalSPVGateway.CallOpts, blockHash_)
}

// GetBlockMerkleRoot is a free data retrieval call binding the contract method 0x690dc201.
//
// Solidity: function getBlockMerkleRoot(bytes32 blockHash_) view returns(bytes32)
func (_HistoricalSPVGateway *HistoricalSPVGatewayCaller) GetBlockMerkleRoot(opts *bind.CallOpts, blockHash_ [32]byte) ([32]byte, error) {
	var out []interface{}
	err := _HistoricalSPVGateway.contract.Call(opts, &out, "getBlockMerkleRoot", blockHash_)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GetBlockMerkleRoot is a free data retrieval call binding the contract method 0x690dc201.
//
// Solidity: function getBlockMerkleRoot(bytes32 blockHash_) view returns(bytes32)
func (_HistoricalSPVGateway *HistoricalSPVGatewaySession) GetBlockMerkleRoot(blockHash_ [32]byte) ([32]byte, error) {
	return _HistoricalSPVGateway.Contract.GetBlockMerkleRoot(&_HistoricalSPVGateway.CallOpts, blockHash_)
}

// GetBlockMerkleRoot is a free data retrieval call binding the contract method 0x690dc201.
//
// Solidity: function getBlockMerkleRoot(bytes32 blockHash_) view returns(bytes32)
func (_HistoricalSPVGateway *HistoricalSPVGatewayCallerSession) GetBlockMerkleRoot(blockHash_ [32]byte) ([32]byte, error) {
	return _HistoricalSPVGateway.Contract.GetBlockMerkleRoot(&_HistoricalSPVGateway.CallOpts, blockHash_)
}

// GetBlockStatus is a free data retrieval call binding the contract method 0x8f657259.
//
// Solidity: function getBlockStatus(bytes32 blockHash_) view returns(bool, uint64)
func (_HistoricalSPVGateway *HistoricalSPVGatewayCaller) GetBlockStatus(opts *bind.CallOpts, blockHash_ [32]byte) (bool, uint64, error) {
	var out []interface{}
	err := _HistoricalSPVGateway.contract.Call(opts, &out, "getBlockStatus", blockHash_)

	if err != nil {
		return *new(bool), *new(uint64), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)
	out1 := *abi.ConvertType(out[1], new(uint64)).(*uint64)

	return out0, out1, err

}

// GetBlockStatus is a free data retrieval call binding the contract method 0x8f657259.
//
// Solidity: function getBlockStatus(bytes32 blockHash_) view returns(bool, uint64)
func (_HistoricalSPVGateway *HistoricalSPVGatewaySession) GetBlockStatus(blockHash_ [32]byte) (bool, uint64, error) {
	return _HistoricalSPVGateway.Contract.GetBlockStatus(&_HistoricalSPVGateway.CallOpts, blockHash_)
}

// GetBlockStatus is a free data retrieval call binding the contract method 0x8f657259.
//
// Solidity: function getBlockStatus(bytes32 blockHash_) view returns(bool, uint64)
func (_HistoricalSPVGateway *HistoricalSPVGatewayCallerSession) GetBlockStatus(blockHash_ [32]byte) (bool, uint64, error) {
	return _HistoricalSPVGateway.Contract.GetBlockStatus(&_HistoricalSPVGateway.CallOpts, blockHash_)
}

// GetBlockTarget is a free data retrieval call binding the contract method 0x18443a65.
//
// Solidity: function getBlockTarget(bytes32 blockHash_) view returns(bytes32)
func (_HistoricalSPVGateway *HistoricalSPVGatewayCaller) GetBlockTarget(opts *bind.CallOpts, blockHash_ [32]byte) ([32]byte, error) {
	var out []interface{}
	err := _HistoricalSPVGateway.contract.Call(opts, &out, "getBlockTarget", blockHash_)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GetBlockTarget is a free data retrieval call binding the contract method 0x18443a65.
//
// Solidity: function getBlockTarget(bytes32 blockHash_) view returns(bytes32)
func (_HistoricalSPVGateway *HistoricalSPVGatewaySession) GetBlockTarget(blockHash_ [32]byte) ([32]byte, error) {
	return _HistoricalSPVGateway.Contract.GetBlockTarget(&_HistoricalSPVGateway.CallOpts, blockHash_)
}

// GetBlockTarget is a free data retrieval call binding the contract method 0x18443a65.
//
// Solidity: function getBlockTarget(bytes32 blockHash_) view returns(bytes32)
func (_HistoricalSPVGateway *HistoricalSPVGatewayCallerSession) GetBlockTarget(blockHash_ [32]byte) ([32]byte, error) {
	return _HistoricalSPVGateway.Contract.GetBlockTarget(&_HistoricalSPVGateway.CallOpts, blockHash_)
}

// GetHistoryBlocksCount is a free data retrieval call binding the contract method 0x58b04178.
//
// Solidity: function getHistoryBlocksCount() view returns(uint256)
func (_HistoricalSPVGateway *HistoricalSPVGatewayCaller) GetHistoryBlocksCount(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _HistoricalSPVGateway.contract.Call(opts, &out, "getHistoryBlocksCount")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetHistoryBlocksCount is a free data retrieval call binding the contract method 0x58b04178.
//
// Solidity: function getHistoryBlocksCount() view returns(uint256)
func (_HistoricalSPVGateway *HistoricalSPVGatewaySession) GetHistoryBlocksCount() (*big.Int, error) {
	return _HistoricalSPVGateway.Contract.GetHistoryBlocksCount(&_HistoricalSPVGateway.CallOpts)
}

// GetHistoryBlocksCount is a free data retrieval call binding the contract method 0x58b04178.
//
// Solidity: function getHistoryBlocksCount() view returns(uint256)
func (_HistoricalSPVGateway *HistoricalSPVGatewayCallerSession) GetHistoryBlocksCount() (*big.Int, error) {
	return _HistoricalSPVGateway.Contract.GetHistoryBlocksCount(&_HistoricalSPVGateway.CallOpts)
}

// GetHistoryBlocksTreeRoot is a free data retrieval call binding the contract method 0x3fe6350a.
//
// Solidity: function getHistoryBlocksTreeRoot() view returns(bytes32)
func (_HistoricalSPVGateway *HistoricalSPVGatewayCaller) GetHistoryBlocksTreeRoot(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _HistoricalSPVGateway.contract.Call(opts, &out, "getHistoryBlocksTreeRoot")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GetHistoryBlocksTreeRoot is a free data retrieval call binding the contract method 0x3fe6350a.
//
// Solidity: function getHistoryBlocksTreeRoot() view returns(bytes32)
func (_HistoricalSPVGateway *HistoricalSPVGatewaySession) GetHistoryBlocksTreeRoot() ([32]byte, error) {
	return _HistoricalSPVGateway.Contract.GetHistoryBlocksTreeRoot(&_HistoricalSPVGateway.CallOpts)
}

// GetHistoryBlocksTreeRoot is a free data retrieval call binding the contract method 0x3fe6350a.
//
// Solidity: function getHistoryBlocksTreeRoot() view returns(bytes32)
func (_HistoricalSPVGateway *HistoricalSPVGatewayCallerSession) GetHistoryBlocksTreeRoot() ([32]byte, error) {
	return _HistoricalSPVGateway.Contract.GetHistoryBlocksTreeRoot(&_HistoricalSPVGateway.CallOpts)
}

// GetLastEpochCumulativeWork is a free data retrieval call binding the contract method 0x43682c7e.
//
// Solidity: function getLastEpochCumulativeWork() view returns(uint256)
func (_HistoricalSPVGateway *HistoricalSPVGatewayCaller) GetLastEpochCumulativeWork(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _HistoricalSPVGateway.contract.Call(opts, &out, "getLastEpochCumulativeWork")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetLastEpochCumulativeWork is a free data retrieval call binding the contract method 0x43682c7e.
//
// Solidity: function getLastEpochCumulativeWork() view returns(uint256)
func (_HistoricalSPVGateway *HistoricalSPVGatewaySession) GetLastEpochCumulativeWork() (*big.Int, error) {
	return _HistoricalSPVGateway.Contract.GetLastEpochCumulativeWork(&_HistoricalSPVGateway.CallOpts)
}

// GetLastEpochCumulativeWork is a free data retrieval call binding the contract method 0x43682c7e.
//
// Solidity: function getLastEpochCumulativeWork() view returns(uint256)
func (_HistoricalSPVGateway *HistoricalSPVGatewayCallerSession) GetLastEpochCumulativeWork() (*big.Int, error) {
	return _HistoricalSPVGateway.Contract.GetLastEpochCumulativeWork(&_HistoricalSPVGateway.CallOpts)
}

// GetMainchainHead is a free data retrieval call binding the contract method 0xafaa65f3.
//
// Solidity: function getMainchainHead() view returns(bytes32)
func (_HistoricalSPVGateway *HistoricalSPVGatewayCaller) GetMainchainHead(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _HistoricalSPVGateway.contract.Call(opts, &out, "getMainchainHead")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GetMainchainHead is a free data retrieval call binding the contract method 0xafaa65f3.
//
// Solidity: function getMainchainHead() view returns(bytes32)
func (_HistoricalSPVGateway *HistoricalSPVGatewaySession) GetMainchainHead() ([32]byte, error) {
	return _HistoricalSPVGateway.Contract.GetMainchainHead(&_HistoricalSPVGateway.CallOpts)
}

// GetMainchainHead is a free data retrieval call binding the contract method 0xafaa65f3.
//
// Solidity: function getMainchainHead() view returns(bytes32)
func (_HistoricalSPVGateway *HistoricalSPVGatewayCallerSession) GetMainchainHead() ([32]byte, error) {
	return _HistoricalSPVGateway.Contract.GetMainchainHead(&_HistoricalSPVGateway.CallOpts)
}

// GetMainchainHeight is a free data retrieval call binding the contract method 0x3f377a6c.
//
// Solidity: function getMainchainHeight() view returns(uint64)
func (_HistoricalSPVGateway *HistoricalSPVGatewayCaller) GetMainchainHeight(opts *bind.CallOpts) (uint64, error) {
	var out []interface{}
	err := _HistoricalSPVGateway.contract.Call(opts, &out, "getMainchainHeight")

	if err != nil {
		return *new(uint64), err
	}

	out0 := *abi.ConvertType(out[0], new(uint64)).(*uint64)

	return out0, err

}

// GetMainchainHeight is a free data retrieval call binding the contract method 0x3f377a6c.
//
// Solidity: function getMainchainHeight() view returns(uint64)
func (_HistoricalSPVGateway *HistoricalSPVGatewaySession) GetMainchainHeight() (uint64, error) {
	return _HistoricalSPVGateway.Contract.GetMainchainHeight(&_HistoricalSPVGateway.CallOpts)
}

// GetMainchainHeight is a free data retrieval call binding the contract method 0x3f377a6c.
//
// Solidity: function getMainchainHeight() view returns(uint64)
func (_HistoricalSPVGateway *HistoricalSPVGatewayCallerSession) GetMainchainHeight() (uint64, error) {
	return _HistoricalSPVGateway.Contract.GetMainchainHeight(&_HistoricalSPVGateway.CallOpts)
}

// IsInMainchain is a free data retrieval call binding the contract method 0xc8fb2245.
//
// Solidity: function isInMainchain(bytes32 blockHash_) view returns(bool)
func (_HistoricalSPVGateway *HistoricalSPVGatewayCaller) IsInMainchain(opts *bind.CallOpts, blockHash_ [32]byte) (bool, error) {
	var out []interface{}
	err := _HistoricalSPVGateway.contract.Call(opts, &out, "isInMainchain", blockHash_)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsInMainchain is a free data retrieval call binding the contract method 0xc8fb2245.
//
// Solidity: function isInMainchain(bytes32 blockHash_) view returns(bool)
func (_HistoricalSPVGateway *HistoricalSPVGatewaySession) IsInMainchain(blockHash_ [32]byte) (bool, error) {
	return _HistoricalSPVGateway.Contract.IsInMainchain(&_HistoricalSPVGateway.CallOpts, blockHash_)
}

// IsInMainchain is a free data retrieval call binding the contract method 0xc8fb2245.
//
// Solidity: function isInMainchain(bytes32 blockHash_) view returns(bool)
func (_HistoricalSPVGateway *HistoricalSPVGatewayCallerSession) IsInMainchain(blockHash_ [32]byte) (bool, error) {
	return _HistoricalSPVGateway.Contract.IsInMainchain(&_HistoricalSPVGateway.CallOpts, blockHash_)
}

// HistoricalSPVGatewayInit is a paid mutator transaction binding the contract method 0x45aa32aa.
//
// Solidity: function __HistoricalSPVGateway_init(bytes blockHeaderRaw_, uint64 blockHeight_, uint256 cumulativeWork_, bytes32 historyBlocksTreeRoot_, (address,bytes32[],bytes) proofData_) returns()
func (_HistoricalSPVGateway *HistoricalSPVGatewayTransactor) HistoricalSPVGatewayInit(opts *bind.TransactOpts, blockHeaderRaw_ []byte, blockHeight_ uint64, cumulativeWork_ *big.Int, historyBlocksTreeRoot_ [32]byte, proofData_ BlockHistoryHistoryProofData) (*types.Transaction, error) {
	return _HistoricalSPVGateway.contract.Transact(opts, "__HistoricalSPVGateway_init", blockHeaderRaw_, blockHeight_, cumulativeWork_, historyBlocksTreeRoot_, proofData_)
}

// HistoricalSPVGatewayInit is a paid mutator transaction binding the contract method 0x45aa32aa.
//
// Solidity: function __HistoricalSPVGateway_init(bytes blockHeaderRaw_, uint64 blockHeight_, uint256 cumulativeWork_, bytes32 historyBlocksTreeRoot_, (address,bytes32[],bytes) proofData_) returns()
func (_HistoricalSPVGateway *HistoricalSPVGatewaySession) HistoricalSPVGatewayInit(blockHeaderRaw_ []byte, blockHeight_ uint64, cumulativeWork_ *big.Int, historyBlocksTreeRoot_ [32]byte, proofData_ BlockHistoryHistoryProofData) (*types.Transaction, error) {
	return _HistoricalSPVGateway.Contract.HistoricalSPVGatewayInit(&_HistoricalSPVGateway.TransactOpts, blockHeaderRaw_, blockHeight_, cumulativeWork_, historyBlocksTreeRoot_, proofData_)
}

// HistoricalSPVGatewayInit is a paid mutator transaction binding the contract method 0x45aa32aa.
//
// Solidity: function __HistoricalSPVGateway_init(bytes blockHeaderRaw_, uint64 blockHeight_, uint256 cumulativeWork_, bytes32 historyBlocksTreeRoot_, (address,bytes32[],bytes) proofData_) returns()
func (_HistoricalSPVGateway *HistoricalSPVGatewayTransactorSession) HistoricalSPVGatewayInit(blockHeaderRaw_ []byte, blockHeight_ uint64, cumulativeWork_ *big.Int, historyBlocksTreeRoot_ [32]byte, proofData_ BlockHistoryHistoryProofData) (*types.Transaction, error) {
	return _HistoricalSPVGateway.Contract.HistoricalSPVGatewayInit(&_HistoricalSPVGateway.TransactOpts, blockHeaderRaw_, blockHeight_, cumulativeWork_, historyBlocksTreeRoot_, proofData_)
}

// SPVGatewayInit is a paid mutator transaction binding the contract method 0xb143121d.
//
// Solidity: function __SPVGateway_init(bytes blockHeaderRaw_, uint64 blockHeight_, uint256 cumulativeWork_) returns()
func (_HistoricalSPVGateway *HistoricalSPVGatewayTransactor) SPVGatewayInit(opts *bind.TransactOpts, blockHeaderRaw_ []byte, blockHeight_ uint64, cumulativeWork_ *big.Int) (*types.Transaction, error) {
	return _HistoricalSPVGateway.contract.Transact(opts, "__SPVGateway_init", blockHeaderRaw_, blockHeight_, cumulativeWork_)
}

// SPVGatewayInit is a paid mutator transaction binding the contract method 0xb143121d.
//
// Solidity: function __SPVGateway_init(bytes blockHeaderRaw_, uint64 blockHeight_, uint256 cumulativeWork_) returns()
func (_HistoricalSPVGateway *HistoricalSPVGatewaySession) SPVGatewayInit(blockHeaderRaw_ []byte, blockHeight_ uint64, cumulativeWork_ *big.Int) (*types.Transaction, error) {
	return _HistoricalSPVGateway.Contract.SPVGatewayInit(&_HistoricalSPVGateway.TransactOpts, blockHeaderRaw_, blockHeight_, cumulativeWork_)
}

// SPVGatewayInit is a paid mutator transaction binding the contract method 0xb143121d.
//
// Solidity: function __SPVGateway_init(bytes blockHeaderRaw_, uint64 blockHeight_, uint256 cumulativeWork_) returns()
func (_HistoricalSPVGateway *HistoricalSPVGatewayTransactorSession) SPVGatewayInit(blockHeaderRaw_ []byte, blockHeight_ uint64, cumulativeWork_ *big.Int) (*types.Transaction, error) {
	return _HistoricalSPVGateway.Contract.SPVGatewayInit(&_HistoricalSPVGateway.TransactOpts, blockHeaderRaw_, blockHeight_, cumulativeWork_)
}

// SPVGatewayInitGenesis is a paid mutator transaction binding the contract method 0x006597ba.
//
// Solidity: function __SPVGateway_init_genesis() returns()
func (_HistoricalSPVGateway *HistoricalSPVGatewayTransactor) SPVGatewayInitGenesis(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _HistoricalSPVGateway.contract.Transact(opts, "__SPVGateway_init_genesis")
}

// SPVGatewayInitGenesis is a paid mutator transaction binding the contract method 0x006597ba.
//
// Solidity: function __SPVGateway_init_genesis() returns()
func (_HistoricalSPVGateway *HistoricalSPVGatewaySession) SPVGatewayInitGenesis() (*types.Transaction, error) {
	return _HistoricalSPVGateway.Contract.SPVGatewayInitGenesis(&_HistoricalSPVGateway.TransactOpts)
}

// SPVGatewayInitGenesis is a paid mutator transaction binding the contract method 0x006597ba.
//
// Solidity: function __SPVGateway_init_genesis() returns()
func (_HistoricalSPVGateway *HistoricalSPVGatewayTransactorSession) SPVGatewayInitGenesis() (*types.Transaction, error) {
	return _HistoricalSPVGateway.Contract.SPVGatewayInitGenesis(&_HistoricalSPVGateway.TransactOpts)
}

// AddBlockHeader is a paid mutator transaction binding the contract method 0x633cc31e.
//
// Solidity: function addBlockHeader(bytes blockHeaderRaw_) returns()
func (_HistoricalSPVGateway *HistoricalSPVGatewayTransactor) AddBlockHeader(opts *bind.TransactOpts, blockHeaderRaw_ []byte) (*types.Transaction, error) {
	return _HistoricalSPVGateway.contract.Transact(opts, "addBlockHeader", blockHeaderRaw_)
}

// AddBlockHeader is a paid mutator transaction binding the contract method 0x633cc31e.
//
// Solidity: function addBlockHeader(bytes blockHeaderRaw_) returns()
func (_HistoricalSPVGateway *HistoricalSPVGatewaySession) AddBlockHeader(blockHeaderRaw_ []byte) (*types.Transaction, error) {
	return _HistoricalSPVGateway.Contract.AddBlockHeader(&_HistoricalSPVGateway.TransactOpts, blockHeaderRaw_)
}

// AddBlockHeader is a paid mutator transaction binding the contract method 0x633cc31e.
//
// Solidity: function addBlockHeader(bytes blockHeaderRaw_) returns()
func (_HistoricalSPVGateway *HistoricalSPVGatewayTransactorSession) AddBlockHeader(blockHeaderRaw_ []byte) (*types.Transaction, error) {
	return _HistoricalSPVGateway.Contract.AddBlockHeader(&_HistoricalSPVGateway.TransactOpts, blockHeaderRaw_)
}

// AddBlockHeaderBatch is a paid mutator transaction binding the contract method 0xebbe0b65.
//
// Solidity: function addBlockHeaderBatch(bytes[] blockHeaderRawArray_) returns()
func (_HistoricalSPVGateway *HistoricalSPVGatewayTransactor) AddBlockHeaderBatch(opts *bind.TransactOpts, blockHeaderRawArray_ [][]byte) (*types.Transaction, error) {
	return _HistoricalSPVGateway.contract.Transact(opts, "addBlockHeaderBatch", blockHeaderRawArray_)
}

// AddBlockHeaderBatch is a paid mutator transaction binding the contract method 0xebbe0b65.
//
// Solidity: function addBlockHeaderBatch(bytes[] blockHeaderRawArray_) returns()
func (_HistoricalSPVGateway *HistoricalSPVGatewaySession) AddBlockHeaderBatch(blockHeaderRawArray_ [][]byte) (*types.Transaction, error) {
	return _HistoricalSPVGateway.Contract.AddBlockHeaderBatch(&_HistoricalSPVGateway.TransactOpts, blockHeaderRawArray_)
}

// AddBlockHeaderBatch is a paid mutator transaction binding the contract method 0xebbe0b65.
//
// Solidity: function addBlockHeaderBatch(bytes[] blockHeaderRawArray_) returns()
func (_HistoricalSPVGateway *HistoricalSPVGatewayTransactorSession) AddBlockHeaderBatch(blockHeaderRawArray_ [][]byte) (*types.Transaction, error) {
	return _HistoricalSPVGateway.Contract.AddBlockHeaderBatch(&_HistoricalSPVGateway.TransactOpts, blockHeaderRawArray_)
}

// HistoricalSPVGatewayBlockHeaderAddedIterator is returned from FilterBlockHeaderAdded and is used to iterate over the raw logs and unpacked data for BlockHeaderAdded events raised by the HistoricalSPVGateway contract.
type HistoricalSPVGatewayBlockHeaderAddedIterator struct {
	Event *HistoricalSPVGatewayBlockHeaderAdded // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *HistoricalSPVGatewayBlockHeaderAddedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(HistoricalSPVGatewayBlockHeaderAdded)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(HistoricalSPVGatewayBlockHeaderAdded)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *HistoricalSPVGatewayBlockHeaderAddedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *HistoricalSPVGatewayBlockHeaderAddedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// HistoricalSPVGatewayBlockHeaderAdded represents a BlockHeaderAdded event raised by the HistoricalSPVGateway contract.
type HistoricalSPVGatewayBlockHeaderAdded struct {
	BlockHeight uint64
	BlockHash   [32]byte
	Raw         types.Log // Blockchain specific contextual infos
}

// FilterBlockHeaderAdded is a free log retrieval operation binding the contract event 0xbe2da3ece3208645642b3c8bbef3f720f76ddfc9d768bba312777fd56a8bcd9a.
//
// Solidity: event BlockHeaderAdded(uint64 indexed blockHeight, bytes32 indexed blockHash)
func (_HistoricalSPVGateway *HistoricalSPVGatewayFilterer) FilterBlockHeaderAdded(opts *bind.FilterOpts, blockHeight []uint64, blockHash [][32]byte) (*HistoricalSPVGatewayBlockHeaderAddedIterator, error) {

	var blockHeightRule []interface{}
	for _, blockHeightItem := range blockHeight {
		blockHeightRule = append(blockHeightRule, blockHeightItem)
	}
	var blockHashRule []interface{}
	for _, blockHashItem := range blockHash {
		blockHashRule = append(blockHashRule, blockHashItem)
	}

	logs, sub, err := _HistoricalSPVGateway.contract.FilterLogs(opts, "BlockHeaderAdded", blockHeightRule, blockHashRule)
	if err != nil {
		return nil, err
	}
	return &HistoricalSPVGatewayBlockHeaderAddedIterator{contract: _HistoricalSPVGateway.contract, event: "BlockHeaderAdded", logs: logs, sub: sub}, nil
}

// WatchBlockHeaderAdded is a free log subscription operation binding the contract event 0xbe2da3ece3208645642b3c8bbef3f720f76ddfc9d768bba312777fd56a8bcd9a.
//
// Solidity: event BlockHeaderAdded(uint64 indexed blockHeight, bytes32 indexed blockHash)
func (_HistoricalSPVGateway *HistoricalSPVGatewayFilterer) WatchBlockHeaderAdded(opts *bind.WatchOpts, sink chan<- *HistoricalSPVGatewayBlockHeaderAdded, blockHeight []uint64, blockHash [][32]byte) (event.Subscription, error) {

	var blockHeightRule []interface{}
	for _, blockHeightItem := range blockHeight {
		blockHeightRule = append(blockHeightRule, blockHeightItem)
	}
	var blockHashRule []interface{}
	for _, blockHashItem := range blockHash {
		blockHashRule = append(blockHashRule, blockHashItem)
	}

	logs, sub, err := _HistoricalSPVGateway.contract.WatchLogs(opts, "BlockHeaderAdded", blockHeightRule, blockHashRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(HistoricalSPVGatewayBlockHeaderAdded)
				if err := _HistoricalSPVGateway.contract.UnpackLog(event, "BlockHeaderAdded", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseBlockHeaderAdded is a log parse operation binding the contract event 0xbe2da3ece3208645642b3c8bbef3f720f76ddfc9d768bba312777fd56a8bcd9a.
//
// Solidity: event BlockHeaderAdded(uint64 indexed blockHeight, bytes32 indexed blockHash)
func (_HistoricalSPVGateway *HistoricalSPVGatewayFilterer) ParseBlockHeaderAdded(log types.Log) (*HistoricalSPVGatewayBlockHeaderAdded, error) {
	event := new(HistoricalSPVGatewayBlockHeaderAdded)
	if err := _HistoricalSPVGateway.contract.UnpackLog(event, "BlockHeaderAdded", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// HistoricalSPVGatewayInitializedIterator is returned from FilterInitialized and is used to iterate over the raw logs and unpacked data for Initialized events raised by the HistoricalSPVGateway contract.
type HistoricalSPVGatewayInitializedIterator struct {
	Event *HistoricalSPVGatewayInitialized // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *HistoricalSPVGatewayInitializedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(HistoricalSPVGatewayInitialized)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(HistoricalSPVGatewayInitialized)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *HistoricalSPVGatewayInitializedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *HistoricalSPVGatewayInitializedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// HistoricalSPVGatewayInitialized represents a Initialized event raised by the HistoricalSPVGateway contract.
type HistoricalSPVGatewayInitialized struct {
	Version uint64
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterInitialized is a free log retrieval operation binding the contract event 0xc7f505b2f371ae2175ee4913f4499e1f2633a7b5936321eed1cdaeb6115181d2.
//
// Solidity: event Initialized(uint64 version)
func (_HistoricalSPVGateway *HistoricalSPVGatewayFilterer) FilterInitialized(opts *bind.FilterOpts) (*HistoricalSPVGatewayInitializedIterator, error) {

	logs, sub, err := _HistoricalSPVGateway.contract.FilterLogs(opts, "Initialized")
	if err != nil {
		return nil, err
	}
	return &HistoricalSPVGatewayInitializedIterator{contract: _HistoricalSPVGateway.contract, event: "Initialized", logs: logs, sub: sub}, nil
}

// WatchInitialized is a free log subscription operation binding the contract event 0xc7f505b2f371ae2175ee4913f4499e1f2633a7b5936321eed1cdaeb6115181d2.
//
// Solidity: event Initialized(uint64 version)
func (_HistoricalSPVGateway *HistoricalSPVGatewayFilterer) WatchInitialized(opts *bind.WatchOpts, sink chan<- *HistoricalSPVGatewayInitialized) (event.Subscription, error) {

	logs, sub, err := _HistoricalSPVGateway.contract.WatchLogs(opts, "Initialized")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(HistoricalSPVGatewayInitialized)
				if err := _HistoricalSPVGateway.contract.UnpackLog(event, "Initialized", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseInitialized is a log parse operation binding the contract event 0xc7f505b2f371ae2175ee4913f4499e1f2633a7b5936321eed1cdaeb6115181d2.
//
// Solidity: event Initialized(uint64 version)
func (_HistoricalSPVGateway *HistoricalSPVGatewayFilterer) ParseInitialized(log types.Log) (*HistoricalSPVGatewayInitialized, error) {
	event := new(HistoricalSPVGatewayInitialized)
	if err := _HistoricalSPVGateway.contract.UnpackLog(event, "Initialized", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// HistoricalSPVGatewayMainchainHeadUpdatedIterator is returned from FilterMainchainHeadUpdated and is used to iterate over the raw logs and unpacked data for MainchainHeadUpdated events raised by the HistoricalSPVGateway contract.
type HistoricalSPVGatewayMainchainHeadUpdatedIterator struct {
	Event *HistoricalSPVGatewayMainchainHeadUpdated // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *HistoricalSPVGatewayMainchainHeadUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(HistoricalSPVGatewayMainchainHeadUpdated)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(HistoricalSPVGatewayMainchainHeadUpdated)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *HistoricalSPVGatewayMainchainHeadUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *HistoricalSPVGatewayMainchainHeadUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// HistoricalSPVGatewayMainchainHeadUpdated represents a MainchainHeadUpdated event raised by the HistoricalSPVGateway contract.
type HistoricalSPVGatewayMainchainHeadUpdated struct {
	NewMainchainHeight uint64
	NewMainchainHead   [32]byte
	Raw                types.Log // Blockchain specific contextual infos
}

// FilterMainchainHeadUpdated is a free log retrieval operation binding the contract event 0x69178d4e683f38fecfbc8c49445d0cf1c5e1df54f862916aa87dabbc47a6a4dd.
//
// Solidity: event MainchainHeadUpdated(uint64 indexed newMainchainHeight, bytes32 indexed newMainchainHead)
func (_HistoricalSPVGateway *HistoricalSPVGatewayFilterer) FilterMainchainHeadUpdated(opts *bind.FilterOpts, newMainchainHeight []uint64, newMainchainHead [][32]byte) (*HistoricalSPVGatewayMainchainHeadUpdatedIterator, error) {

	var newMainchainHeightRule []interface{}
	for _, newMainchainHeightItem := range newMainchainHeight {
		newMainchainHeightRule = append(newMainchainHeightRule, newMainchainHeightItem)
	}
	var newMainchainHeadRule []interface{}
	for _, newMainchainHeadItem := range newMainchainHead {
		newMainchainHeadRule = append(newMainchainHeadRule, newMainchainHeadItem)
	}

	logs, sub, err := _HistoricalSPVGateway.contract.FilterLogs(opts, "MainchainHeadUpdated", newMainchainHeightRule, newMainchainHeadRule)
	if err != nil {
		return nil, err
	}
	return &HistoricalSPVGatewayMainchainHeadUpdatedIterator{contract: _HistoricalSPVGateway.contract, event: "MainchainHeadUpdated", logs: logs, sub: sub}, nil
}

// WatchMainchainHeadUpdated is a free log subscription operation binding the contract event 0x69178d4e683f38fecfbc8c49445d0cf1c5e1df54f862916aa87dabbc47a6a4dd.
//
// Solidity: event MainchainHeadUpdated(uint64 indexed newMainchainHeight, bytes32 indexed newMainchainHead)
func (_HistoricalSPVGateway *HistoricalSPVGatewayFilterer) WatchMainchainHeadUpdated(opts *bind.WatchOpts, sink chan<- *HistoricalSPVGatewayMainchainHeadUpdated, newMainchainHeight []uint64, newMainchainHead [][32]byte) (event.Subscription, error) {

	var newMainchainHeightRule []interface{}
	for _, newMainchainHeightItem := range newMainchainHeight {
		newMainchainHeightRule = append(newMainchainHeightRule, newMainchainHeightItem)
	}
	var newMainchainHeadRule []interface{}
	for _, newMainchainHeadItem := range newMainchainHead {
		newMainchainHeadRule = append(newMainchainHeadRule, newMainchainHeadItem)
	}

	logs, sub, err := _HistoricalSPVGateway.contract.WatchLogs(opts, "MainchainHeadUpdated", newMainchainHeightRule, newMainchainHeadRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(HistoricalSPVGatewayMainchainHeadUpdated)
				if err := _HistoricalSPVGateway.contract.UnpackLog(event, "MainchainHeadUpdated", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseMainchainHeadUpdated is a log parse operation binding the contract event 0x69178d4e683f38fecfbc8c49445d0cf1c5e1df54f862916aa87dabbc47a6a4dd.
//
// Solidity: event MainchainHeadUpdated(uint64 indexed newMainchainHeight, bytes32 indexed newMainchainHead)
func (_HistoricalSPVGateway *HistoricalSPVGatewayFilterer) ParseMainchainHeadUpdated(log types.Log) (*HistoricalSPVGatewayMainchainHeadUpdated, error) {
	event := new(HistoricalSPVGatewayMainchainHeadUpdated)
	if err := _HistoricalSPVGateway.contract.UnpackLog(event, "MainchainHeadUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
