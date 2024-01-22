// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @title IPizzaInitializer
 * @dev Interface for initializing a pizza contract.
 */
interface IPizzaInitializer {
    function initialize(address[] memory _payees, uint256[] memory _shares, uint256 _bounty) external;

    function initializeWithBountyRelease(
        address[] calldata _payees,
        uint256[] calldata _shares,
        uint256 _bounty,
        address[] calldata _bountyTokens,
        address _bountyReceiver
    ) external;
}
