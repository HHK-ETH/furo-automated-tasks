// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

abstract contract BaseFuroAutomated {
    function checker()
        external
        view
        virtual
        returns (bool canExec, bytes memory execPayload);

    function executeTask(bytes calldata execPayload) external virtual;
}
