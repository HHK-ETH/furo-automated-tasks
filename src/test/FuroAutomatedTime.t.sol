// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import "forge-std/Test.sol";

import {ERC20Mock} from "./../mock/ERC20Mock.sol";
import {BentoBoxV1, IERC20} from "./../flat/BentoBoxFlat.sol";
import {FuroStream, IFuroStream} from "./../furo/FuroStream.sol";
import {FuroStreamRouter} from "./../furo/FuroStreamRouter.sol";
import {FuroVesting, IFuroVesting} from "./../furo/FuroVesting.sol";
import {FuroVestingRouter} from "./../furo/FuroVestingRouter.sol";
import {FuroAutomatedTime, BaseFuroAutomated, ERC721TokenReceiver} from "./../FuroAutomatedTime.sol";
import {FuroAutomatedTimeFactory} from "./../FuroAutomatedTimeFactory.sol";
import {GelatoMock} from "./../mock/GelatoMock.sol";
import {AutoUnwrap} from "./../mock/AutoUnwrap.sol";

contract TestFuroAutomatedTime is Test, ERC721TokenReceiver {
    ERC20Mock WETH;
    BentoBoxV1 bentobox;
    FuroStream furoStream;
    FuroStreamRouter furoStreamRouter;
    FuroVesting furoVesting;
    FuroVestingRouter furoVestingRouter;
    FuroAutomatedTime implementation;
    FuroAutomatedTimeFactory factory;
    GelatoMock ops;

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

        //deploy gelato ops
        ops = new GelatoMock(
            payable(address(1)),
            0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
            1e16 //0.01 ETH
        );

        //deploy implementation and factory
        implementation = new FuroAutomatedTime();
        factory = new FuroAutomatedTimeFactory(
            address(bentobox),
            address(furoStream),
            address(furoVesting),
            address(ops), //replace with mock gelato ops
            payable(implementation)
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
        furoStream.approve(address(factory), 1000);

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
        furoVesting.approve(address(factory), 1);
    }

    ///@notice Helper function to easily create Furo Automated Time clone
    function _createBasicFuroAutomatedTimeStream()
        internal
        returns (FuroAutomatedTime furoAutomatedTime)
    {
        bytes memory data = abi.encode(
            uint256(1000),
            address(WETH),
            address(this),
            uint32(3600),
            false,
            false,
            bytes("")
        );
        furoAutomatedTime = FuroAutomatedTime(
            payable(factory.createFuroAutomated(data))
        );
        furoAutomatedTime.fund{value: 1 ether}();
    }

    ///@notice Helper function to easily create Furo Automated Time clone
    function _createBasicFuroAutomatedTimeVesting()
        internal
        returns (FuroAutomatedTime furoAutomatedTime)
    {
        bytes memory data = abi.encode(
            uint256(1),
            address(WETH),
            address(this),
            uint32(3600),
            true,
            false,
            bytes("")
        );
        furoAutomatedTime = FuroAutomatedTime(
            payable(factory.createFuroAutomated(data))
        );
        furoAutomatedTime.fund{value: 1 ether}();
    }

    function testCreateAutomatedTime_withStream() public {
        FuroAutomatedTime furoAutomatedTime = _createBasicFuroAutomatedTimeStream();
        assertEq(furoAutomatedTime.id(), uint256(1000));
        assertEq(furoAutomatedTime.vesting(), false);
        assertEq(furoAutomatedTime.token(), address(WETH));
        assertEq(furoAutomatedTime.owner(), address(this));
        assertEq(furoAutomatedTime.furo(), address(furoStream));
        assertEq(furoAutomatedTime.ops(), address(ops));
        assertEq(furoAutomatedTime.withdrawTo(), address(this));
        assertEq(furoAutomatedTime.withdrawPeriod(), uint32(3600));
        assertEq(furoAutomatedTime.lastWithdraw(), uint128(block.timestamp));
        assertEq(furoAutomatedTime.toBentoBox(), false);
        assertEq(furoAutomatedTime.taskData(), bytes(""));
    }

    function testCreateAutomatedTime_withVesting() public {
        FuroAutomatedTime furoAutomatedTime = _createBasicFuroAutomatedTimeVesting();
        assertEq(furoAutomatedTime.id(), uint256(1));
        assertEq(furoAutomatedTime.vesting(), true);
        assertEq(furoAutomatedTime.token(), address(WETH));
        assertEq(furoAutomatedTime.owner(), address(this));
        assertEq(furoAutomatedTime.furo(), address(furoVesting));
        assertEq(furoAutomatedTime.ops(), address(ops));
        assertEq(furoAutomatedTime.withdrawTo(), address(this));
        assertEq(furoAutomatedTime.withdrawPeriod(), uint32(3600));
        assertEq(furoAutomatedTime.lastWithdraw(), uint128(block.timestamp));
        assertEq(furoAutomatedTime.toBentoBox(), false);
        assertEq(furoAutomatedTime.taskData(), bytes(""));
    }

    function testUpdateAutomatedTime() public {
        FuroAutomatedTime furoAutomatedTime = _createBasicFuroAutomatedTimeStream();
        address withdrawTo = address(100);
        uint32 withdrawPeriod = 9999;
        bool toBentoBox = true;
        bytes memory taskData = "";
        bytes memory data = abi.encode(
            withdrawTo,
            withdrawPeriod,
            toBentoBox,
            taskData
        );
        furoAutomatedTime.updateTask(data);
        assertEq(furoAutomatedTime.withdrawTo(), withdrawTo);
        assertEq(furoAutomatedTime.withdrawPeriod(), withdrawPeriod);
        assertEq(furoAutomatedTime.toBentoBox(), toBentoBox);
        assertEq(furoAutomatedTime.taskData(), taskData);
    }

    function testCannotUpdateAutomatedTime_ifNotOwner() public {
        FuroAutomatedTime furoAutomatedTime = _createBasicFuroAutomatedTimeStream();
        vm.prank(address(2222));
        address withdrawTo = address(100);
        uint32 withdrawPeriod = 9999;
        bool toBentoBox = true;
        bytes memory taskData = "";
        bytes memory data = abi.encode(
            withdrawTo,
            withdrawPeriod,
            toBentoBox,
            taskData
        );
        vm.expectRevert(BaseFuroAutomated.NotOwner.selector);
        furoAutomatedTime.updateTask(data);
    }

    function testCancelAutomatedTime() public {
        FuroAutomatedTime furoAutomatedTime = _createBasicFuroAutomatedTimeStream();
        furoAutomatedTime.cancelTask(abi.encode(address(this)));
        assertEq(furoStream.ownerOf(furoAutomatedTime.id()), address(this));
    }

    function testCannotCancelAutomatedTime_ifNotOwner() public {
        FuroAutomatedTime furoAutomatedTime = _createBasicFuroAutomatedTimeStream();
        vm.prank(address(2222));
        vm.expectRevert(BaseFuroAutomated.NotOwner.selector);
        furoAutomatedTime.cancelTask(abi.encode(address(this)));
    }

    function testCannotInit_ifNotFactory() public {
        FuroAutomatedTime furoAutomatedTime = _createBasicFuroAutomatedTimeStream();
        vm.expectRevert(BaseFuroAutomated.NotFactory.selector);
        furoAutomatedTime.init("");
    }

    function testCheckTask_canExec() public {
        FuroAutomatedTime furoAutomatedTime = _createBasicFuroAutomatedTimeStream();
        vm.warp(block.timestamp + furoAutomatedTime.withdrawPeriod() + 1);
        (bool canExec, bytes memory execPayload) = furoAutomatedTime
            .checkTask();
        (, uint256 sharesToWithdraw) = FuroStream(furoAutomatedTime.furo())
            .streamBalanceOf(furoAutomatedTime.id());
        assertEq(canExec, true);
        assertEq(
            execPayload,
            abi.encodeWithSelector(
                BaseFuroAutomated.executeTask.selector,
                sharesToWithdraw
            )
        );
    }

    function testCheckTask_canNotExec() public {
        FuroAutomatedTime furoAutomatedTime = _createBasicFuroAutomatedTimeStream();
        (bool canExec, bytes memory execPayload) = furoAutomatedTime
            .checkTask();
        assertEq(canExec, false);
        assertEq(execPayload, bytes(""));
    }

    function testExecTask() public {
        FuroAutomatedTime furoAutomatedTime = _createBasicFuroAutomatedTimeStream();
        uint256 balance = WETH.balanceOf(furoAutomatedTime.withdrawTo());
        vm.warp(block.timestamp + furoAutomatedTime.withdrawPeriod() + 1);
        (, uint256 sharesToWithdraw) = FuroStream(furoAutomatedTime.furo())
            .streamBalanceOf(furoAutomatedTime.id());
        vm.prank(address(ops));
        furoAutomatedTime.executeTask(abi.encode(sharesToWithdraw));
        assertEq(furoAutomatedTime.lastWithdraw(), block.timestamp);
        assertEq(
            WETH.balanceOf(furoAutomatedTime.withdrawTo()),
            balance +
                bentobox.toAmount(
                    IERC20(address(WETH)),
                    sharesToWithdraw,
                    false
                )
        );
    }

    function testCannotExecTask_ifToEarly() public {
        FuroAutomatedTime furoAutomatedTime = _createBasicFuroAutomatedTimeStream();
        (, uint256 sharesToWithdraw) = FuroStream(furoAutomatedTime.furo())
            .streamBalanceOf(furoAutomatedTime.id());
        vm.prank(address(ops));
        vm.expectRevert(FuroAutomatedTime.ToEarlyToWithdraw.selector);
        furoAutomatedTime.executeTask(abi.encode(sharesToWithdraw));
    }

    function testExecTask_toBentoBox() public {
        FuroAutomatedTime furoAutomatedTime = _createBasicFuroAutomatedTimeStream();
        bytes memory data = abi.encode(
            furoAutomatedTime.withdrawTo(),
            furoAutomatedTime.withdrawPeriod(),
            true,
            furoAutomatedTime.taskData()
        );
        furoAutomatedTime.updateTask(data);
        uint256 balance = bentobox.balanceOf(
            IERC20(address(WETH)),
            furoAutomatedTime.withdrawTo()
        );
        vm.warp(block.timestamp + furoAutomatedTime.withdrawPeriod() + 1);
        (, uint256 sharesToWithdraw) = FuroStream(furoAutomatedTime.furo())
            .streamBalanceOf(furoAutomatedTime.id());
        vm.prank(address(ops));
        furoAutomatedTime.executeTask(abi.encode(sharesToWithdraw));

        assertEq(
            bentobox.balanceOf(
                IERC20(address(WETH)),
                furoAutomatedTime.withdrawTo()
            ),
            balance + sharesToWithdraw
        );
    }

    function testExecTask_execTaskDataOnWithdrawTo() public {
        FuroAutomatedTime furoAutomatedTime = _createBasicFuroAutomatedTimeStream();
        AutoUnwrap autoUnwrap = new AutoUnwrap(address(99), payable(WETH));
        vm.warp(block.timestamp + furoAutomatedTime.withdrawPeriod() + 1);
        (, uint256 sharesToWithdraw) = FuroStream(furoAutomatedTime.furo())
            .streamBalanceOf(furoAutomatedTime.id());
        bytes memory data = abi.encode(
            address(autoUnwrap),
            furoAutomatedTime.withdrawPeriod(),
            false,
            abi.encode(
                bentobox.toAmount(
                    IERC20(address(WETH)),
                    sharesToWithdraw,
                    false
                )
            )
        );
        furoAutomatedTime.updateTask(data);
        vm.prank(address(ops));
        furoAutomatedTime.executeTask(abi.encode(sharesToWithdraw));
        assertEq(furoAutomatedTime.lastWithdraw(), block.timestamp);
        assertEq(
            bentobox.toAmount(IERC20(address(WETH)), sharesToWithdraw, false),
            address(99).balance
        );
    }
}
