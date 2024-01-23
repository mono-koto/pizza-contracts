// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {Pizza} from "../src/Pizza.sol";
import {PizzaFactory} from "../src/PizzaFactory.sol";

/**
 * @title DeployPizzaFactory
 * @dev A script contract for deploying the PizzaFactory contract.
 */
contract DeployPizzaFactory is Script {
    function setUp() public {}

    function run() public returns (Pizza implementation, PizzaFactory factory) {
        vm.startBroadcast();
        bytes32 salt = bytes32(vm.envUint("DEPLOY_SALT"));
        implementation = new Pizza{salt: salt}();
        factory = new PizzaFactory{salt: salt}(address(implementation));
        vm.stopBroadcast();
    }
}
