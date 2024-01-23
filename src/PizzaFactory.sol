// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Clones} from "openzeppelin-contracts/proxy/Clones.sol";
import {IPizzaInitializer} from "./IPizzaInitializer.sol";

event PizzaCreated(address indexed pizza);

/**
 * @title PizzaFactory
 * @dev A contract for creating {IPizzaInitializer} splitter contracts.
 */
contract PizzaFactory {
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
        _initFreePizza(pizza, _payees, _shares);
    }

    function createDeterministic(address[] memory _payees, uint256[] memory _shares, uint256 _salt)
        external
        returns (address pizza)
    {
        pizza = address(Clones.cloneDeterministic(implementation, salt(_payees, _shares, 0, _salt)));
        _initFreePizza(pizza, _payees, _shares);
    }

    function createDeterministicAndRelease(
        address[] memory _payees,
        uint256[] memory _shares,
        uint256 _salt,
        uint256 _bounty,
        address[] memory _bountyTokens,
        address _bountyReceiver
    ) external returns (address pizza) {
        pizza = address(Clones.cloneDeterministic(implementation, salt(_payees, _shares, _bounty, _salt)));
        IPizzaInitializer(pizza).initializeWithBountyRelease(_payees, _shares, _bounty, _bountyTokens, _bountyReceiver);
        pizzas[pizza] = msg.sender;
        emit PizzaCreated(pizza);
    }

    function predict(address[] memory _payees, uint256[] memory _shares, uint256 _bounty, uint256 _salt)
        external
        view
        returns (address)
    {
        return Clones.predictDeterministicAddress(implementation, salt(_payees, _shares, _bounty, _salt), address(this));
    }

    /* //////////////////////////////////////////////////////////////////////// 
                                       Private
    //////////////////////////////////////////////////////////////////////// */

    function salt(address[] memory _payees, uint256[] memory _shares, uint256 _bounty, uint256 _salt)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_payees, _shares, _bounty, _salt));
    }

    function _initFreePizza(address _pizza, address[] memory _payees, uint256[] memory _shares) private {
        IPizzaInitializer(_pizza).initialize(_payees, _shares, 0);
        pizzas[_pizza] = msg.sender;
        emit PizzaCreated(_pizza);
    }
}
