// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Initializable} from "openzeppelin-contracts/proxy/utils/Initializable.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {Context} from "openzeppelin-contracts/utils/Context.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";

/**
 * @title Pizza
 * @dev This contract is a simplifications of OpenZeppelin's PaymentSplitter.
 *      It allows for the release of ERC20 tokens as well as Ether.
 *      Releases are modified to be only callable in a batch, rather than individually.
 */
contract Pizza is Initializable, Context {
    using SafeERC20 for IERC20;

    event PaymentReceived(address from, uint256 amount);
    event Release(uint256 amount);
    event ERC20Release(IERC20 indexed token, uint256 amount);

    uint256 public totalShares;
    uint256 public totalReleased;
    address[] public payee;
    mapping(address => uint256) public shares;
    mapping(IERC20 => uint256) public erc20TotalReleased;

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

    function release() external {
        uint256 totalReleasable = address(this).balance;
        require(totalReleasable > 0, "PaymentSplitter: no payment is due");
        totalReleased += totalReleasable;
        for (uint256 i = 0; i < payee.length; i++) {
            _releaseTo(totalReleasable, payee[i]);
        }
        emit Release(totalReleasable);
    }

    function erc20Release(IERC20 token) external {
        uint256 erc20TotalReleasable = token.balanceOf(address(this));
        require(erc20TotalReleasable > 0, "PaymentSplitter: no payment is due");
        erc20TotalReleased[token] += erc20TotalReleasable;
        for (uint256 i = 0; i < payee.length; i++) {
            _erc20ReleaseTo(erc20TotalReleasable, token, payee[i]);
        }
        emit ERC20Release(token, erc20TotalReleasable);
    }

    /* //////////////////////////////////////////////////////////////////////// 
                                      Getters
    //////////////////////////////////////////////////////////////////////// */

    function numPayees() external view returns (uint256) {
        return payee.length;
    }

    function payees() external view returns (address[] memory) {
        return payee;
    }

    /* //////////////////////////////////////////////////////////////////////// 
                                      Private
    //////////////////////////////////////////////////////////////////////// */

    function _releaseTo(uint256 totalReleasable, address account) private {
        uint256 amountToPay = totalReleasable * shares[account] / totalShares;
        Address.sendValue(payable(account), amountToPay);
    }

    /**
     * @dev Releases a specified amount of ERC20 tokens to a specified account.
     * @param erc20TotalReleasable The amount of ERC20 tokens to release.
     * @param token The ERC20 token contract.
     * @param account The account to receive the released tokens.
     */
    function _erc20ReleaseTo(uint256 erc20TotalReleasable, IERC20 token, address account) private {
        uint256 amountToPay = erc20TotalReleasable * shares[account] / totalShares;
        SafeERC20.safeTransfer(token, payable(account), amountToPay);
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
    }
}
