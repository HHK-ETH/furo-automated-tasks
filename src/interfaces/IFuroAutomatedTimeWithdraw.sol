// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

struct Task {
    uint256 streamId;
    address streamToken;
    address streamOwner;
    address streamWithdrawTo;
    uint256 streamWithdrawPeriod; //minimum time between each withdrawal
    uint256 streamLastWithdraw;
    bool toBentoBox;
    bool vesting; //true if vesting - false if stream
    bytes taskData;
}

interface IFuroAutomatedTimeWithdraw {
    function createTask(
        uint256 streamId,
        address streamToken,
        address streamWithdrawTo,
        uint64 streamWithdrawPeriod,
        bool toBentoBox,
        bool vesting,
        bytes calldata taskData
    ) external;

    function cancelTask(uint256 taskId, address to) external;

    function updateTask(
        uint256 taskId,
        address streamWithdrawTo,
        uint64 streamWithdrawPeriod,
        bool toBentoBox,
        bytes calldata taskData
    ) external;
}
