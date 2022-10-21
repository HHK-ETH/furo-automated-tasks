// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import "./../base/BaseFuroAutomated.sol";
import {FuroStream} from "./../furo/FuroStream.sol";
import {FuroVesting} from "./../furo/FuroVesting.sol";

contract FuroAutomatedTime is BaseFuroAutomated {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error ToEarlyToWithdraw();

    /// -----------------------------------------------------------------------
    /// Immutable variables
    /// -----------------------------------------------------------------------

    function vesting() public pure returns (bool) {
        return _getArgBool(120);
    }

    function id() public pure returns (uint256) {
        return _getArgUint256(121);
    }

    /// -----------------------------------------------------------------------
    /// Mutable variables
    /// -----------------------------------------------------------------------

    address public withdrawTo;
    uint32 public withdrawPeriod;
    uint128 public lastWithdraw;
    bool public toBentoBox;
    bytes public taskData;

    /// -----------------------------------------------------------------------
    /// State change functions
    /// -----------------------------------------------------------------------

    ///@notice Init contract variables and set lastWithdraw
    function _init(bytes calldata data) internal override {
        _updateTask(data);
        lastWithdraw = uint128(block.timestamp);
    }

    ///@notice Update contract variables
    function _updateTask(bytes calldata data) internal override {
        (
            address _withdrawTo,
            uint32 _withdrawPeriod,
            bool _toBentoBox,
            bytes memory _taskData
        ) = abi.decode(data, (address, uint32, bool, bytes));
        withdrawTo = _withdrawTo;
        withdrawPeriod = _withdrawPeriod;
        toBentoBox = _toBentoBox;
        taskData = _taskData;
    }

    ///@notice Cancel Gelato task, send back Furo NFT and send back native token
    function _cancelTask(bytes calldata data) internal override {
        address to = abi.decode(data, (address));

        if (vesting()) {
            FuroVesting(furo()).safeTransferFrom(address(this), to, id());
        } else {
            FuroStream(furo()).safeTransferFrom(address(this), to, id());
        }
        _withdraw(to);
    }

    /// -----------------------------------------------------------------------
    /// Keepers functions
    /// -----------------------------------------------------------------------

    ///@notice Check if enough time has passed since last withdraw
    ///@return canExec True if enough time has passed
    ///@return execPayload The amount of shares to withdraw
    function checkTask()
        external
        view
        override
        returns (bool canExec, bytes memory execPayload)
    {
        if (lastWithdraw + withdrawPeriod < block.timestamp) {
            uint256 sharesToWithdraw;
            if (vesting() == false) {
                (, sharesToWithdraw) = FuroStream(furo()).streamBalanceOf(id());
            }
            return (
                true,
                abi.encodeWithSelector(
                    this.executeTask.selector,
                    abi.encode(sharesToWithdraw)
                )
            );
        }
    }

    ///@notice Function called by Gelato keepers if enough time has passed since last withdraw
    ///@param execPayload Amount of sharesToWitdraw if it's a stream
    function _executeTask(bytes calldata execPayload) internal override {
        uint256 sharesToWithdraw = abi.decode(execPayload, (uint256));

        //check if not too early
        if (lastWithdraw + withdrawPeriod > block.timestamp) {
            revert ToEarlyToWithdraw();
        }

        if (vesting()) {
            FuroVesting(furo()).withdraw(id(), "", true);
            //can't compute in checkTask as it can increase between check and execution which could result in a very small amount of token burn
            sharesToWithdraw = bentoBox().balanceOf(token(), address(this)); //use less gas than vestBalance()
            _transferToken(
                token(),
                address(this),
                withdrawTo,
                sharesToWithdraw,
                toBentoBox
            );
            if (taskData.length > 0) {
                ITasker(withdrawTo).onTaskReceived(taskData);
            }
        } else {
            FuroStream(furo()).withdrawFromStream(
                id(),
                sharesToWithdraw,
                withdrawTo,
                toBentoBox,
                taskData
            );
        }

        lastWithdraw = uint128(block.timestamp);
    }
}
