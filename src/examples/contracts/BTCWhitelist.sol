// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {TxParser} from "@solarity/solidity-lib/libs/bitcoin/TxParser.sol";
import {Paginator} from "@solarity/solidity-lib/libs/arrays/Paginator.sol";

import {ISPVGatewayV2} from "./interfaces/ISPVGatewayV2.sol";
import {IBTCWhitelist} from "./interfaces/IBTCWhitelist.sol";

contract BTCWhitelist is IBTCWhitelist, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Paginator for EnumerableSet.AddressSet;
    using TxParser for bytes;

    ISPVGatewayV2 public immutable spvGatewayV2;

    uint256 internal _whitelistMinAmount;
    uint256 internal _minConfirmationsCount;

    EnumerableSet.AddressSet internal _whitelist;

    modifier onlyWhitelistedAccount() {
        _onlyWhitelistedAccount(msg.sender);
        _;
    }

    constructor(
        address spvGatewayV2Addr_,
        uint256 whitelistMinAmount_,
        uint256 minConfirmationsCount_
    ) Ownable(msg.sender) {
        spvGatewayV2 = ISPVGatewayV2(spvGatewayV2Addr_);

        _updateWhitelistMinAmount(whitelistMinAmount_);
        _updateMinConfirmationsCount(minConfirmationsCount_);
    }

    /// @inheritdoc IBTCWhitelist
    function updateWhitelistMinAmount(uint256 whitelistMinAmount_) external onlyOwner {
        _updateWhitelistMinAmount(whitelistMinAmount_);
    }

    /// @inheritdoc IBTCWhitelist
    function updateMinConfirmationsCount(uint256 minConfirmationsCount_) external onlyOwner {
        _updateMinConfirmationsCount(minConfirmationsCount_);
    }

    /// @inheritdoc IBTCWhitelist
    function enterToWhitelist(bytes calldata txData_, bytes calldata txInclusionProof_) external {
        require(!isAccountWhitelisted(msg.sender), AccountIsAlreadyWhitelisted(msg.sender));

        bytes32 txId_ = txData_.calculateTxId();

        _checkTxInclusionProof(txId_, txInclusionProof_);

        (TxParser.Transaction memory tx_, ) = txData_.parseTransaction();

        require(_verifyWhitelistEntryRules(tx_), WhitelistEntryRulesAreNotMatched());

        _whitelistAccount(msg.sender);
    }

    /// @inheritdoc IBTCWhitelist
    function getWhitelistMinAmount() external view returns (uint256) {
        return _whitelistMinAmount;
    }

    /// @inheritdoc IBTCWhitelist
    function getMinConfirmationsCount() external view returns (uint256) {
        return _minConfirmationsCount;
    }

    /// @inheritdoc IBTCWhitelist
    function getWhitelistedAccountsCount() external view returns (uint256) {
        return _whitelist.length();
    }

    /// @inheritdoc IBTCWhitelist
    function getAllWhitelistedAccounts() external view returns (address[] memory) {
        return _whitelist.values();
    }

    /// @inheritdoc IBTCWhitelist
    function getWhitelistedAccountsPart(
        uint256 offset_,
        uint256 limit_
    ) external view returns (address[] memory) {
        return _whitelist.part(offset_, limit_);
    }

    /// @inheritdoc IBTCWhitelist
    function isAccountWhitelisted(address account_) public view virtual returns (bool) {
        return _whitelist.contains(account_);
    }

    function _updateWhitelistMinAmount(uint256 whitelistMinAmount_) internal {
        _whitelistMinAmount = whitelistMinAmount_;

        emit WhitelistMinAmountUpdated(whitelistMinAmount_);
    }

    function _updateMinConfirmationsCount(uint256 minConfirmationsCount_) internal {
        _minConfirmationsCount = minConfirmationsCount_;

        emit MinConfirmationsCountUpdated(minConfirmationsCount_);
    }

    function _whitelistAccount(address account_) internal virtual {
        _whitelist.add(account_);

        emit AccountWhitelisted(account_);
    }

    function _verifyWhitelistEntryRules(
        TxParser.Transaction memory tx_
    ) internal view virtual returns (bool) {
        TxParser.TransactionOutput[] memory outputs_ = tx_.outputs;

        for (uint256 i = 0; i < outputs_.length; i++) {
            if (outputs_[i].value >= _whitelistMinAmount) {
                return true;
            }
        }

        return false;
    }

    function _checkTxInclusionProof(
        bytes32 txId_,
        bytes calldata txInclusionProof_
    ) internal view virtual {
        (
            bytes memory blockHeaderRaw_,
            uint256 txIndex_,
            bytes32[] memory merkleProof_,
            ISPVGatewayV2.HistoryBlockInclusionProofData memory blockProofData_
        ) = abi.decode(
                txInclusionProof_,
                (bytes, uint256, bytes32[], ISPVGatewayV2.HistoryBlockInclusionProofData)
            );

        require(
            spvGatewayV2.checkTxInclusion(
                merkleProof_,
                blockHeaderRaw_,
                txId_,
                txIndex_,
                blockProofData_
            ),
            TxNotIncluded()
        );
        _checkBlockConfirmations(uint64(blockProofData_.blockHeight));
    }

    function _checkBlockConfirmations(uint64 blockHeight_) internal view virtual {
        uint64 currentMainchainHeight_ = spvGatewayV2.getMainchainHeight();

        require(
            blockHeight_ + _minConfirmationsCount <= currentMainchainHeight_,
            MinConfirmationsCountNotReached(blockHeight_, currentMainchainHeight_)
        );
    }

    function _onlyWhitelistedAccount(address account_) internal view {
        require(isAccountWhitelisted(account_), NotAWhitelistedAccount(account_));
    }
}
