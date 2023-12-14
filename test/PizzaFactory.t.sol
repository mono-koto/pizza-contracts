// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {PizzaFactory} from "../src/PizzaFactory.sol";
import {Pizza} from "../src/Pizza.sol";

event PaymentReceived(address from, uint256 amount);

contract CounterTest is Test {
    PizzaFactory public f;
    address[] payees;
    uint256[] shares;

    function setUp() public {
        f = new PizzaFactory(address(new Pizza()));

        payees.push(address(0x1));
        payees.push(address(0x2));
        shares.push(2);
        shares.push(3);
    }

    function test_createDeterministic(uint256 nonce) public {
        address predicted = f.predict(payees, shares, nonce);
        Pizza p = Pizza(payable(address(f.createDeterministic(payees, shares, nonce))));
        assertEq(address(p), predicted);

        assertNotEq(address(p), address(0));
        assertNotEq(address(p), address(f));

        vm.expectRevert("ERC1167: create2 failed");
        f.createDeterministic(payees, shares, nonce);

        address sender = address(0x3);
        vm.deal(sender, 1 ether);
        vm.expectEmit(true, true, false, true);
        emit PaymentReceived(sender, 1 ether);
        vm.prank(sender);
        payable(p).transfer(1 ether);

        p.release();
        assertEq(payable(payees[0]).balance, 0.4 ether);
        assertEq(payable(payees[1]).balance, 0.6 ether);
    }
}
