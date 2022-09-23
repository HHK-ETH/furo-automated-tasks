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
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error NotOwner();

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event AutomatedTimeWithdrawExecution(uint256 streamId, uint256 timestamp);

    /// -----------------------------------------------------------------------
    /// Immutable variables
    /// -----------------------------------------------------------------------

    IFuroStream internal immutable furoStream;
    IFuroVesting internal immutable furoVesting;

    /// -----------------------------------------------------------------------
    /// Mutable variables
    /// -----------------------------------------------------------------------

    mapping(uint256 => AutomatedTimeWithdraw) public automatedTimeWithdraws;

    uint256 public automatedTimeWithdrawAmount;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(address _furoStream, address _furoVesting) {
        furoStream = IFuroStream(_furoStream);
        furoVesting = IFuroVesting(_furoVesting);
    }

    /// -----------------------------------------------------------------------
    /// State change functions
    /// -----------------------------------------------------------------------

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

    /// -----------------------------------------------------------------------
    /// Keepers functions
    /// -----------------------------------------------------------------------

    function checkUpkeep(bytes calldata checkData)
        external
        view
        returns (bool upkeepNeeded, bytes memory performData)
    {
        (uint256 index, uint256 stopIndex) = abi.decode(
            checkData,
            (uint256, uint256)
        );

        while (index < stopIndex) {
            AutomatedTimeWithdraw
                memory automatedTimeWithdraw = automatedTimeWithdraws[index];

            if (
                automatedTimeWithdraw.streamLastWithdraw +
                    automatedTimeWithdraw.streamWithdrawPeriod <
                block.timestamp
            ) {
                if (automatedTimeWithdraw.vesting) {
                    return (true, abi.encode(automatedTimeWithdraw));
                }
                (, uint256 amountToWithdraw) = furoStream.streamBalanceOf(
                    automatedTimeWithdraw.streamId
                );
                return (
                    true,
                    abi.encode(automatedTimeWithdraw, amountToWithdraw)
                );
            }

            unchecked {
                index += 1;
            }
        }
    }

    function performUpkeep(bytes calldata performData) external {}
}
