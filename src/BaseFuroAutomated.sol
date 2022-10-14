// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import "./interfaces/IBentoBoxMinimal.sol";

abstract contract BaseFuroAutomated {
    IBentoBoxMinimal immutable bentoBox;

    constructor(address _bentoBox) {
        bentoBox = IBentoBoxMinimal(_bentoBox);
    }

    function updateTask() external virtual;

    function cancelTask() external virtual;

    function checkTask()
        external
        view
        virtual
        returns (bool canExec, bytes memory execPayload);

    function executeTask(bytes calldata execPayload) external virtual;

    /// -----------------------------------------------------------------------
    /// Internal functions
    /// -----------------------------------------------------------------------

    ///@notice Helper function to transfer/withdraw tokens from bentobox
    ///@param token Address of the token to transfer
    ///@param from Address sending the tokens
    ///@param to Address receiving the tokens
    ///@param shares Shares to transfer/deposit
    ///@param toBentoBox True if stays in bentobox, false if withdraws from bentobox
    function _transferToken(
        address token,
        address from,
        address to,
        uint256 shares,
        bool toBentoBox
    ) internal {
        if (toBentoBox) {
            bentoBox.transfer(token, from, to, shares);
        } else {
            bentoBox.withdraw(token, from, to, 0, shares);
        }
    }
}
