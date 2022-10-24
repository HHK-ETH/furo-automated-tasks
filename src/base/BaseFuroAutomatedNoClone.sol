// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import {Clone} from "./../clonesWithImmutableArgs/Clone.sol";
import {IBentoBoxMinimal} from "./../interfaces/IBentoBoxMinimal.sol";
import {ITasker} from "./../interfaces/ITasker.sol";
import {ERC721TokenReceiver} from "solmate/tokens/ERC721.sol";
import {IOps} from "./../interfaces/IOps.sol";
import {SafeERC20, IERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {FuroStream} from "./../furo/FuroStream.sol";
import {FuroVesting} from "./../furo/FuroVesting.sol";

abstract contract BaseFuroAutomatedNoClone is ERC721TokenReceiver {
    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event Funded(uint256 amount);
    event Withdraw(uint256 amount);
    event TaskUpdate(bytes data);
    event TaskCancel(bytes data);
    event TaskExecute(uint256 fee);

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error AlreadyInit();
    error NotOwner();

    /// -----------------------------------------------------------------------
    /// Immutable variables
    /// -----------------------------------------------------------------------

    IBentoBoxMinimal public immutable bentoBox;
    IOps public immutable ops;
    address public immutable gelato;
    address public immutable furo;
    address public immutable owner;
    address public immutable token;
    bool public immutable vesting;
    uint256 public immutable id;

    /// -----------------------------------------------------------------------
    /// Mutable variables
    /// -----------------------------------------------------------------------

    bytes32 public taskId; //Gelato OPS taskId hash

    /// -----------------------------------------------------------------------
    /// modifiers
    /// -----------------------------------------------------------------------

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    /// -----------------------------------------------------------------------
    /// external functions
    /// -----------------------------------------------------------------------

    constructor(
        address _bentoBox,
        address _ops,
        address _furo,
        address _owner,
        bool _vesting,
        uint256 _id
    ) {
        bentoBox = IBentoBoxMinimal(_bentoBox);
        ops = IOps(_ops);
        gelato = ops.gelato();
        furo = _furo;
        owner = _owner;
        vesting = _vesting;
        id = _id;
        address _token;
        if (vesting) {
            (, _token, , , , , , , ) = FuroVesting(furo).vests(id);
        } else {
            (, _token, , , , ) = FuroStream(furo).streams(id);
        }
        token = _token;
    }

    ///@notice Update the contracts data/params
    ///@param data Abi encoded data neeeded to update the contract
    function updateTask(bytes calldata data) external onlyOwner {
        _updateTask(data);
        emit TaskUpdate(data);
    }

    ///@notice updateTask() implementation logic
    function _updateTask(bytes calldata data) internal virtual;

    ///@notice Send back Furo NFT and Native tokens
    ///@param data Abi encoded data neeeded to cancel the task
    function cancelTask(bytes calldata data) external onlyOwner {
        _cancelTask(data);
        emit TaskCancel(data);
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
        (uint256 fee, ) = ops.getFeeDetails();
        (bool success, ) = gelato.call{value: fee}("");
        if (!success) {
            revert();
        }
        emit TaskExecute(fee);
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
            bentoBox.transfer(tokenAddress, from, to, shares);
        } else {
            bentoBox.withdraw(tokenAddress, from, to, 0, shares);
        }
    }
}
