// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @title IPizzaInitializer
 * @dev Interface for initializing a pizza contract.
 */
interface IPizzaInitializer {
    function initialize(address[] memory _payees, uint256[] memory _shares) external;
}
