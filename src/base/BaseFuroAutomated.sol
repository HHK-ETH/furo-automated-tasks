// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import {Clone} from "./../clonesWithImmutableArgs/Clone.sol";
import {IBentoBoxMinimal} from "./../interfaces/IBentoBoxMinimal.sol";
import {ITasker} from "./../interfaces/ITasker.sol";

abstract contract BaseFuroAutomated is Clone {
    function bentoBox() internal pure returns (IBentoBoxMinimal) {
        return IBentoBoxMinimal(_getArgAddress(0));
    }

    function init(bytes calldata data) external virtual;

    function updateTask(bytes calldata data) external virtual;

    function cancelTask(bytes calldata data) external virtual;

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
            bentoBox().transfer(token, from, to, shares);
        } else {
            bentoBox().withdraw(token, from, to, 0, shares);
        }
    }
}
