// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Clones} from "openzeppelin-contracts/proxy/Clones.sol";
import {IPizzaInitializer} from "./IPizzaInitializer.sol";

event PizzaCreated(address indexed pizza);

contract PizzaFactory {
    address implementation;
    mapping(address => bool) public pizzas;

    constructor(address _impl) {
        implementation = _impl;
    }

    function create(address[] memory _payees, uint256[] memory _shares) external returns (address pizza) {
        pizza = address(Clones.clone(implementation));
        IPizzaInitializer(pizza).initialize(_payees, _shares);
        pizzas[pizza] = true;
        emit PizzaCreated(pizza);
    }

    function createDeterministic(address[] memory _payees, uint256[] memory _shares, uint256 _salt)
        external
        returns (address pizza)
    {
        pizza = address(Clones.cloneDeterministic(implementation, keccak256(abi.encode(_payees, _shares, _salt))));

        IPizzaInitializer(pizza).initialize(_payees, _shares);
        pizzas[pizza] = true;
        emit PizzaCreated(pizza);
    }

    function predict(address[] memory _payees, uint256[] memory _shares, uint256 _salt)
        external
        view
        returns (address)
    {
        return Clones.predictDeterministicAddress(
            implementation, keccak256(abi.encode(_payees, _shares, _salt)), address(this)
        );
    }
}
