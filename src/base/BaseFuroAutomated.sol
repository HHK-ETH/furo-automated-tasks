// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import {Clone} from "./../clonesWithImmutableArgs/Clone.sol";
import {IBentoBoxMinimal} from "./../interfaces/IBentoBoxMinimal.sol";
import {ITasker} from "./../interfaces/ITasker.sol";

abstract contract BaseFuroAutomated is Clone {
    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event Funded(uint256 amount);

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error NotOwnerNorFactory();
    error NotOwner();

    /// -----------------------------------------------------------------------
    /// Immutable variables
    /// -----------------------------------------------------------------------

    function bentoBox() internal pure returns (IBentoBoxMinimal) {
        return IBentoBoxMinimal(_getArgAddress(0));
    }

    function factory() internal pure returns (address) {
        return _getArgAddress(20);
    }

    function furo() public pure returns (address) {
        return _getArgAddress(40);
    }

    function owner() public pure returns (address) {
        return _getArgAddress(60);
    }

    function token() public pure returns (address) {
        return _getArgAddress(80);
    }

    /// -----------------------------------------------------------------------
    /// modifiers
    /// -----------------------------------------------------------------------

    modifier onlyOwnerOrFactory() {
        if (msg.sender != owner() && msg.sender != factory()) {
            revert NotOwnerNorFactory();
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

    function updateTask(bytes calldata data) external virtual;

    function cancelTask(bytes calldata data) external virtual;

    function checkTask()
        external
        view
        virtual
        returns (bool canExec, bytes memory execPayload);

    function executeTask(bytes calldata execPayload) external virtual;

    //Should be used over a transfer
    function fund() external payable {
        emit Funded(msg.value);
    }

    //In case user wants to refill the contract without frontend/directly
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
}
