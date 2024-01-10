// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Initializable} from "openzeppelin-contracts/proxy/utils/Initializable.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {Context} from "openzeppelin-contracts/utils/Context.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";
import {Multicall} from "openzeppelin-contracts/utils/Multicall.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/utils/ReentrancyGuard.sol";

/**
 * @title Pizza
 * @notice This contract is a simplification of OpenZeppelin's PaymentSplitter.
 *      It allows for the release of ERC20 tokens as well as Ether.
 *      Releases are modified to be only callable in a batch, rather than individually.
 */
contract Pizza is Initializable, Context, Multicall, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /* //////////////////////////////////////////////////////////////////////// 
                                      Errors
    //////////////////////////////////////////////////////////////////////// */

    /**
     * @dev Error thrown when no payment is due.
     */
    error NoPaymentDue();

    /**
     * @dev Error thrown when an account has zero shares.
     */
    error PayeedHasZeroShares(address);

    /**
     * @dev Error thrown for duplicate account
     */
    error DuplicatePayee(address);

    /**
     * @dev Error thrown when an account is a zero address.
     */
    error NullPayee(address);

    /**
     * @dev Error thrown when the length of payees and shares are not equal.
     */
    error PayeeShareLengthMismatch();

    /**
     * @dev Error thrown when there are no payees.
     */
    error NoPayees();

    /* //////////////////////////////////////////////////////////////////////// 
                                      Events
    //////////////////////////////////////////////////////////////////////// */

    /**
     * @notice Emitted when a payment is received.
     * @param from The address from which the payment is received.
     * @param amount The amount of the payment.
     */
    event PaymentReceived(address from, uint256 amount);

    /**
     * @notice Emitted when funds are released.
     * @param amount The amount of funds released.
     */
    event Release(uint256 amount);

    /**
     * @notice Emitted when ERC20 tokens are released.
     * @param token The ERC20 token being released.
     * @param amount The amount of ERC20 tokens released.
     */
    event ERC20Release(IERC20 indexed token, uint256 amount);

    /* //////////////////////////////////////////////////////////////////////// 
                                      Constants
    //////////////////////////////////////////////////////////////////////// */

    uint256 private constant BIPS_PRECISION = 10000;

    /* //////////////////////////////////////////////////////////////////////// 
                                      Storage
    //////////////////////////////////////////////////////////////////////// */

    /**
     * @notice The total number of shares.
     */
    uint256 public totalShares;

    /**
     * @notice The total amount of funds released.
     */
    uint256 public totalReleased;

    /**
     * @notice The address of payee.
     */
    address[] public payee;

    /**
     * @notice The shares owed to each payee.
     */
    mapping(address => uint256) public shares;

    /**
     * @notice The total amount released for a token.
     */
    mapping(IERC20 => uint256) public erc20TotalReleased;

    /**
     * @notice The amount of funds released to a payee.
     */
    uint32 public releaseBountyBIPS;

    /* //////////////////////////////////////////////////////////////////////// 
                           Construction + Initialization
    //////////////////////////////////////////////////////////////////////// */

    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the contract with the specified payees and shares.
     * @param _payees The addresses of the payees.
     * @param _shares The corresponding shares of each payee.
     */
    function initialize(address[] memory _payees, uint256[] memory _shares) external initializer {
        if (_payees.length != _shares.length) {
            revert PayeeShareLengthMismatch();
        }
        if (_payees.length == 0) {
            revert NoPayees();
        }

        for (uint256 i = 0; i < _payees.length; i++) {
            _addPayee(_payees[i], _shares[i]);
        }
    }

    /* //////////////////////////////////////////////////////////////////////// 
                                      Receive   
    //////////////////////////////////////////////////////////////////////// */

    /**
     * @notice Receives ETH payments.
     * @dev This contract must be payable to receive ETH.
     *      Event is not reliably emitted in all possible cases where ETH
     *      balance is increased.
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /* //////////////////////////////////////////////////////////////////////// 
                                      Release
    //////////////////////////////////////////////////////////////////////// */

    /**
     * @notice Releases available ETH balance.
     */
    function release() external {
        uint256 totalReleasable = address(this).balance;
        address account;
        uint256 amountToPay;
        uint256 released;
        for (uint256 i = 0; i < payee.length; ++i) {
            account = payee[i];
            amountToPay = totalReleasable * shares[account] / totalShares;
            released += amountToPay;
            Address.sendValue(payable(account), amountToPay);
        }
        if (released == 0) {
            revert NoPaymentDue();
        }
        totalReleased += released;
        emit Release(released);
    }

    /**
     * @notice Releases available ERC20 token balance.
     * @param token The ERC20 token to be released.
     */
    function erc20Release(IERC20 token) external nonReentrant {
        uint256 erc20TotalReleasable = token.balanceOf(address(this));
        address account;
        uint256 amountToPay;
        uint256 released;
        for (uint256 i = 0; i < payee.length; ++i) {
            account = payee[i];
            amountToPay = (erc20TotalReleasable * shares[account]) / totalShares;
            released += amountToPay;
            SafeERC20.safeTransfer(token, payable(account), amountToPay);
        }
        if (released == 0) {
            revert NoPaymentDue();
        }
        erc20TotalReleased[token] += released;
        emit ERC20Release(token, released);
    }

    /* //////////////////////////////////////////////////////////////////////// 
                                      Getters
    //////////////////////////////////////////////////////////////////////// */

    /**
     * @notice Returns the number of payees.
     * @return The number of payees as a uint256 value.
     */
    function numPayees() external view returns (uint256) {
        return payee.length;
    }

    /**
     * @notice Returns an array of payees.
     * @return An array of addresses representing the payees.
     */
    function payees() external view returns (address[] memory) {
        return payee;
    }

    /* //////////////////////////////////////////////////////////////////////// 
                                      Helpers
    //////////////////////////////////////////////////////////////////////// */

    /**
     * @notice Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param _shares The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 _shares) private {
        if (account == address(0)) {
            revert NullPayee(account);
        }
        if (_shares == 0) {
            revert PayeedHasZeroShares(account);
        }
        if (shares[account] != 0) {
            revert DuplicatePayee(account);
        }

        payee.push(account);
        shares[account] = _shares;
        totalShares = totalShares + _shares;
    }
}
