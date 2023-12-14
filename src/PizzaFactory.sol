// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Clones} from "openzeppelin-contracts/proxy/Clones.sol";
import {IPizza} from "./IPizza.sol";

contract PizzaFactory {
    address implementation;

    constructor(address _impl) {
        implementation = _impl;
    }

    function create(address[] memory _payees, uint256[] memory _shares) external returns (IPizza pizza) {
        pizza = IPizza(address(Clones.clone(implementation)));
        pizza.initialize(_payees, _shares);
    }

    function createDeterministic(address[] memory _payees, uint256[] memory _shares, uint256 _nonce)
        external
        returns (IPizza pizza)
    {
        pizza = IPizza(address(Clones.cloneDeterministic(implementation, _paramHashedSalt(_payees, _shares, _nonce))));
        pizza.initialize(_payees, _shares);
    }

    function predict(address[] memory _payees, uint256[] memory _shares, uint256 _nonce)
        external
        view
        returns (address)
    {
        return Clones.predictDeterministicAddress(
            implementation, _paramHashedSalt(_payees, _shares, _nonce), address(this)
        );
    }

    function _paramHashedSalt(address[] memory _payees, uint256[] memory _shares, uint256 _nonce)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_payees, _shares, _nonce));
    }
}
