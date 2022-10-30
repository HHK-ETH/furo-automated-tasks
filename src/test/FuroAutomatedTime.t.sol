// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import "./FuroAutomatedSetUp.sol";
import {FuroAutomatedTime, BaseFuroAutomated} from "./../implementations/FuroAutomatedTime.sol";
import {FuroAutomatedTimeFactory} from "./../implementations/FuroAutomatedTimeFactory.sol";
import {AutoUnwrap} from "./../mock/AutoUnwrap.sol";

contract TestFuroAutomatedTime is FuroAutomatedSetUp {
    FuroAutomatedTime implementation;
    FuroAutomatedTimeFactory factory;

    function _setUp() internal override {
        //deploy implementation and factory
        implementation = new FuroAutomatedTime();
        factory = new FuroAutomatedTimeFactory(
            address(bentobox),
            address(furoStream),
            address(furoVesting),
            address(ops), //replace with mock gelato ops
            payable(implementation)
        );
        //pre approve furo nfts
        furoStream.approve(address(factory), 1000);
        furoVesting.approve(address(factory), 1);
    }

    ///@notice Helper function to easily create Furo Automated Time clone
    function _createBasicFuroAutomatedTime(bool vesting)
        internal
        returns (FuroAutomatedTime furoAutomatedTime)
    {
        bytes memory data = abi.encode(
            vesting ? uint256(1) : uint256(1000),
            address(WETH),
            address(this),
            uint64(3600),
            vesting,
            false,
            bytes("")
        );
        furoAutomatedTime = FuroAutomatedTime(
            payable(factory.createFuroAutomated(data))
        );
        furoAutomatedTime.fund{value: 1 ether}();
    }

    function testCreateAutomatedTime_withStream() public {
        //exec
        FuroAutomatedTime furoAutomatedTime = _createBasicFuroAutomatedTime(
            false
        );

        //assert
        assertEq(furoAutomatedTime.id(), uint256(1000));
        assertEq(furoAutomatedTime.vesting(), false);
        assertEq(furoAutomatedTime.token(), address(WETH));
        assertEq(furoAutomatedTime.owner(), address(this));
        assertEq(furoAutomatedTime.furo(), address(furoStream));
        assertEq(address(furoAutomatedTime.ops()), address(ops));
        assertEq(furoAutomatedTime.withdrawTo(), address(this));
        assertEq(furoAutomatedTime.withdrawPeriod(), uint64(3600));
        assertEq(furoAutomatedTime.lastWithdraw(), uint128(block.timestamp));
        assertEq(furoAutomatedTime.toBentoBox(), false);
        assertEq(furoAutomatedTime.taskData(), bytes(""));
    }

    function testCreateAutomatedTime_withVesting() public {
        //exec
        FuroAutomatedTime furoAutomatedTime = _createBasicFuroAutomatedTime(
            true
        );

        //assert
        assertEq(furoAutomatedTime.id(), uint256(1));
        assertEq(furoAutomatedTime.vesting(), true);
        assertEq(furoAutomatedTime.token(), address(WETH));
        assertEq(furoAutomatedTime.owner(), address(this));
        assertEq(furoAutomatedTime.furo(), address(furoVesting));
        assertEq(address(furoAutomatedTime.ops()), address(ops));
        assertEq(furoAutomatedTime.withdrawTo(), address(this));
        assertEq(furoAutomatedTime.withdrawPeriod(), uint64(3600));
        assertEq(furoAutomatedTime.lastWithdraw(), uint128(block.timestamp));
        assertEq(furoAutomatedTime.toBentoBox(), false);
        assertEq(furoAutomatedTime.taskData(), bytes(""));
    }

    function testUpdateAutomatedTime() public {
        //setup
        FuroAutomatedTime furoAutomatedTime = _createBasicFuroAutomatedTime(
            false
        );
        address withdrawTo = address(100);
        uint64 withdrawPeriod = 9999;
        bool toBentoBox = true;
        bytes memory taskData = "";
        bytes memory data = abi.encode(
            withdrawTo,
            withdrawPeriod,
            toBentoBox,
            taskData
        );

        //exec
        furoAutomatedTime.updateTask(data);

        //assert
        assertEq(furoAutomatedTime.withdrawTo(), withdrawTo);
        assertEq(furoAutomatedTime.withdrawPeriod(), withdrawPeriod);
        assertEq(furoAutomatedTime.toBentoBox(), toBentoBox);
        assertEq(furoAutomatedTime.taskData(), taskData);
    }

    function testCannotUpdateAutomatedTime_ifNotOwner() public {
        //setup
        FuroAutomatedTime furoAutomatedTime = _createBasicFuroAutomatedTime(
            false
        );
        address withdrawTo = address(100);
        uint64 withdrawPeriod = 9999;
        bool toBentoBox = true;
        bytes memory taskData = "";
        bytes memory data = abi.encode(
            withdrawTo,
            withdrawPeriod,
            toBentoBox,
            taskData
        );
        //setup vm
        vm.prank(address(2222));
        vm.expectRevert(BaseFuroAutomated.NotOwner.selector);

        //exec
        furoAutomatedTime.updateTask(data);
    }

    function testCancelAutomatedTime() public {
        //setup
        FuroAutomatedTime furoAutomatedTime = _createBasicFuroAutomatedTime(
            false
        );
        uint256 balance = address(this).balance;
        uint256 cloneBalance = address(furoAutomatedTime).balance;

        //exec
        furoAutomatedTime.cancelTask(abi.encode(address(this)));

        //assert
        assertEq(furoStream.ownerOf(furoAutomatedTime.id()), address(this));
        assertEq(address(this).balance, balance + cloneBalance);
        assertEq(address(furoAutomatedTime).balance, 0);
    }

    function testCannotCancelAutomatedTime_ifNotOwner() public {
        //setup
        FuroAutomatedTime furoAutomatedTime = _createBasicFuroAutomatedTime(
            false
        );
        //setup vm
        vm.prank(address(2222));
        vm.expectRevert(BaseFuroAutomated.NotOwner.selector);

        //exec
        furoAutomatedTime.cancelTask(abi.encode(address(this)));
    }

    function testCannotInit_ifAlreadyInit() public {
        //setup
        FuroAutomatedTime furoAutomatedTime = _createBasicFuroAutomatedTime(
            false
        );
        //setup vm
        vm.expectRevert(BaseFuroAutomated.AlreadyInit.selector);

        //exec
        furoAutomatedTime.init("");
    }

    function testCheckTask_canExec() public {
        //setup
        FuroAutomatedTime furoAutomatedTime = _createBasicFuroAutomatedTime(
            false
        );
        //setup vm
        vm.warp(block.timestamp + furoAutomatedTime.withdrawPeriod() + 1);
        (, uint256 sharesToWithdraw) = FuroStream(furoAutomatedTime.furo())
            .streamBalanceOf(furoAutomatedTime.id());

        //exec
        (bool canExec, bytes memory execPayload) = furoAutomatedTime
            .checkTask();

        //assert
        assertEq(canExec, true);
        assertEq(
            execPayload,
            abi.encodeWithSelector(
                BaseFuroAutomated.executeTask.selector,
                abi.encode(sharesToWithdraw)
            )
        );
    }

    function testCheckTask_canNotExec() public {
        //setup
        FuroAutomatedTime furoAutomatedTime = _createBasicFuroAutomatedTime(
            false
        );

        //exec
        (bool canExec, bytes memory execPayload) = furoAutomatedTime
            .checkTask();

        //assert
        assertEq(canExec, false);
        assertEq(execPayload, bytes(""));
    }

    function testExecTask() public {
        //setup
        FuroAutomatedTime furoAutomatedTime = _createBasicFuroAutomatedTime(
            false
        );
        uint256 balance = WETH.balanceOf(furoAutomatedTime.withdrawTo());
        //setup vm
        vm.warp(block.timestamp + furoAutomatedTime.withdrawPeriod() + 1);
        (, uint256 sharesToWithdraw) = FuroStream(furoAutomatedTime.furo())
            .streamBalanceOf(furoAutomatedTime.id());
        (, bytes memory execPayload) = furoAutomatedTime.checkTask();
        vm.prank(address(ops));

        //exec
        (bool success, ) = address(furoAutomatedTime).call(execPayload);

        //assert
        assertEq(success, true);
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
        //setup
        FuroAutomatedTime furoAutomatedTime = _createBasicFuroAutomatedTime(
            false
        );
        (, uint256 sharesToWithdraw) = FuroStream(furoAutomatedTime.furo())
            .streamBalanceOf(furoAutomatedTime.id());

        //setup vm
        vm.prank(address(ops));
        vm.expectRevert(FuroAutomatedTime.ToEarlyToWithdraw.selector);

        //exec
        furoAutomatedTime.executeTask(abi.encode(sharesToWithdraw));
    }

    function testExecTask_toBentoBox() public {
        //setup
        FuroAutomatedTime furoAutomatedTime = _createBasicFuroAutomatedTime(
            false
        );
        bytes memory data = abi.encode(
            furoAutomatedTime.withdrawTo(),
            furoAutomatedTime.withdrawPeriod(),
            true, //set bento to true
            furoAutomatedTime.taskData()
        );
        furoAutomatedTime.updateTask(data);
        uint256 balance = bentobox.balanceOf(
            IERC20(address(WETH)),
            furoAutomatedTime.withdrawTo()
        );
        //setup vm
        vm.warp(block.timestamp + furoAutomatedTime.withdrawPeriod() + 1);
        (, uint256 sharesToWithdraw) = FuroStream(furoAutomatedTime.furo())
            .streamBalanceOf(furoAutomatedTime.id());
        vm.prank(address(ops));

        //exec
        furoAutomatedTime.executeTask(abi.encode(sharesToWithdraw));

        //assert
        assertEq(
            bentobox.balanceOf(
                IERC20(address(WETH)),
                furoAutomatedTime.withdrawTo()
            ),
            balance + sharesToWithdraw
        );
    }

    function testExecTask_execTaskDataOnWithdrawTo() public {
        //setup
        FuroAutomatedTime furoAutomatedTime = _createBasicFuroAutomatedTime(
            false
        );
        AutoUnwrap autoUnwrap = new AutoUnwrap(address(99), payable(WETH));
        //setup vm
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

        //exec
        furoAutomatedTime.executeTask(abi.encode(sharesToWithdraw));

        //assert
        assertEq(furoAutomatedTime.lastWithdraw(), block.timestamp);
        assertEq(
            bentobox.toAmount(IERC20(address(WETH)), sharesToWithdraw, false),
            address(99).balance
        );
    }
}
