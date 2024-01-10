// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Initializable} from "openzeppelin-contracts/proxy/utils/Initializable.sol";

interface IPizzaInitializer {
    function initialize(address[] memory _payees, uint256[] memory _shares) external;
}
