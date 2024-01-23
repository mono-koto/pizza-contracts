// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Initializable} from "openzeppelin-contracts/proxy/utils/Initializable.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";
import {Multicall} from "openzeppelin-contracts/utils/Multicall.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/utils/ReentrancyGuard.sol";

/**
 * @title Pizza
 * @notice This contract is a simplification of OpenZeppelin's PaymentSplitter.
 *      It allows for the release of ERC20 tokens as well as Ether.
 *      Releases are modified to be only callable in a batch, rather than individually.
 */
contract Pizza is Initializable, Multicall, ReentrancyGuard {
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

    /**
     * @dev Error thrown when the bounty is invalid.
     */
    error InvalidBounty();

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

    /**
     * @notice Emitted when the bounty is released.
     * @param receiver The address of the bounty receiver.
     * @param amount The amount of ETH released.
     */
    event PayBounty(address indexed receiver, uint256 amount);

    /**
     * @notice Emitted when the bounty is released.
     * @param token The ERC20 token being released.
     * @param receiver The address of the bounty receiver.
     * @param amount The amount of ERC20 tokens released.
     */
    event PayERC20Bounty(IERC20 indexed token, address indexed receiver, uint256 amount);

    /* //////////////////////////////////////////////////////////////////////// 
                                      Constants
    //////////////////////////////////////////////////////////////////////// */

    uint256 public constant BOUNTY_PRECISION = 1e6;

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
    uint256 public bounty;

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
    function initialize(address[] memory _payees, uint256[] memory _shares, uint256 _bounty) external initializer {
        _init(_payees, _shares, _bounty);
    }

    /**
     * @notice Initializes the contract with the specified payees and shares.
     * @param _payees The addresses of the payees.
     * @param _shares The corresponding shares of each payee.
     */
    function initializeWithBountyRelease(
        address[] calldata _payees,
        uint256[] calldata _shares,
        uint256 _bounty,
        address[] calldata _bountyTokens,
        address _bountyReceiver
    ) external initializer nonReentrant {
        _init(_payees, _shares, _bounty);

        bounty = _bounty;
        if (_bounty > 0 && _bountyReceiver != address(0)) {
            for (uint256 i = 0; i < _bountyTokens.length; i++) {
                address token = _bountyTokens[i];
                if (token == address(0)) {
                    _payBounty(_bountyReceiver);
                    _release();
                } else {
                    _payERC20Bounty(IERC20(token), _bountyReceiver);
                    _erc20Release(IERC20(token));
                }
            }
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
        emit PaymentReceived(msg.sender, msg.value);
    }

    /* //////////////////////////////////////////////////////////////////////// 
                                      Release
    //////////////////////////////////////////////////////////////////////// */

    /**
     * @notice Releases available ETH balance.
     */
    function release() external nonReentrant {
        _release();
    }

    /**
     * @dev Releases the bounty to the specified receiver.
     * @param _bountyReceiver The address of the receiver of the bounty.
     */
    function release(address _bountyReceiver) public nonReentrant {
        _payBounty(_bountyReceiver);
        _release();
    }

    /**
     * @notice Releases available ERC20 token balance.
     * @param token The ERC20 token to be released.
     */
    function erc20Release(IERC20 token) external nonReentrant {
        _erc20Release(token);
    }

    /**
     * @dev Releases ERC20 tokens to a specified bounty receiver.
     * @param token The ERC20 token contract address.
     * @param _bountyReceiver The address of the bounty receiver.
     */
    function erc20Release(IERC20 token, address _bountyReceiver) external nonReentrant {
        _payERC20Bounty(token, _bountyReceiver);
        _erc20Release(token);
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

    /**
     * @notice Releases the ETH bounty to the bounty receiver.
     * @param _bountyReceiver The address of the bounty receiver.
     */
    function _payBounty(address _bountyReceiver) private {
        uint256 bountyAmount = address(this).balance * bounty / BOUNTY_PRECISION;
        if (bountyAmount > 0) {
            Address.sendValue(payable(_bountyReceiver), bountyAmount);
            emit PayBounty(_bountyReceiver, bountyAmount);
        }
    }

    /**
     * @notice Releases the bounty to the bounty receiver.
     * @param _bountyToken The ERC20 tokens to be released.
     * @param _bountyReceiver The address of the bounty receiver.
     */
    function _payERC20Bounty(IERC20 _bountyToken, address _bountyReceiver) private {
        uint256 bountyAmount = _bountyToken.balanceOf(address(this)) * bounty / BOUNTY_PRECISION;
        if (bountyAmount > 0) {
            SafeERC20.safeTransfer(_bountyToken, payable(_bountyReceiver), bountyAmount);
            emit PayERC20Bounty(_bountyToken, _bountyReceiver, bountyAmount);
        }
    }

    /**
     * @dev Initializes the contract with the given payees, shares, and bounty.
     * @param _payees The addresses of the payees.
     * @param _shares The corresponding shares of each payee.
     * @param _bounty The bounty amount to be distributed among the payees.
     */
    function _init(address[] memory _payees, uint256[] memory _shares, uint256 _bounty) internal {
        if (_payees.length != _shares.length) {
            revert PayeeShareLengthMismatch();
        }
        if (_payees.length == 0) {
            revert NoPayees();
        }
        if (_bounty > BOUNTY_PRECISION) {
            revert InvalidBounty();
        }

        for (uint256 i = 0; i < _payees.length; i++) {
            _addPayee(_payees[i], _shares[i]);
        }
    }

    /**
     * @notice Releases available ETH balance.
     */
    function _release() internal {
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
     * @dev Releases ERC20 tokens.
     * @param token The ERC20 token to be released.
     */
    function _erc20Release(IERC20 token) internal {
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
}
