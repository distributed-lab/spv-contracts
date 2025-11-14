// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title IBTCWhitelist
 * @notice Interface for the BTC Whitelist contract, which manages whitelisting of addresses on the Ethereum side using SPV proofs.
 */
interface IBTCWhitelist {
    /**
     * @notice Error thrown when an account is not whitelisted.
     * @param account The address that is not whitelisted.
     */
    error NotAWhitelistedAccount(address account);
    /**
     * @notice Error thrown when an account is already whitelisted.
     * @param account The address that is already whitelisted.
     */
    error AccountIsAlreadyWhitelisted(address account);
    /**
     * @notice Error thrown when the block has not reached the required number of confirmations.
     * @param blockHeight The height of the block being verified.
     * @param mainchainHeight The current height of the mainchain.
     */
    error MinConfirmationsCountNotReached(uint64 blockHeight, uint64 mainchainHeight);
    /**
     * @notice Error thrown when the SPV proof is invalid.
     */
    error InvalidSPVProof();
    /**
     * @notice Error thrown when the transaction is not included in the proof.
     */
    error TxNotIncluded();
    /**
     * @notice Error thrown when the whitelist entry rules are not matched.
     */
    error WhitelistEntryRulesAreNotMatched();

    /**
     * @notice Emitted when the whitelist minimum amount is updated.
     * @param newMinAmount The new minimum amount required for whitelisting.
     */
    event WhitelistMinAmountUpdated(uint256 newMinAmount);
    /**
     * @notice Emitted when the minimum confirmations count is updated.
     * @param newMinConfirmationsCount The new minimum confirmations count required.
     */
    event MinConfirmationsCountUpdated(uint256 newMinConfirmationsCount);
    /**
     * @notice Emitted when an account is successfully whitelisted.
     * @param account The address that was whitelisted.
     */
    event AccountWhitelisted(address account);

    /**
     * @notice Updates the minimum amount required for whitelisting.
     * @param whitelistMinAmount_ The new minimum amount in satoshis.
     */
    function updateWhitelistMinAmount(uint256 whitelistMinAmount_) external;

    /**
     * @notice Updates the minimum number of confirmations required for whitelisting.
     * @param minConfirmationsCount_ The new minimum confirmations count.
     */
    function updateMinConfirmationsCount(uint256 minConfirmationsCount_) external;

    /**
     * @notice Enters a `msg.sender` address to the whitelist using an SPV proof and transaction inclusion proof.
     * @param txData_ The raw transaction data.
     * @param txInclusionProof_ The proof data for transaction inclusion in the mainchain.
     */
    function enterToWhitelist(bytes calldata txData_, bytes calldata txInclusionProof_) external;

    /**
     * @notice Returns the minimum amount required for whitelisting.
     * @return The minimum whitelist amount in satoshis.
     */
    function getWhitelistMinAmount() external view returns (uint256);

    /**
     * @notice Returns the minimum number of confirmations required for whitelisting.
     * @return The minimum confirmations count.
     */
    function getMinConfirmationsCount() external view returns (uint256);

    /**
     * @notice Returns the total number of whitelisted accounts.
     * @return The count of whitelisted accounts.
     */
    function getWhitelistedAccountsCount() external view returns (uint256);

    /**
     * @notice Returns all whitelisted accounts.
     * @return An array of all whitelisted addresses.
     */
    function getAllWhitelistedAccounts() external view returns (address[] memory);

    /**
     * @notice Returns a paginated list of whitelisted accounts.
     * @param offset_ The starting index for pagination.
     * @param limit_ The maximum number of accounts to return.
     * @return An array of whitelisted addresses in the specified range.
     */
    function getWhitelistedAccountsPart(
        uint256 offset_,
        uint256 limit_
    ) external view returns (address[] memory);

    /**
     * @notice Checks if an account is whitelisted.
     * @param account_ The address to check.
     * @return True if the account is whitelisted, false otherwise.
     */
    function isAccountWhitelisted(address account_) external view returns (bool);
}
