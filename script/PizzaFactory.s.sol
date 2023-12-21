// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {Pizza} from "../src/Pizza.sol";
import {PizzaFactory} from "../src/PizzaFactory.sol";

contract DeployPizzaFactory is Script {
    function setUp() public {}

    function run() public returns (Pizza implementation, PizzaFactory factory) {
        vm.startBroadcast();
        bytes32 salt = bytes32(vm.envUint("DEPLOY_SALT"));
        implementation = new Pizza{salt: salt}();
        factory = new PizzaFactory{salt: salt}(address(implementation));
    }
}

contract DeploySamplePizza is Script {
    function setUp() public {}

    function run(address factory) public returns (address) {
        PizzaFactory f = PizzaFactory(factory);
        vm.startBroadcast();

        address[] memory payees = new address[](2);
        payees[0] = vm.createWallet("wallet a").addr;
        payees[1] = vm.createWallet("wallet b").addr;
        uint256[] memory shares = new uint256[](2);
        shares[0] = 100;
        shares[1] = 100;
        return address(f.create(payees, shares));
    }
}
