// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @title IPizzaInitializer
 * @dev Interface for initializing a pizza contract.
 */
interface IPizzaInitializer {
    /**
     * @dev Initializes the contract.
     * @param _payees The addresses of the payees.
     * @param _shares The shares of each payee.
     * @param _bounty The bounty amount.
     */
    function initialize(address[] memory _payees, uint256[] memory _shares, uint256 _bounty) external;

    /**
     * @dev Initializes the contract.
     * @param _payees The addresses of the payees.
     * @param _shares The shares of each payee.
     * @param _bounty The bounty amount.
     * @param _bountyTokens The tokens to be used for the bounty.
     * @param _bountyReceiver The address of the bounty receiver.
     */
    function initializeWithBountyRelease(
        address[] calldata _payees,
        uint256[] calldata _shares,
        uint256 _bounty,
        address[] calldata _bountyTokens,
        address _bountyReceiver
    ) external;
}
