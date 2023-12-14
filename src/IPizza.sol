// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {PaymentSplitterUpgradeable} from "openzeppelin-contracts-upgradeable/finance/PaymentSplitterUpgradeable.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";

interface IPizza {
    function initialize(address[] memory _payees, uint256[] memory _shares) external;
}
