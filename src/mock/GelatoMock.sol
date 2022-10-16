// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

contract GelatoMock {
    uint256 public fee;
    address public feeToken;

    function getFeeDetails() public view returns (uint256, address) {
        return (fee, feeToken);
    }

    function createTask(
        address target,
        bytes calldata targetSelector,
        address checker,
        bytes calldata checkerSelector
    ) public {}
}
