// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {FuroAutomatedTimeWithdraw, ERC721TokenReceiver, Task} from "./../FuroAutomatedTimeWithdraw.sol";
import {ERC20Mock} from "./../mock/ERC20Mock.sol";
import {BentoBoxV1, IERC20} from "./../flat/BentoBoxFlat.sol";
import {FuroStream, IFuroStream} from "./../base/FuroStream.sol";
import {FuroStreamRouter} from "./../base/FuroStreamRouter.sol";
import {FuroVesting, IFuroVesting} from "./../base/FuroVesting.sol";
import {FuroVestingRouter} from "./../base/FuroVestingRouter.sol";

contract TestFuroAutomatedTimeWithdraw is Test {
    ERC20Mock WETH;
    BentoBoxV1 bentobox;
    FuroStream furoStream;
    FuroStreamRouter furoStreamRouter;
    FuroVesting furoVesting;
    FuroVestingRouter furoVestingRouter;
    FuroAutomatedTimeWithdraw furoAutomatedTimeWithdraw;

    ///@notice Deploy contracts needed for each tests
    function setUp() public {
        //Deploy contracts needed
        WETH = new ERC20Mock("WETH", "WETH", 18);
        bentobox = new BentoBoxV1(IERC20(address(WETH)));
        furoStream = new FuroStream(address(bentobox), address(WETH));
        bentobox.whitelistMasterContract(address(furoStream), true);
        furoStreamRouter = new FuroStreamRouter(
            address(bentobox),
            address(furoStream),
            address(WETH)
        );
        bentobox.whitelistMasterContract(address(furoStreamRouter), true);

        furoVesting = new FuroVesting(address(bentobox), address(WETH));
        bentobox.whitelistMasterContract((address(furoVesting)), true);
        furoVestingRouter = new FuroVestingRouter(
            address(bentobox),
            address(furoVesting),
            address(WETH)
        );
        bentobox.whitelistMasterContract((address(furoVestingRouter)), true);

        furoAutomatedTimeWithdraw = new FuroAutomatedTimeWithdraw(
            address(bentobox),
            address(furoStream),
            address(furoVesting)
        );

        //Mint ETH & WETH tokens
        vm.deal(address(this), 100 * 1e18);
        address(WETH).call{value: 20 * 1e18}("");

        //Create a test stream and approve it
        WETH.approve(address(bentobox), 10 * 1e18);
        bentobox.setMasterContractApproval(
            address(this),
            address(furoStreamRouter),
            true,
            0,
            bytes32(0),
            bytes32(0)
        );
        furoStreamRouter.createStream(
            address(this),
            address(WETH),
            uint64(block.timestamp),
            uint64(block.timestamp + 3600),
            10 * 1e18,
            false,
            0
        );
        furoStream.approve(address(furoAutomatedTimeWithdraw), 1000);

        //Create a test vesting and approve it
        WETH.approve(address(bentobox), 10 * 1e18);
        bentobox.setMasterContractApproval(
            address(this),
            address(furoVestingRouter),
            true,
            0,
            bytes32(0),
            bytes32(0)
        );
        furoVestingRouter.createVesting(
            IFuroVesting.VestParams({
                token: address(WETH),
                recipient: address(this),
                start: uint32(block.timestamp),
                cliffDuration: 0,
                stepDuration: 3600,
                steps: 1,
                stepPercentage: 100,
                amount: 10 * 1e18,
                fromBentoBox: false
            }),
            0
        );
        furoVesting.approve(address(furoAutomatedTimeWithdraw), 1);
    }

    ///@notice Try to create a task from a Furo stream
    function testCreateStreamAutomaticTimeWithdraw() public {
        furoAutomatedTimeWithdraw.createTask(
            1000,
            address(WETH),
            address(this),
            600,
            false,
            false,
            ""
        );
        Task memory task = furoAutomatedTimeWithdraw.getTask(0);
        assertEq(task.streamId, 1000);
        assertEq(task.streamToken, address(WETH));
        assertEq(task.streamWithdrawTo, address(this));
        assertEq(task.streamWithdrawPeriod, 600);
        assertEq(task.toBentoBox, false);
        assertEq(task.taskData, "");
    }

    ///@notice Try to create a task from a Furo vesting
    function testCreateVestingAutomaticTimeWithdraw() public {
        furoAutomatedTimeWithdraw.createTask(
            1,
            address(WETH),
            address(this),
            600,
            false,
            true,
            ""
        );
        Task memory task = furoAutomatedTimeWithdraw.getTask(0);
        assertEq(task.streamId, 1);
        assertEq(task.streamToken, address(WETH));
        assertEq(task.streamWithdrawTo, address(this));
        assertEq(task.streamWithdrawPeriod, 600);
        assertEq(task.toBentoBox, false);
        assertEq(task.taskData, "");
    }

    ///@notice Try to update an existing task
    function testUpdateAutomaticTimeWithdraw() public {
        furoAutomatedTimeWithdraw.createTask(
            1000,
            address(WETH),
            address(this),
            600,
            false,
            false,
            ""
        );
        furoAutomatedTimeWithdraw.updateTask(0, address(this), 300, true, "");
        Task memory task = furoAutomatedTimeWithdraw.getTask(0);
        assertEq(task.streamWithdrawTo, address(this));
        assertEq(task.streamWithdrawPeriod, 300);
        assertEq(task.toBentoBox, true);
        assertEq(task.taskData, "");
    }

    ///@notice Try to update a task without being its owner
    function testFailUpdateAutomaticTimeWithdraw_NotOwner() public {
        furoAutomatedTimeWithdraw.createTask(
            1000,
            address(WETH),
            address(this),
            600,
            false,
            false,
            ""
        );
        vm.prank(address(1));
        furoAutomatedTimeWithdraw.updateTask(0, address(this), 300, true, "");
    }

    ///@notice Try to cancel a Furo stream task
    function testCancelStreamAutomaticTimeWithdraw() public {
        furoAutomatedTimeWithdraw.createTask(
            1000,
            address(WETH),
            address(this),
            600,
            false,
            false,
            ""
        );
        furoAutomatedTimeWithdraw.cancelTask(0, address(1));
        Task memory task = furoAutomatedTimeWithdraw.getTask(0);
        assertEq(task.streamId, 0); //struct successfully deleted
        assertEq(furoStream.ownerOf(1000), address(1));
    }

    ///@notice Try to cancel a Furo vesting task
    function testCancelVestingAutomaticTimeWithdraw() public {
        furoAutomatedTimeWithdraw.createTask(
            1,
            address(WETH),
            address(this),
            600,
            false,
            true,
            ""
        );
        furoAutomatedTimeWithdraw.cancelTask(0, address(1));
        Task memory task = furoAutomatedTimeWithdraw.getTask(0);
        assertEq(task.streamId, 0); //struct successfully deleted
        assertEq(furoVesting.ownerOf(1), address(1));
    }

    ///@notice Try to cancel a task without being its owner
    function testFailCancelAutomaticTimeWithdraw_NotOwner() public {
        furoAutomatedTimeWithdraw.createTask(
            1000,
            address(WETH),
            address(this),
            600,
            false,
            false,
            ""
        );
        vm.prank(address(1));
        furoAutomatedTimeWithdraw.cancelTask(0, address(1));
    }

    ///@notice Check if CheckUpKeep return true only when a task can indeed be executed
    function testCheckUpKeep() public {
        furoAutomatedTimeWithdraw.createTask(
            1000,
            address(WETH),
            address(this),
            600,
            false,
            false,
            ""
        );
        (
            bool upkeepNeeded,
            bytes memory performData
        ) = furoAutomatedTimeWithdraw.checkUpkeep(abi.encode(0, 5));
        assertEq(upkeepNeeded, false); //to early
        assertEq(performData, "");
        //increase timestamp and check again
        vm.warp(block.timestamp + 601);
        (upkeepNeeded, performData) = furoAutomatedTimeWithdraw.checkUpkeep(
            abi.encode(0, 5)
        );
        (uint256 automatedTimeWithdrawId, uint256 sharesToWithdraw) = abi
            .decode(performData, (uint256, uint256));
        assertEq(upkeepNeeded, true);
        assertEq(automatedTimeWithdrawId, 0);
        (, uint256 streamBalance) = furoStream.streamBalanceOf(1000);
        assertEq(sharesToWithdraw, streamBalance);
    }

    ///@notice Try to execute a Furo stream task that is ready to be executed
    function testStreamPerformUpKeep() public {
        furoAutomatedTimeWithdraw.createTask(
            1000,
            address(WETH),
            address(this),
            600,
            false,
            false,
            ""
        );
        //increase timestamp to allow perfromUpKeep
        vm.warp(block.timestamp + 601);
        (, bytes memory performData) = furoAutomatedTimeWithdraw.checkUpkeep(
            abi.encode(0, 5)
        );
        furoAutomatedTimeWithdraw.performUpkeep(performData);
        Task memory task = furoAutomatedTimeWithdraw.getTask(0);
        (, uint256 streamBalance) = furoStream.streamBalanceOf(1000);
        assertEq(task.streamLastWithdraw, block.timestamp);
        assertEq(streamBalance, 0);
    }

    ///@notice Try to execute a Furo vesting task that is ready to be executed
    function testVestingPerformUpKeep() public {
        furoAutomatedTimeWithdraw.createTask(
            1,
            address(WETH),
            address(this),
            600,
            false,
            true,
            ""
        );
        //increase timestamp to allow perfromUpKeep
        vm.warp(block.timestamp + 601);
        (, bytes memory performData) = furoAutomatedTimeWithdraw.checkUpkeep(
            abi.encode(0, 5)
        );
        furoAutomatedTimeWithdraw.performUpkeep(performData);
        Task memory task = furoAutomatedTimeWithdraw.getTask(0);
        uint256 vestBalance = furoVesting.vestBalance(1);
        assertEq(task.streamLastWithdraw, block.timestamp);
        assertEq(vestBalance, 0);
    }

    ///@notice Try to execute a task that is not ready to be executed
    function testFailPerformUpKeep_ToEarly() public {
        furoAutomatedTimeWithdraw.createTask(
            1000,
            address(WETH),
            address(this),
            600,
            false,
            false,
            ""
        );
        //0 as streamId & 0 as stream didn't start
        bytes memory performData = abi.encode(0, 0);
        furoAutomatedTimeWithdraw.performUpkeep(performData);
    }
}
