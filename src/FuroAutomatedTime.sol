// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import "./base/BaseFuroAutomated.sol";
import {FuroStream} from "./furo/FuroStream.sol";
import {FuroVesting} from "./furo/FuroVesting.sol";

contract FuroAutomatedTime is BaseFuroAutomated {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error ToEarlyToWithdraw();

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event TaskUpdate(
        address withdrawTo,
        uint32 withdrawPeriod,
        bool toBentoBox,
        bytes taskData
    );
    event TaskCancel(address to);
    event TaskExecute(uint256 amount);

    /// -----------------------------------------------------------------------
    /// Immutable variables
    /// -----------------------------------------------------------------------

    function vesting() public pure returns (bool) {
        return _getArgBool(140);
    }

    function id() public pure returns (uint256) {
        return _getArgUint256(141);
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

    ///@notice Update contract variables
    ///@param data abi encoded (withdrawTo, withdrawPeriod, toBentoBox, taskData)
    function updateTask(bytes calldata data)
        external
        override
        onlyOwnerOrFactory
    {
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
        emit TaskUpdate(_withdrawTo, _withdrawPeriod, _toBentoBox, _taskData);
    }

    ///@notice Cancel task, send back funds and the Furo NFT
    ///@param data abi encoded address to send the Furo NFT to
    function cancelTask(bytes calldata data) external override onlyOwner {
        address to = abi.decode(data, (address));

        if (vesting()) {
            FuroVesting(furo()).safeTransferFrom(address(this), to, id());
        } else {
            FuroStream(furo()).safeTransferFrom(address(this), to, id());
        }
        to.call{value: address(this).balance}("");
        emit TaskCancel(to);
    }

    /// -----------------------------------------------------------------------
    /// Keepers functions
    /// -----------------------------------------------------------------------

    ///@notice Function checked by Gelato keepers to know if the task need to be executed
    function checkTask()
        external
        view
        override
        returns (bool canExec, bytes memory execPayload)
    {}

    ///@notice Function called by Gelato keepers if checkTask return true, execute an automated time withdraw
    ///@param execPayload TaskId and sharesToWitdraw from the Furo stream/vesting
    function _executeTask(bytes calldata execPayload) internal override {
        uint256 sharesToWithdraw = abi.decode(execPayload, (uint256));

        //check if not too early
        if (
            lastWithdraw != 0 && lastWithdraw + withdrawPeriod > block.timestamp
        ) {
            revert ToEarlyToWithdraw();
        }

        if (vesting()) {
            FuroVesting(furo()).withdraw(id(), "", true);
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
        emit TaskExecute(sharesToWithdraw);
    }
}
