// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test, console2} from "forge-std/Test.sol";
import {PizzaFactory} from "../src/PizzaFactory.sol";
import {Pizza} from "../src/Pizza.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {Clones} from "openzeppelin-contracts/proxy/Clones.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {DeployPizzaFactory} from "../script/PizzaFactory.s.sol";

event PaymentReceived(address from, uint256 amount);

contract PizzaTest is Test {
    PizzaFactory public f;
    address[] payees;
    uint256[] shares;
    Pizza pizza;
    MockERC20 token;

    function setUp() public {
        token = new MockERC20("ERC20", "ERC20");
        (, f) = new DeployPizzaFactory().run();
        payees.push(address(0x1));
        payees.push(address(0x2));
        shares.push(2);
        shares.push(3);
        pizza = Pizza(payable(address(f.create(payees, shares, 0))));
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

    function test_fuzzRelease(uint256 amount) public {
        vm.assume(amount < type(uint256).max / 10);
        vm.deal(payable(pizza), amount);

        uint256 expectedAmountA = shares[0] * amount / pizza.totalShares();
        uint256 expectedAMountB = shares[1] * amount / pizza.totalShares();
        if (expectedAmountA + expectedAMountB == 0) {
            vm.expectRevert(abi.encodeWithSelector(Pizza.NoPaymentDue.selector));
            pizza.release();
        } else {
            pizza.release();
            assertEq(payable(payees[0]).balance, expectedAmountA);
            assertEq(payable(payees[1]).balance, expectedAMountB);
            assertEq(payable(pizza).balance, amount - expectedAmountA - expectedAMountB);
            assertEq(pizza.totalReleased(), expectedAmountA + expectedAMountB);
        }
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
        token.transfer(address(pizza), 1e18);
        pizza.erc20Release(token);
        assertEq(token.balanceOf(payees[0]), 4e17);
        assertEq(token.balanceOf(payees[1]), 6e17);
        assertEq(token.balanceOf(address(pizza)), 0);
        assertEq(pizza.erc20TotalReleased(token), 1e18);
    }

    function test_erc20ReleaseSmallAmount() public {
        token.transfer(address(pizza), 1);
        vm.expectRevert(abi.encodeWithSelector(Pizza.NoPaymentDue.selector));
        pizza.erc20Release(token);
    }

    function test_bountyCreateInvalidBounty(uint256 salt, uint256 bounty) public {
        vm.assume(bounty > pizza.BOUNTY_PRECISION());
        address predicted = f.predict(payees, shares, bounty, salt);
        address[] memory bountyTokens = new address[](2);
        bountyTokens[0] = address(token);
        bountyTokens[1] = address(0);
        address bountyReceiver = address(0x4);
        token.transfer(address(predicted), 1e18);
        vm.deal(payable(predicted), 2e18);

        vm.expectRevert(abi.encodeWithSelector(Pizza.InvalidBounty.selector));
        f.createAndRelease(payees, shares, salt, bounty, bountyTokens, bountyReceiver);
    }

    function test_bountyCreate(uint256 salt) public {
        uint256 bounty = 1e4; // 0.01 aka 1%
        address predicted = f.predict(payees, shares, bounty, salt);

        // Now some balances accumulate on the undeployed address

        token.transfer(address(predicted), 1e18);
        vm.deal(payable(predicted), 2e18);

        // Now we a deployer/releaser comes along and is willing to pay to release
        // the funds. Their designated receiver will get the bounty.

        address[] memory bountyTokens = new address[](2);
        bountyTokens[0] = address(token);
        bountyTokens[1] = address(0);
        address bountyDeployer = address(0x3);
        address bountyReceiver = address(0x4);

        vm.prank(bountyDeployer);
        f.createAndRelease(payees, shares, salt, bounty, bountyTokens, bountyReceiver);

        assertEq(token.balanceOf(bountyDeployer), 0);
        assertEq(token.balanceOf(bountyReceiver), 1e16);
        assertEq(token.balanceOf(predicted), 0);
        assertEq(token.balanceOf(payees[0]), 396e15);
        assertEq(token.balanceOf(payees[1]), 594e15);

        assertEq(bountyDeployer.balance, 0);
        assertEq(bountyReceiver.balance, 2e16);
        assertEq(predicted.balance, 0);
        assertEq(payees[0].balance, 792e15);
        assertEq(payees[1].balance, 1188e15);
    }
}
