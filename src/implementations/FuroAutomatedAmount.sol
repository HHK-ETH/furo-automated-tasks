// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import "./../base/BaseFuroAutomated.sol";
import {FuroStream} from "./../furo/FuroStream.sol";
import {FuroVesting} from "./../furo/FuroVesting.sol";

contract FuroAutomatedAmount is BaseFuroAutomated {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error NotEnoughToWithdraw();

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

    uint256 public minAmount;
    address public withdrawTo;
    bool public toBentoBox;
    bytes public taskData;

    /// -----------------------------------------------------------------------
    /// State change functions
    /// -----------------------------------------------------------------------

    ///@notice Init contract variables and set lastWithdraw
    function _init(bytes calldata data) internal override {
        _updateTask(data);
    }

    ///@notice Update contract variables
    function _updateTask(bytes calldata data) internal override {
        (
            address _withdrawTo,
            uint256 _minAmount,
            bool _toBentoBox,
            bytes memory _taskData
        ) = abi.decode(data, (address, uint256, bool, bytes));
        withdrawTo = _withdrawTo;
        minAmount = _minAmount;
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

    ///@notice Check if amount of token to claim is enough
    ///@return canExec True if amount is enough
    ///@return execPayload SharesToWithdraw and amount
    function checkTask()
        external
        view
        override
        returns (bool canExec, bytes memory execPayload)
    {
        uint256 sharesToWithdraw;
        if (vesting() == false) {
            (, sharesToWithdraw) = FuroStream(furo()).streamBalanceOf(id());
        } else {
            sharesToWithdraw = FuroVesting(furo()).vestBalance(id());
        }
        uint256 amount = bentoBox().toAmount(token(), sharesToWithdraw, false);
        if (amount > minAmount) {
            return (
                true,
                abi.encodeWithSelector(
                    this.executeTask.selector,
                    abi.encode(sharesToWithdraw, amount)
                )
            );
        }
    }

    ///@notice Function called by Gelato keepers if amount to claim is enough
    ///@param execPayload SharesToWitdraw and amount to withdraw
    function _executeTask(bytes calldata execPayload) internal override {
        (uint256 sharesToWithdraw, uint256 amountToWithdraw) = abi.decode(
            execPayload,
            (uint256, uint256)
        );

        //check if not too early
        if (amountToWithdraw > minAmount) {
            revert NotEnoughToWithdraw();
        }

        if (vesting()) {
            FuroVesting(furo()).withdraw(id(), "", true);
            //Need to be computed again as it can increase between check and execution which could result in a very small amount of token burn
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
    }
}
