// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import "./FuroAutomatedSetUp.sol";
import {FuroAutomatedTimeNoClone, BaseFuroAutomatedNoClone} from "./../implementations/FuroAutomatedTimeNoClone.sol";
import {FuroAutomatedTimeFactoryNoClone} from "./../implementations/FuroAutomatedTimeFactoryNoClone.sol";
import {AutoUnwrap} from "./../mock/AutoUnwrap.sol";

contract TestFuroAutomatedTimeNoCloneNoClone is FuroAutomatedSetUp {
    FuroAutomatedTimeFactoryNoClone factory;

    function _setUp() internal override {
        //deploy factory
        factory = new FuroAutomatedTimeFactoryNoClone(
            address(bentobox),
            address(ops), //replace with mock gelato ops
            address(furoStream),
            address(furoVesting)
        );
        //pre approve furo nfts
        furoStream.approve(address(factory), 1000);
        furoVesting.approve(address(factory), 1);
    }

    ///@notice Helper function to easily create Furo Automated Time clone
    function _createBasicFuroAutomatedTimeNoClone(bool vesting)
        internal
        returns (FuroAutomatedTimeNoClone furoAutomatedTimeNoClone)
    {
        furoAutomatedTimeNoClone = factory.createFuroAutomated(
            vesting,
            vesting ? uint256(1) : uint256(1000),
            address(this),
            uint32(3600),
            false,
            ""
        );
        furoAutomatedTimeNoClone.fund{value: 1 ether}();
    }

    function testCreateAutomatedTimeNoClone_withStream() public {
        //exec
        FuroAutomatedTimeNoClone furoAutomatedTimeNoClone = _createBasicFuroAutomatedTimeNoClone(
                false
            );

        //assert
        assertEq(furoAutomatedTimeNoClone.id(), uint256(1000));
        assertEq(furoAutomatedTimeNoClone.vesting(), false);
        assertEq(furoAutomatedTimeNoClone.token(), address(WETH));
        assertEq(furoAutomatedTimeNoClone.owner(), address(this));
        assertEq(furoAutomatedTimeNoClone.furo(), address(furoStream));
        assertEq(address(furoAutomatedTimeNoClone.ops()), address(ops));
        assertEq(furoAutomatedTimeNoClone.withdrawTo(), address(this));
        assertEq(furoAutomatedTimeNoClone.withdrawPeriod(), uint32(3600));
        assertEq(
            furoAutomatedTimeNoClone.lastWithdraw(),
            uint128(block.timestamp)
        );
        assertEq(furoAutomatedTimeNoClone.toBentoBox(), false);
        assertEq(furoAutomatedTimeNoClone.taskData(), bytes(""));
    }

    function testCreateAutomatedTimeNoClone_withVesting() public {
        //exec
        FuroAutomatedTimeNoClone furoAutomatedTimeNoClone = _createBasicFuroAutomatedTimeNoClone(
                true
            );

        //assert
        assertEq(furoAutomatedTimeNoClone.id(), uint256(1));
        assertEq(furoAutomatedTimeNoClone.vesting(), true);
        assertEq(furoAutomatedTimeNoClone.token(), address(WETH));
        assertEq(furoAutomatedTimeNoClone.owner(), address(this));
        assertEq(furoAutomatedTimeNoClone.furo(), address(furoVesting));
        assertEq(address(furoAutomatedTimeNoClone.ops()), address(ops));
        assertEq(furoAutomatedTimeNoClone.withdrawTo(), address(this));
        assertEq(furoAutomatedTimeNoClone.withdrawPeriod(), uint32(3600));
        assertEq(
            furoAutomatedTimeNoClone.lastWithdraw(),
            uint128(block.timestamp)
        );
        assertEq(furoAutomatedTimeNoClone.toBentoBox(), false);
        assertEq(furoAutomatedTimeNoClone.taskData(), bytes(""));
    }

    function testUpdateAutomatedTimeNoClone() public {
        //setup
        FuroAutomatedTimeNoClone furoAutomatedTimeNoClone = _createBasicFuroAutomatedTimeNoClone(
                false
            );
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

        //exec
        furoAutomatedTimeNoClone.updateTask(data);

        //assert
        assertEq(furoAutomatedTimeNoClone.withdrawTo(), withdrawTo);
        assertEq(furoAutomatedTimeNoClone.withdrawPeriod(), withdrawPeriod);
        assertEq(furoAutomatedTimeNoClone.toBentoBox(), toBentoBox);
        assertEq(furoAutomatedTimeNoClone.taskData(), taskData);
    }

    function testCannotUpdateAutomatedTimeNoClone_ifNotOwner() public {
        //setup
        FuroAutomatedTimeNoClone furoAutomatedTimeNoClone = _createBasicFuroAutomatedTimeNoClone(
                false
            );
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
        //setup vm
        vm.prank(address(2222));
        vm.expectRevert(BaseFuroAutomatedNoClone.NotOwner.selector);

        //exec
        furoAutomatedTimeNoClone.updateTask(data);
    }

    function testCancelAutomatedTimeNoClone() public {
        //setup
        FuroAutomatedTimeNoClone furoAutomatedTimeNoClone = _createBasicFuroAutomatedTimeNoClone(
                false
            );
        uint256 balance = address(this).balance;
        uint256 cloneBalance = address(furoAutomatedTimeNoClone).balance;

        //exec
        furoAutomatedTimeNoClone.cancelTask(abi.encode(address(this)));

        //assert
        assertEq(
            furoStream.ownerOf(furoAutomatedTimeNoClone.id()),
            address(this)
        );
        assertEq(address(this).balance, balance + cloneBalance);
        assertEq(address(furoAutomatedTimeNoClone).balance, 0);
    }

    function testCannotCancelAutomatedTimeNoClone_ifNotOwner() public {
        //setup
        FuroAutomatedTimeNoClone furoAutomatedTimeNoClone = _createBasicFuroAutomatedTimeNoClone(
                false
            );
        //setup vm
        vm.prank(address(2222));
        vm.expectRevert(BaseFuroAutomatedNoClone.NotOwner.selector);

        //exec
        furoAutomatedTimeNoClone.cancelTask(abi.encode(address(this)));
    }

    function testCheckTask_canExec() public {
        //setup
        FuroAutomatedTimeNoClone furoAutomatedTimeNoClone = _createBasicFuroAutomatedTimeNoClone(
                false
            );
        //setup vm
        vm.warp(
            block.timestamp + furoAutomatedTimeNoClone.withdrawPeriod() + 1
        );
        (, uint256 sharesToWithdraw) = FuroStream(
            furoAutomatedTimeNoClone.furo()
        ).streamBalanceOf(furoAutomatedTimeNoClone.id());

        //exec
        (bool canExec, bytes memory execPayload) = furoAutomatedTimeNoClone
            .checkTask();

        //assert
        assertEq(canExec, true);
        assertEq(
            execPayload,
            abi.encodeWithSelector(
                BaseFuroAutomatedNoClone.executeTask.selector,
                abi.encode(sharesToWithdraw)
            )
        );
    }

    function testCheckTask_canNotExec() public {
        //setup
        FuroAutomatedTimeNoClone furoAutomatedTimeNoClone = _createBasicFuroAutomatedTimeNoClone(
                false
            );

        //exec
        (bool canExec, bytes memory execPayload) = furoAutomatedTimeNoClone
            .checkTask();

        //assert
        assertEq(canExec, false);
        assertEq(execPayload, bytes(""));
    }

    function testExecTask() public {
        //setup
        FuroAutomatedTimeNoClone furoAutomatedTimeNoClone = _createBasicFuroAutomatedTimeNoClone(
                false
            );
        uint256 balance = WETH.balanceOf(furoAutomatedTimeNoClone.withdrawTo());
        //setup vm
        vm.warp(
            block.timestamp + furoAutomatedTimeNoClone.withdrawPeriod() + 1
        );
        (, uint256 sharesToWithdraw) = FuroStream(
            furoAutomatedTimeNoClone.furo()
        ).streamBalanceOf(furoAutomatedTimeNoClone.id());
        (, bytes memory execPayload) = furoAutomatedTimeNoClone.checkTask();
        vm.prank(address(ops));

        //exec
        (bool success, ) = address(furoAutomatedTimeNoClone).call(execPayload);

        //assert
        assertEq(success, true);
        assertEq(furoAutomatedTimeNoClone.lastWithdraw(), block.timestamp);
        assertEq(
            WETH.balanceOf(furoAutomatedTimeNoClone.withdrawTo()),
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
        FuroAutomatedTimeNoClone furoAutomatedTimeNoClone = _createBasicFuroAutomatedTimeNoClone(
                false
            );
        (, uint256 sharesToWithdraw) = FuroStream(
            furoAutomatedTimeNoClone.furo()
        ).streamBalanceOf(furoAutomatedTimeNoClone.id());

        //setup vm
        vm.prank(address(ops));
        vm.expectRevert(FuroAutomatedTimeNoClone.ToEarlyToWithdraw.selector);

        //exec
        furoAutomatedTimeNoClone.executeTask(abi.encode(sharesToWithdraw));
    }

    function testExecTask_toBentoBox() public {
        //setup
        FuroAutomatedTimeNoClone furoAutomatedTimeNoClone = _createBasicFuroAutomatedTimeNoClone(
                false
            );
        bytes memory data = abi.encode(
            furoAutomatedTimeNoClone.withdrawTo(),
            furoAutomatedTimeNoClone.withdrawPeriod(),
            true, //set bento to true
            furoAutomatedTimeNoClone.taskData()
        );
        furoAutomatedTimeNoClone.updateTask(data);
        uint256 balance = bentobox.balanceOf(
            IERC20(address(WETH)),
            furoAutomatedTimeNoClone.withdrawTo()
        );
        //setup vm
        vm.warp(
            block.timestamp + furoAutomatedTimeNoClone.withdrawPeriod() + 1
        );
        (, uint256 sharesToWithdraw) = FuroStream(
            furoAutomatedTimeNoClone.furo()
        ).streamBalanceOf(furoAutomatedTimeNoClone.id());
        vm.prank(address(ops));

        //exec
        furoAutomatedTimeNoClone.executeTask(abi.encode(sharesToWithdraw));

        //assert
        assertEq(
            bentobox.balanceOf(
                IERC20(address(WETH)),
                furoAutomatedTimeNoClone.withdrawTo()
            ),
            balance + sharesToWithdraw
        );
    }

    function testExecTask_execTaskDataOnWithdrawTo() public {
        //setup
        FuroAutomatedTimeNoClone furoAutomatedTimeNoClone = _createBasicFuroAutomatedTimeNoClone(
                false
            );
        AutoUnwrap autoUnwrap = new AutoUnwrap(address(99), payable(WETH));
        //setup vm
        vm.warp(
            block.timestamp + furoAutomatedTimeNoClone.withdrawPeriod() + 1
        );
        (, uint256 sharesToWithdraw) = FuroStream(
            furoAutomatedTimeNoClone.furo()
        ).streamBalanceOf(furoAutomatedTimeNoClone.id());
        bytes memory data = abi.encode(
            address(autoUnwrap),
            furoAutomatedTimeNoClone.withdrawPeriod(),
            false,
            abi.encode(
                bentobox.toAmount(
                    IERC20(address(WETH)),
                    sharesToWithdraw,
                    false
                )
            )
        );
        furoAutomatedTimeNoClone.updateTask(data);
        vm.prank(address(ops));

        //exec
        furoAutomatedTimeNoClone.executeTask(abi.encode(sharesToWithdraw));

        //assert
        assertEq(furoAutomatedTimeNoClone.lastWithdraw(), block.timestamp);
        assertEq(
            bentobox.toAmount(IERC20(address(WETH)), sharesToWithdraw, false),
            address(99).balance
        );
    }
}
