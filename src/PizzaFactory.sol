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

    function createDeterministic(address[] memory _payees, uint256[] memory _shares, bytes32 _salt)
        external
        returns (IPizza pizza)
    {
        pizza = IPizza(address(Clones.cloneDeterministic(implementation, _paramHashedSalt(_payees, _shares, _salt))));
        pizza.initialize(_payees, _shares);
    }

    function predict(address[] memory _payees, uint256[] memory _shares, bytes32 _salt)
        external
        view
        returns (address)
    {
        return
            Clones.predictDeterministicAddress(implementation, _paramHashedSalt(_payees, _shares, _salt), address(this));
    }

    function deployWithReimbursement(address[] memory _payees, uint256[] memory _shares, bytes32 _salt)
        external
        returns (IPizza pizza)
    {
        pizza = IPizza(address(Clones.cloneDeterministic(implementation, _salt)));
        pizza.initialize(_payees, _shares);
        // pizza.reimburse{value: msg.value}();
    }

    function _paramHashedSalt(address[] memory _payees, uint256[] memory _shares, bytes32 _salt)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_payees, _shares, _salt));
    }
}
