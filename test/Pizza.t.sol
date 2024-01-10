// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test, console2} from "forge-std/Test.sol";
import {PizzaFactory, PizzaCreated} from "../src/PizzaFactory.sol";
import {Pizza} from "../src/Pizza.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {Clones} from "openzeppelin-contracts/proxy/Clones.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

event PaymentReceived(address from, uint256 amount);

contract PizzaTest is Test {
    PizzaFactory public f;
    address[] payees;
    uint256[] shares;
    Pizza pizza;

    function setUp() public {
        f = new PizzaFactory(address(new Pizza()));
        payees.push(address(0x1));
        payees.push(address(0x2));
        shares.push(2);
        shares.push(3);
        pizza = Pizza(payable(address(f.create(payees, shares))));
    }

    function test_emitPaymentReceived() public {
        address sender = address(0x3);
        vm.deal(sender, 1 ether);
        vm.expectEmit(true, true, false, true);
        emit PaymentReceived(sender, 1 ether);
        vm.prank(sender);
        Address.sendValue(payable(pizza), 1 ether);
    }

    function test_release() public {
        vm.deal(payable(pizza), 1 ether);
        pizza.release();
        assertEq(payable(payees[0]).balance, 0.4 ether);
        assertEq(payable(payees[1]).balance, 0.6 ether);
        assertEq(payable(pizza).balance, 0);
        assertEq(pizza.totalReleased(), 1 ether);
    }

    function test_releaseSmallAmount() public {
        vm.deal(payable(pizza), 1 wei);
        vm.expectRevert(abi.encodeWithSelector(Pizza.NoPaymentDue.selector));
        pizza.release();

        vm.deal(payable(pizza), 2 wei);
        pizza.release();
        assertEq(payable(payees[0]).balance, 0);
        assertEq(payable(payees[1]).balance, 1);
        assertEq(payable(pizza).balance, 1);
    }

    function test_erc20Release() public {
        MockERC20 token = new MockERC20("ERC20", "ERC20");
        token.transfer(address(pizza), 1e18);
        pizza.erc20Release(token);
        assertEq(token.balanceOf(payees[0]), 4e17);
        assertEq(token.balanceOf(payees[1]), 6e17);
        assertEq(token.balanceOf(address(pizza)), 0);
        assertEq(pizza.erc20TotalReleased(token), 1e18);
    }

    function test_erc20ReleaseSmallAmount() public {
        MockERC20 token = new MockERC20("ERC20", "ERC20");
        token.transfer(address(pizza), 1);
        vm.expectRevert(abi.encodeWithSelector(Pizza.NoPaymentDue.selector));
        pizza.erc20Release(token);
    }
}
