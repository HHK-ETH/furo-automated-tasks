// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

struct AutomatedTimeWithdraw {
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
    function createAutomatedWithdraw(
        uint256 streamId,
        address streamToken,
        address streamWithdrawTo,
        uint64 streamWithdrawPeriod,
        bool toBentoBox,
        bool vesting,
        bytes calldata taskData
    ) external;

    function cancelAutomatedWithdraw(uint256 streamId, address to) external;

    function updateAutomatedWithdraw(
        uint256 automatedTimeWithdrawId,
        address streamWithdrawTo,
        uint64 streamWithdrawPeriod,
        bool toBentoBox,
        bytes calldata taskData
    ) external;
}
