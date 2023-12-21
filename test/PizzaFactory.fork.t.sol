// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test, console2} from "forge-std/Test.sol";
import {PizzaFactory, PizzaCreated} from "../src/PizzaFactory.sol";
import {Pizza} from "../src/Pizza.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {Clones} from "openzeppelin-contracts/proxy/Clones.sol";

event PaymentReceived(address from, uint256 amount);

contract PizzaFactoryForkTest is Test {
    PizzaFactory public f;
    address[] payees;
    uint256[] shares;

    function setUp() public {
        vm.createSelectFork("mainnet", 18814000);

        f = new PizzaFactory(address(new Pizza()));

        payees.push(vm.createWallet("wallet a").addr);
        payees.push(vm.createWallet("wallet b").addr);
        shares.push(2);
        shares.push(3);
    }

    function test_cloneReceive() public {
        Pizza p = Pizza(payable(address(f.create(payees, shares))));

        address sender = address(0x3);
        vm.deal(sender, 3 ether);

        vm.startPrank(sender);

        vm.expectEmit(true, true, false, true);
        emit PaymentReceived(sender, 1 ether);
        payable(p).transfer(1 ether);

        vm.expectEmit(true, true, false, true);
        emit PaymentReceived(sender, 1 ether);
        bool ok = payable(p).send(1 ether);
        assertTrue(ok);

        vm.expectEmit(true, true, false, true);
        emit PaymentReceived(sender, 1 ether);
        (ok,) = payable(p).call{value: 1 ether}("");
        assertTrue(ok);
    }

    function test_release() public {
        Pizza p = Pizza(payable(address(f.create(payees, shares))));

        address sender = address(0x3);
        vm.deal(sender, 1 ether);
        vm.expectEmit(true, true, false, true);
        emit PaymentReceived(sender, 1 ether);
        vm.prank(sender);
        Address.sendValue(payable(p), 1 ether);

        assertEq(payable(payees[0]).balance, 0);
        assertEq(payable(payees[1]).balance, 0);

        p.release();
        assertEq(payable(payees[0]).balance, 0.4 ether);
        assertEq(payable(payees[1]).balance, 0.6 ether);
    }
}
