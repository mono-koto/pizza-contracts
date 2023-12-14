// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Initializable} from "openzeppelin-contracts/proxy/utils/Initializable.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {Context} from "openzeppelin-contracts/utils/Context.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";

/**
 * @title Pizza
 * @dev This contract is a modification of OpenZeppelin's PaymentSplitter.
 *      It allows for the release of ERC20 tokens as well as Ether.
 *      Releases are modified to be only callable in a batch, rather than individually.
 */
contract Pizza is Initializable, Context {
    using SafeERC20 for IERC20;

    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 public totalShares;
    uint256 public totalReleased;

    mapping(address => uint256) public shares;
    mapping(address => uint256) public released;
    address[] public payee;

    mapping(IERC20 => uint256) public erc20TotalReleased;
    mapping(IERC20 => mapping(address => uint256)) public erc20Released;

    // uint32 public releaseBountyBIPS;
    // uint256 public constant BIPS_PRECISION = 10000;

    constructor() {
        _disableInitializers();
    }

    function initialize(address[] memory _payees, uint256[] memory _shares) external initializer {
        require(_payees.length == _shares.length, "PaymentSplitter: payees and shares length mismatch");
        require(_payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < _payees.length; i++) {
            _addPayee(_payees[i], _shares[i]);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the amount of payee's releasable Ether.
     */
    function releasable(address account) public view returns (uint256) {
        uint256 totalReceived = address(this).balance + totalReleased;
        return _pendingPayment(account, totalReceived, released[account]);
    }

    /**
     * @dev Getter for the amount of payee's releasable `token` tokens. `token` should be the address of an
     * IERC20 contract.
     */
    function releasable(IERC20 token, address account) public view returns (uint256) {
        uint256 totalReceived = token.balanceOf(address(this)) + erc20TotalReleased[token];
        return _pendingPayment(account, totalReceived, erc20Released[token][account]);
    }

    function release() external {
        for (uint256 i = 0; i < payee.length; i++) {
            _release(payable(payee[i]));
        }
    }

    function erc20Release(IERC20 token) external {
        for (uint256 i = 0; i < payee.length; i++) {
            _release(token, payable(payee[i]));
        }
    }

    /* //////////////////////////////////////////////////////////////////////// 
                                      Private
    //////////////////////////////////////////////////////////////////////// */

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function _release(address payable account) private {
        require(shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 payment = releasable(account);

        require(payment != 0, "PaymentSplitter: account is not due payment");

        // _totalReleased is the sum of all values in released.
        // If "_totalReleased += payment" does not overflow, then "released[account] += payment" cannot overflow.
        totalReleased += payment;
        unchecked {
            released[account] += payment;
        }

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function _release(IERC20 token, address account) private {
        require(shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 payment = releasable(token, account);

        require(payment != 0, "PaymentSplitter: account is not due payment");

        // erc20TotalReleased[token] is the sum of all values in erc20Released[token].
        // If "erc20TotalReleased[token] += payment" does not overflow, then "erc20Released[token][account] += payment"
        // cannot overflow.
        erc20TotalReleased[token] += payment;
        unchecked {
            erc20Released[token][account] += payment;
        }

        SafeERC20.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(address account, uint256 totalReceived, uint256 alreadyReleased)
        private
        view
        returns (uint256)
    {
        return (totalReceived * shares[account]) / totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param _shares The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 _shares) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(_shares > 0, "PaymentSplitter: shares are 0");
        require(shares[account] == 0, "PaymentSplitter: account already has shares");

        payee.push(account);
        shares[account] = _shares;
        totalShares = totalShares + _shares;
        emit PayeeAdded(account, _shares);
    }
}
