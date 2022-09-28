// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "./interfaces/IFuroAutomatedTimeWithdraw.sol";
import "./interfaces/KeeperCompatibleInterface.sol";
import "./interfaces/IBentoBoxMinimal.sol";
import "./base/FuroStream.sol";
import "./base/FuroVesting.sol";
import "./interfaces/ITasker.sol";

contract FuroAutomatedTimeWithdraw is
    IFuroAutomatedTimeWithdraw,
    KeeperCompatibleInterface,
    ERC721TokenReceiver
{
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error NotOwner();
    error ToEarlyToWithdraw();

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event TaskCreation(uint256 taskId);
    event TaskUpdate(uint256 taskId);
    event TaskCancel(uint256 taskId);
    event TaskExecution(uint256 taskId, uint256 timestamp);

    /// -----------------------------------------------------------------------
    /// Immutable variables
    /// -----------------------------------------------------------------------

    IBentoBoxMinimal public immutable bentoBox;
    FuroStream internal immutable furoStream;
    FuroVesting internal immutable furoVesting;

    /// -----------------------------------------------------------------------
    /// Mutable variables
    /// -----------------------------------------------------------------------

    ///@notice TaskId => Task struct
    mapping(uint256 => Task) internal tasks;

    ///@notice Task amount, used to increment the mapping
    uint256 internal taskCount;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    ///@param _bentoBox Address of the BentoBox contract
    ///@param _furoStream Address of the furoStream contract
    ///@param _furoVesting Address of the furoVesting contract
    constructor(
        address _bentoBox,
        address _furoStream,
        address _furoVesting
    ) {
        bentoBox = IBentoBoxMinimal(_bentoBox);
        furoStream = FuroStream(_furoStream);
        furoVesting = FuroVesting(_furoVesting);
    }

    /// -----------------------------------------------------------------------
    /// State change functions
    /// -----------------------------------------------------------------------

    ///@notice Transfer Furo NFT to the contract and create an automated time withdraw task
    ///@param streamId Furo stream/vest id
    ///@param streamToken Furo stream/vest token address
    ///@param streamWithdrawTo Furo stream/vest to withdraw to
    ///@param streamWithdrawPeriod Minimum time between 2 automatic withdraw
    ///@param toBentoBox True if should withdraw to BentoBox
    ///@param vesting True for vesting and false for a stream
    ///@param taskData Calldata to execute on each withdraw on streamWithdrawTo address
    function createTask(
        uint256 streamId,
        address streamToken,
        address streamWithdrawTo,
        uint32 streamWithdrawPeriod,
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

        tasks[taskCount] = Task({
            streamId: streamId,
            streamToken: streamToken,
            streamOwner: msg.sender,
            streamWithdrawTo: streamWithdrawTo,
            streamWithdrawPeriod: streamWithdrawPeriod,
            streamLastWithdraw: uint128(block.timestamp),
            toBentoBox: toBentoBox,
            vesting: vesting,
            taskData: taskData
        });

        emit TaskCreation(taskCount);
        unchecked {
            taskCount += 1;
        }
    }

    ///@notice Update an existing automated time withdraw task
    ///@param taskId Id of the task
    ///@param streamWithdrawTo Furo stream/vest to withdraw to
    ///@param streamWithdrawPeriod Minimum time between 2 automatic withdraw
    ///@param toBentoBox True if should withdraw to BentoBox
    ///@param taskData Calldata to execute on each withdraw on streamWithdrawTo address
    function updateTask(
        uint256 taskId,
        address streamWithdrawTo,
        uint32 streamWithdrawPeriod,
        bool toBentoBox,
        bytes calldata taskData
    ) external {
        Task storage task = tasks[taskId];
        if (msg.sender != task.streamOwner) {
            revert NotOwner();
        }

        task.streamWithdrawTo = streamWithdrawTo;
        task.streamWithdrawPeriod = streamWithdrawPeriod;
        task.toBentoBox = toBentoBox;
        task.taskData = taskData;

        emit TaskUpdate(taskId);
    }

    ///@notice Cancel an existing automated time withdraw task and send back the Furo NFT
    ///@param taskId Id of the task
    ///@param to Address to send the Furo NFT to
    function cancelTask(uint256 taskId, address to) external {
        Task memory task = tasks[taskId];
        if (msg.sender != task.streamOwner) {
            revert NotOwner();
        }

        if (task.vesting) {
            furoVesting.safeTransferFrom(address(this), to, task.streamId);
        } else {
            furoStream.safeTransferFrom(address(this), to, task.streamId);
        }

        delete tasks[taskId];
        emit TaskCancel(taskId);
    }

    /// -----------------------------------------------------------------------
    /// Keepers functions
    /// -----------------------------------------------------------------------

    ///@notice Function checked by Chainlink keepers on each block to know if a task need to be executed
    ///@param checkData Start and Stop index to loop into the mapping looking for tasks to execute
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
            Task memory task = tasks[index];

            if (
                task.streamLastWithdraw != 0 &&
                task.streamLastWithdraw + task.streamWithdrawPeriod <
                block.timestamp
            ) {
                uint256 sharesToWithdraw;
                if (!task.vesting) {
                    (, sharesToWithdraw) = furoStream.streamBalanceOf(
                        task.streamId
                    );
                }
                return (true, abi.encode(index, sharesToWithdraw));
            }

            unchecked {
                index += 1;
            }
        }
    }

    ///@notice Function called by Chainlink keepers if checkUpKeep return true, execute an automated time withdraw task
    ///@param performData TaskId and sharesToWitdraw from the Furo stream/vesting
    function performUpkeep(bytes calldata performData) external {
        (uint256 taskId, uint256 sharesToWithdraw) = abi.decode(
            performData,
            (uint256, uint256)
        );
        Task storage task = tasks[taskId];

        //check if not too early
        if (
            task.streamLastWithdraw != 0 &&
            task.streamLastWithdraw + task.streamWithdrawPeriod >
            block.timestamp
        ) {
            revert ToEarlyToWithdraw();
        }

        if (task.vesting) {
            furoVesting.withdraw(task.streamId, "", true);
            sharesToWithdraw = bentoBox.balanceOf(
                task.streamToken,
                address(this)
            ); //use less gas than vestBalance()
            _transferToken(
                task.streamToken,
                address(this),
                task.streamWithdrawTo,
                sharesToWithdraw,
                task.toBentoBox
            );
            if (task.taskData.length > 0) {
                ITasker(task.streamWithdrawTo).onTaskReceived(task.taskData);
            }
        } else {
            furoStream.withdrawFromStream(
                task.streamId,
                sharesToWithdraw,
                task.streamWithdrawTo,
                task.toBentoBox,
                task.taskData
            );
        }

        task.streamLastWithdraw = uint128(block.timestamp);
        emit TaskExecution(taskId, block.timestamp);
    }

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

    /// -----------------------------------------------------------------------
    /// View functions
    /// -----------------------------------------------------------------------

    ///@notice Getter function to get task infos
    ///@param taskId Id of the task
    ///@return Task Task struct containing all its informations
    function getTask(uint256 taskId) external view returns (Task memory) {
        return tasks[taskId];
    }
}
