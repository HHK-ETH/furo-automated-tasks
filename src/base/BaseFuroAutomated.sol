// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import {Clone} from "./../clonesWithImmutableArgs/Clone.sol";
import {IBentoBoxMinimal} from "./../interfaces/IBentoBoxMinimal.sol";
import {ITasker} from "./../interfaces/ITasker.sol";
import {ERC721TokenReceiver} from "solmate/tokens/ERC721.sol";
import {IOps} from "./../interfaces/IOps.sol";
import {SafeERC20, IERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract BaseFuroAutomated is Clone, ERC721TokenReceiver {
    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event Funded(uint256 amount);
    event Withdraw(uint256 amount);

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error AlreadyInit();
    error NotOwner();

    /// -----------------------------------------------------------------------
    /// Immutable variables
    /// -----------------------------------------------------------------------

    function bentoBox() internal pure returns (IBentoBoxMinimal) {
        return IBentoBoxMinimal(_getArgAddress(0));
    }

    function ops() public pure returns (IOps) {
        return IOps(_getArgAddress(20));
    }

    function gelato() public pure returns (address) {
        return _getArgAddress(40);
    }

    function furo() public pure returns (address) {
        return _getArgAddress(60);
    }

    function owner() public pure returns (address) {
        return _getArgAddress(80);
    }

    function token() public pure returns (address) {
        return _getArgAddress(100);
    }

    /// -----------------------------------------------------------------------
    /// Mutable variables
    /// -----------------------------------------------------------------------

    bytes32 public taskId; //Gelato OPS taskId hash

    /// -----------------------------------------------------------------------
    /// modifiers
    /// -----------------------------------------------------------------------

    modifier onlyInitOnce() {
        if (taskId != bytes32(0)) {
            revert AlreadyInit();
        }
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != owner()) {
            revert NotOwner();
        }
        _;
    }

    /// -----------------------------------------------------------------------
    /// external functions
    /// -----------------------------------------------------------------------

    ///@notice Called on contract creation by factory to init variables
    ///@param data Abi encoded data for initiating the newly created clone
    function init(bytes calldata data) external onlyInitOnce {
        _init(data);

        taskId = ops().createTaskNoPrepayment(
            address(this),
            this.executeTask.selector,
            address(this),
            abi.encodeWithSelector(this.checkTask.selector),
            0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE //native token
        );
    }

    ///@notice init() implementation logic
    function _init(bytes calldata data) internal virtual;

    ///@notice Update the contracts data/params
    ///@param data Abi encoded data neeeded to update the contract
    function updateTask(bytes calldata data) external onlyOwner {
        _updateTask(data);
    }

    ///@notice updateTask() implementation logic
    function _updateTask(bytes calldata data) internal virtual;

    ///@notice Send back Furo NFT and Native tokens
    ///@param data Abi encoded data neeeded to cancel the task
    function cancelTask(bytes calldata data) external onlyOwner {
        _cancelTask(data);
    }

    ///@notice cancelTask() implementation logic
    function _cancelTask(bytes calldata data) internal virtual;

    ///@notice Gelato keeper function to check if should execute
    function checkTask()
        external
        view
        virtual
        returns (bool canExec, bytes memory execPayload);

    ///@notice Gelato keeper execute function
    ///@param execPayload Abi encoded data neeeded to execute
    function executeTask(bytes calldata execPayload) external {
        _executeTask(execPayload);

        //pay gelato ops
        (uint256 fee, address feeToken) = ops().getFeeDetails();
        _transfer(fee, feeToken);
    }

    ///@notice executeTask() logic implementation
    ///@param execPayload Abi encoded data neeeded to execute
    function _executeTask(bytes calldata execPayload) internal virtual;

    ///@notice Fund the contract, should be used over a transfer
    function fund() external payable {
        emit Funded(msg.value);
    }

    ///@notice Withdraw funds from the contract
    ///@param to Address to withdraw to
    function withdraw(address to) external onlyOwner returns (bool success) {
        success = _withdraw(to);
    }

    ///@notice Withdraw funds from the contract
    ///@param to Address to withdraw to
    function _withdraw(address to) internal returns (bool success) {
        uint256 balance = address(this).balance;
        (success, ) = to.call{value: balance}("");
        if (success) {
            emit Withdraw(balance);
        }
    }

    ///@notice In case user wants to refill the contract without frontend/directly
    receive() external payable {
        emit Funded(msg.value);
    }

    /// -----------------------------------------------------------------------
    /// Internal functions
    /// -----------------------------------------------------------------------

    ///@notice Helper function to transfer/withdraw tokens from bentobox
    ///@param tokenAddress Address of the token to transfer
    ///@param from Address sending the tokens
    ///@param to Address receiving the tokens
    ///@param shares Shares to transfer/deposit
    ///@param toBentoBox True if stays in bentobox, false if withdraws from bentobox
    function _transferToken(
        address tokenAddress,
        address from,
        address to,
        uint256 shares,
        bool toBentoBox
    ) internal {
        if (toBentoBox) {
            bentoBox().transfer(tokenAddress, from, to, shares);
        } else {
            bentoBox().withdraw(tokenAddress, from, to, 0, shares);
        }
    }

    ///@notice Gelato compatible transfer function to pay fees
    function _transfer(uint256 _amount, address _paymentToken) internal {
        if (_paymentToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            (bool success, ) = gelato().call{value: _amount}("");
            require(success, "_transfer: ETH transfer failed");
        } else {
            SafeERC20.safeTransfer(IERC20(_paymentToken), gelato(), _amount);
        }
    }
}
