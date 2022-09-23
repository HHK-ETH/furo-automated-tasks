// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "./interfaces/IFuroAutomatedTimeWithdraw.sol";
import "./interfaces/KeeperCompatibleInterface.sol";
import "./interfaces/IFuroStream.sol";
import "./interfaces/IFuroVesting.sol";

contract FuroAutomatedTimeWithdraw is
    IFuroAutomatedTimeWithdraw,
    KeeperCompatibleInterface
{
    error NotOwner();

    event AutomatedTimeWithdrawExecution(uint256 streamId, uint256 timestamp);

    IFuroStream internal immutable furoStream;
    IFuroVesting internal immutable furoVesting;

    mapping(uint256 => AutomatedTimeWithdraw) public automatedTimeWithdraws;

    uint256 public automatedTimeWithdrawAmount;

    constructor(address _furoStream, address _furoVesting) {
        furoStream = IFuroStream(_furoStream);
        furoVesting = IFuroVesting(_furoVesting);
    }

    function createAutomatedWithdraw(
        uint256 streamId,
        address streamWithdrawTo,
        uint64 streamWithdrawPeriod,
        bool toBentoBox,
        bool vesting,
        bytes calldata taskData
    ) external {
        if (vesting) {
            if (msg.sender != furoVesting.ownerOf(streamId)) {
                revert NotOwner();
            }
            furoVesting.safeTransferFrom(msg.sender, address(this), streamId);
        } else {
            if (msg.sender != furoStream.ownerOf(streamId)) {
                revert NotOwner();
            }
            furoStream.safeTransferFrom(msg.sender, address(this), streamId);
        }

        automatedTimeWithdraws[
            automatedTimeWithdrawAmount
        ] = AutomatedTimeWithdraw({
            streamId: streamId,
            streamOwner: msg.sender,
            streamWithdrawTo: streamWithdrawTo,
            streamWithdrawPeriod: streamWithdrawPeriod,
            streamLastWithdraw: block.timestamp,
            toBentoBox: toBentoBox,
            vesting: vesting,
            taskData: taskData
        });
        automatedTimeWithdrawAmount += 1;
    }

    function updateAutomatedWithdraw(
        uint256 automatedTimeWithdrawId,
        address streamWithdrawTo,
        uint64 streamWithdrawPeriod,
        bool toBentoBox,
        bytes calldata taskData
    ) external {
        AutomatedTimeWithdraw
            storage automatedTimeWithdraw = automatedTimeWithdraws[
                automatedTimeWithdrawId
            ];
        if (msg.sender != automatedTimeWithdraw.streamOwner) {
            revert NotOwner();
        }

        automatedTimeWithdraw.streamWithdrawTo = streamWithdrawTo;
        automatedTimeWithdraw.streamWithdrawPeriod = streamWithdrawPeriod;
        automatedTimeWithdraw.toBentoBox = toBentoBox;
        automatedTimeWithdraw.taskData = taskData;
    }

    function cancelAutomatedWithdraw(
        uint256 automatedTimeWithdrawId,
        address to
    ) external {
        AutomatedTimeWithdraw
            memory automatedTimeWithdraw = automatedTimeWithdraws[
                automatedTimeWithdrawId
            ];
        if (msg.sender != automatedTimeWithdraw.streamOwner) {
            revert NotOwner();
        }

        if (automatedTimeWithdraw.vesting) {
            furoVesting.safeTransferFrom(
                address(this),
                to,
                automatedTimeWithdraw.streamId
            );
        } else {
            furoStream.safeTransferFrom(
                address(this),
                to,
                automatedTimeWithdraw.streamId
            );
        }

        delete automatedTimeWithdraws[automatedTimeWithdrawId];
    }

    function checkUpkeep(bytes calldata checkData)
        external
        returns (bool upkeepNeeded, bytes memory performData)
    {}

    function performUpkeep(bytes calldata performData) external {}
}
