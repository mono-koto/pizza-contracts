// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Clones} from "openzeppelin-contracts/proxy/Clones.sol";
import {IPizzaInitializer} from "./IPizzaInitializer.sol";
import {Context} from "openzeppelin-contracts/utils/Context.sol";

event PizzaCreated(address indexed pizza);

/**
 * @title PizzaFactory
 * @dev A contract for creating {IPizzaInitializer} splitter contracts.
 */
contract PizzaFactory is Context {
    /* //////////////////////////////////////////////////////////////////////// 
                                       Storage
    //////////////////////////////////////////////////////////////////////// */

    /**
     * @dev The address of the implementation contract.
     */
    address public implementation;

    /**
     * @dev A mapping that stores pizzas created.
     * The key is the address of the pizza owner, and the value is a boolean indicating creator.
     */
    mapping(address => address) public pizzas;

    /* //////////////////////////////////////////////////////////////////////// 
                                       Constructor
    //////////////////////////////////////////////////////////////////////// */

    constructor(address _impl) {
        implementation = _impl;
    }

    /* //////////////////////////////////////////////////////////////////////// 
                                       Factory
    //////////////////////////////////////////////////////////////////////// */

    function create(address[] memory _payees, uint256[] memory _shares) external returns (address pizza) {
        pizza = address(Clones.clone(implementation));
        _initPizza(pizza, _payees, _shares);
    }

    function createDeterministic(address[] memory _payees, uint256[] memory _shares, uint256 _salt)
        external
        returns (address pizza)
    {
        pizza = address(Clones.cloneDeterministic(implementation, keccak256(abi.encode(_payees, _shares, _salt))));
        _initPizza(pizza, _payees, _shares);
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

    /* //////////////////////////////////////////////////////////////////////// 
                                       Private
    //////////////////////////////////////////////////////////////////////// */

    function _initPizza(address _pizza, address[] memory _payees, uint256[] memory _shares) private {
        IPizzaInitializer(_pizza).initialize(_payees, _shares);
        pizzas[_pizza] = _msgSender();
        emit PizzaCreated(_pizza);
    }
}
