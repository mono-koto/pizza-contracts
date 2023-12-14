// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Clones} from "openzeppelin-contracts/proxy/Clones.sol";
import {IPizza} from "./IPizza.sol";

event PizzaCreated(address indexed pizza);

contract PizzaFactory {
    address implementation;
    mapping(address => bool) public pizzas;

    constructor(address _impl) {
        implementation = _impl;
    }

    function create(address[] memory _payees, uint256[] memory _shares) external returns (IPizza pizza) {
        pizza = IPizza(address(Clones.clone(implementation)));
        pizza.initialize(_payees, _shares);
        pizzas[address(pizza)] = true;
        emit PizzaCreated(address(pizza));
    }

    function createDeterministic(address[] memory _payees, uint256[] memory _shares, uint256 _nonce)
        external
        returns (IPizza pizza)
    {
        pizza =
            IPizza(address(Clones.cloneDeterministic(implementation, keccak256(abi.encode(_payees, _shares, _nonce)))));
        pizza.initialize(_payees, _shares);
        pizzas[address(pizza)] = true;
        emit PizzaCreated(address(pizza));
    }

    function predict(address[] memory _payees, uint256[] memory _shares, uint256 _nonce)
        external
        view
        returns (address)
    {
        return Clones.predictDeterministicAddress(
            implementation, keccak256(abi.encode(_payees, _shares, _nonce)), address(this)
        );
    }
}
