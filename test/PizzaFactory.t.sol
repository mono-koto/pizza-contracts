// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test, console2} from "forge-std/Test.sol";
import {PizzaFactory, PizzaCreated} from "../src/PizzaFactory.sol";
import {Pizza} from "../src/Pizza.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {Clones} from "openzeppelin-contracts/proxy/Clones.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {DeployPizzaFactory} from "../script/PizzaFactory.s.sol";

event PaymentReceived(address from, uint256 amount);

contract PizzaFactoryTest is Test {
    PizzaFactory public f;
    address[] payees;
    uint256[] shares;

    function setUp() public {
        (, f) = new DeployPizzaFactory().run();

        payees.push(address(0x1));
        payees.push(address(0x2));
        shares.push(2);
        shares.push(3);
    }

    function test_createDeterministic(uint256 nonce) public {
        address predicted = f.predict(payees, shares, nonce);
        vm.expectEmit(true, true, true, true);
        emit PizzaCreated(predicted);
        Pizza p = Pizza(payable(address(f.createDeterministic(payees, shares, nonce))));
        assertEq(address(p), predicted);

        assertNotEq(address(p), address(0));
        assertNotEq(address(p), address(f));
        assertEq(p.payee(0), address(0x1));
        assertEq(p.payee(1), address(0x2));
        assertEq(p.shares(address(0x1)), 2);
        assertEq(p.shares(address(0x2)), 3);
        assertEq(p.numPayees(), 2);
        assertEq(p.payees().length, 2);
        assertEq(p.payees()[0], address(0x1));
        assertEq(p.payees()[1], address(0x2));
        assertEq(p.totalShares(), 5);
        assertEq(p.totalReleased(), 0);
        assertEq(p.erc20TotalReleased(IERC20(address(0))), 0);
    }

    function test_createDeterministicOnce(uint256 nonce) public {
        Pizza(payable(address(f.createDeterministic(payees, shares, nonce))));
        vm.expectRevert(abi.encodeWithSelector(Clones.ERC1167FailedCreateClone.selector));
        f.createDeterministic(payees, shares, nonce);
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
}
