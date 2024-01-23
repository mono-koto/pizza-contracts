// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Clones} from "openzeppelin-contracts/proxy/Clones.sol";
import {IPizzaInitializer} from "./IPizzaInitializer.sol";

/**
 * @title PizzaFactory
 * @dev A contract for creating Pizza splitter contracts.
 * @author Mono Koto (mono-koto.eth)
 */
contract PizzaFactory {
    /* //////////////////////////////////////////////////////////////////////// 
                                       Events
    //////////////////////////////////////////////////////////////////////// */
    event PizzaCreated(address indexed pizza, address indexed creator);

    /* //////////////////////////////////////////////////////////////////////// 
                                       Storage
    //////////////////////////////////////////////////////////////////////// */

    /**
     * @dev The address of the implementation contract.
     */
    address public implementation;

    /* //////////////////////////////////////////////////////////////////////// 
                                       Constructor
    //////////////////////////////////////////////////////////////////////// */

    constructor(address _impl) {
        implementation = _impl;
    }

    /* //////////////////////////////////////////////////////////////////////// 
                                       Factory
    //////////////////////////////////////////////////////////////////////// */

    /**
     * @dev Creates a new Pizza contract with the given payees and shares.
     * @param _payees The addresses of the payees.
     * @param _shares The corresponding shares of each payee.
     * @return pizza address of the newly created Pizza contract.
     */
    function create(address[] memory _payees, uint256[] memory _shares) external returns (address pizza) {
        pizza = address(Clones.clone(implementation));
        IPizzaInitializer(pizza).initialize(_payees, _shares, 0);
        emit PizzaCreated(pizza, msg.sender);
    }

    /**
     * @dev Creates a new Pizza contract with the given payees, shares, and salt.
     * @param _payees The addresses of the payees.
     * @param _shares The corresponding shares of each payee.
     * @param _salt The salt value used for deterministic cloning.
     * @return pizza address of the newly created Pizza contract.
     */
    function create(address[] memory _payees, uint256[] memory _shares, uint256 _salt)
        external
        returns (address pizza)
    {
        pizza = address(Clones.cloneDeterministic(implementation, salt(_payees, _shares, 0, _salt)));
        IPizzaInitializer(pizza).initialize(_payees, _shares, 0);
        emit PizzaCreated(pizza, msg.sender);
    }

    /**
     * @dev Creates a new Pizza contract with the given payees, shares, salt, bounty, bounty tokens, and bounty receiver.
     * @param _payees The addresses of the payees.
     * @param _shares The corresponding shares of each payee.
     * @param _salt The salt value used for deterministic cloning.
     * @param _bounty The bounty amount to be released.
     * @param _bountyTokens The addresses of the bounty tokens.
     * @param _bountyReceiver The address of the bounty receiver.
     * @return pizza address of the newly created Pizza contract.
     */
    function createAndRelease(
        address[] memory _payees,
        uint256[] memory _shares,
        uint256 _salt,
        uint256 _bounty,
        address[] memory _bountyTokens,
        address _bountyReceiver
    ) external returns (address pizza) {
        pizza = address(Clones.cloneDeterministic(implementation, salt(_payees, _shares, _bounty, _salt)));
        IPizzaInitializer(pizza).initializeWithBountyRelease(_payees, _shares, _bounty, _bountyTokens, _bountyReceiver);
        emit PizzaCreated(pizza, msg.sender);
    }

    /**
     * @dev Predicts the address of the pizza contract with the given params
     *
     * @param _payees The addresses of the payees who will receive a share of the pizza order.
     * @param _shares The corresponding shares of each payee.
     * @param _bounty The bounty amount to be awarded to the successful predictor.
     * @param _salt A random value used in case multiple contracts are created with the same params.
     * @return The predicted address of the pizza contract.
     */
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
}
