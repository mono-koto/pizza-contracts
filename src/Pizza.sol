// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {PaymentSplitterUpgradeable} from "openzeppelin-contracts-upgradeable/finance/PaymentSplitterUpgradeable.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";

contract Pizza is Initializable, PaymentSplitterUpgradeable {
    // uint32 public releaseBountyBIPS;
    // uint256 public constant BIPS_PRECISION = 10000;

    constructor() {
        _disableInitializers();
    }

    function initialize(address[] memory _payees, uint256[] memory _shares) external initializer {
        __PaymentSplitter_init(_payees, _shares);
    }
}
