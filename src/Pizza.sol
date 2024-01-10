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
 * @dev This contract is a simplifications of OpenZeppelin's PaymentSplitter.
 *      It allows for the release of ERC20 tokens as well as Ether.
 *      Releases are modified to be only callable in a batch, rather than individually.
 */
contract Pizza is Initializable, Context, Multicall, ReentrancyGuard {
    using SafeERC20 for IERC20;

    error NoPaymentDue();
    error AccoundHasZeroShares(address);
    error DuplicateAccount(address);
    error AccountIsZeroAddress(address);
    error PayeeShareLengthMismatch();
    error NoPayees();

    /**
     * @dev Emitted when a payment is received.
     * @param from The address from which the payment is received.
     * @param amount The amount of the payment.
     */
    event PaymentReceived(address from, uint256 amount);

    /**
     * @dev Emitted when funds are released.
     * @param amount The amount of funds released.
     */
    event Release(uint256 amount);

    /**
     * @dev Emitted when ERC20 tokens are released.
     * @param token The ERC20 token being released.
     * @param amount The amount of ERC20 tokens released.
     */
    event ERC20Release(IERC20 indexed token, uint256 amount);

    /**
     * @dev The total number of shares.
     */
    uint256 public totalShares;

    /**
     * @dev The total amount of funds released.
     */
    uint256 public totalReleased;

    /**
     * @dev The address of payee.
     */
    address[] public payee;

    /**
     * @dev The shares owed to each payee.
     */
    mapping(address => uint256) public shares;

    /**
     * @dev The total amount released for a token.
     */
    mapping(IERC20 => uint256) public erc20TotalReleased;

    uint32 public releaseBountyBIPS;
    uint256 public constant BIPS_PRECISION = 10000;

    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract with the specified payees and shares.
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
     * @dev Releases available ETH balance.
     */
    function release() external {
        uint256 totalReleasable = address(this).balance;
        address account;
        uint256 amountToPay;
        uint256 released;
        for (uint256 i = 0; i < payee.length; i++) {
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
     * @dev Releases available ERC20 token balance.
     * @param token The ERC20 token to be released.
     */
    function erc20Release(IERC20 token) external nonReentrant {
        uint256 erc20TotalReleasable = token.balanceOf(address(this));
        address account;
        uint256 amountToPay;
        uint256 released;
        for (uint256 i = 0; i < payee.length; i++) {
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
     * @dev Returns the number of payees.
     * @return The number of payees as a uint256 value.
     */
    function numPayees() external view returns (uint256) {
        return payee.length;
    }

    /**
     * @dev Returns an array of payees.
     * @return An array of addresses representing the payees.
     */
    function payees() external view returns (address[] memory) {
        return payee;
    }

    /* //////////////////////////////////////////////////////////////////////// 
                                      Private
    //////////////////////////////////////////////////////////////////////// */

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param _shares The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 _shares) private {
        if (account == address(0)) {
            revert AccountIsZeroAddress(account);
        }
        if (_shares == 0) {
            revert AccoundHasZeroShares(account);
        }
        if (shares[account] != 0) {
            revert DuplicateAccount(account);
        }

        payee.push(account);
        shares[account] = _shares;
        totalShares = totalShares + _shares;
    }
}
