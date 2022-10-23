// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import "./FuroAutomatedSetUp.sol";
import {FuroAutomatedAmount, BaseFuroAutomated} from "./../implementations/FuroAutomatedAmount.sol";
import {FuroAutomatedAmountFactory} from "./../implementations/FuroAutomatedAmountFactory.sol";
import {AutoUnwrap} from "./../mock/AutoUnwrap.sol";

contract TestFuroAutomatedAmount is FuroAutomatedSetUp {
    FuroAutomatedAmount implementation;
    FuroAutomatedAmountFactory factory;

    function _setUp() internal override {
        //deploy implementation and factory
        implementation = new FuroAutomatedAmount();
        factory = new FuroAutomatedAmountFactory(
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

    ///@notice Helper function to easily create Furo Automated Amount clone
    function _createBasicFuroAutomatedAmount(bool vesting)
        internal
        returns (FuroAutomatedAmount furoAutomatedAmount)
    {
        bytes memory data = abi.encode(
            vesting ? uint256(1) : uint256(1000),
            address(WETH),
            address(this),
            1e18,
            vesting,
            false,
            bytes("")
        );
        furoAutomatedAmount = FuroAutomatedAmount(
            payable(factory.createFuroAutomated(data))
        );
        furoAutomatedAmount.fund{value: 1 ether}();
    }

    function testCreateAutomatedAmount_withStream() public {
        //exec
        FuroAutomatedAmount furoAutomatedAmount = _createBasicFuroAutomatedAmount(
                false
            );

        //assert
        assertEq(furoAutomatedAmount.id(), uint256(1000));
        assertEq(furoAutomatedAmount.vesting(), false);
        assertEq(furoAutomatedAmount.token(), address(WETH));
        assertEq(furoAutomatedAmount.owner(), address(this));
        assertEq(furoAutomatedAmount.furo(), address(furoStream));
        assertEq(address(furoAutomatedAmount.ops()), address(ops));
        assertEq(furoAutomatedAmount.withdrawTo(), address(this));
        assertEq(furoAutomatedAmount.minAmount(), 1e18);
        assertEq(furoAutomatedAmount.toBentoBox(), false);
        assertEq(furoAutomatedAmount.taskData(), bytes(""));
    }

    function testCreateAutomatedAmount_withVesting() public {
        //exec
        FuroAutomatedAmount furoAutomatedAmount = _createBasicFuroAutomatedAmount(
                true
            );

        //assert
        assertEq(furoAutomatedAmount.id(), uint256(1));
        assertEq(furoAutomatedAmount.vesting(), true);
        assertEq(furoAutomatedAmount.token(), address(WETH));
        assertEq(furoAutomatedAmount.owner(), address(this));
        assertEq(furoAutomatedAmount.furo(), address(furoVesting));
        assertEq(address(furoAutomatedAmount.ops()), address(ops));
        assertEq(furoAutomatedAmount.withdrawTo(), address(this));
        assertEq(furoAutomatedAmount.minAmount(), 1e18);
        assertEq(furoAutomatedAmount.toBentoBox(), false);
        assertEq(furoAutomatedAmount.taskData(), bytes(""));
    }

    function testUpdateAutomatedAmount() public {
        //setup
        FuroAutomatedAmount furoAutomatedAmount = _createBasicFuroAutomatedAmount(
                false
            );
        address withdrawTo = address(100);
        uint256 minAmount = 2 * 1e18;
        bool toBentoBox = true;
        bytes memory taskData = "";
        bytes memory data = abi.encode(
            withdrawTo,
            minAmount,
            toBentoBox,
            taskData
        );

        //exec
        furoAutomatedAmount.updateTask(data);

        //assert
        assertEq(furoAutomatedAmount.withdrawTo(), withdrawTo);
        assertEq(furoAutomatedAmount.minAmount(), minAmount);
        assertEq(furoAutomatedAmount.toBentoBox(), toBentoBox);
        assertEq(furoAutomatedAmount.taskData(), taskData);
    }

    function testCannotUpdateAutomatedAmount_ifNotOwner() public {
        //setup
        FuroAutomatedAmount furoAutomatedAmount = _createBasicFuroAutomatedAmount(
                false
            );
        address withdrawTo = address(100);
        uint256 minAmount = 9999;
        bool toBentoBox = true;
        bytes memory taskData = "";
        bytes memory data = abi.encode(
            withdrawTo,
            minAmount,
            toBentoBox,
            taskData
        );
        //setup vm
        vm.prank(address(2222));
        vm.expectRevert(BaseFuroAutomated.NotOwner.selector);

        //exec
        furoAutomatedAmount.updateTask(data);
    }

    function testCancelAutomatedAmount() public {
        //setup
        FuroAutomatedAmount furoAutomatedAmount = _createBasicFuroAutomatedAmount(
                false
            );
        uint256 balance = address(this).balance;
        uint256 cloneBalance = address(furoAutomatedAmount).balance;

        //exec
        furoAutomatedAmount.cancelTask(abi.encode(address(this)));

        //assert
        assertEq(furoStream.ownerOf(furoAutomatedAmount.id()), address(this));
        assertEq(address(this).balance, balance + cloneBalance);
        assertEq(address(furoAutomatedAmount).balance, 0);
    }

    function testCannotCancelAutomatedAmount_ifNotOwner() public {
        //setup
        FuroAutomatedAmount furoAutomatedAmount = _createBasicFuroAutomatedAmount(
                false
            );
        //setup vm
        vm.prank(address(2222));
        vm.expectRevert(BaseFuroAutomated.NotOwner.selector);

        //exec
        furoAutomatedAmount.cancelTask(abi.encode(address(this)));
    }

    function testCannotInit_ifAlreadyInit() public {
        //setup
        FuroAutomatedAmount furoAutomatedAmount = _createBasicFuroAutomatedAmount(
                false
            );
        //setup vm
        vm.expectRevert(BaseFuroAutomated.AlreadyInit.selector);

        //exec
        furoAutomatedAmount.init("");
    }

    function testCheckTask_canExec() public {
        //setup
        FuroAutomatedAmount furoAutomatedAmount = _createBasicFuroAutomatedAmount(
                false
            );
        //setup vm
        vm.warp(block.timestamp + 600);

        //exec
        (bool canExec, bytes memory execPayload) = furoAutomatedAmount
            .checkTask();

        //assert
        assertEq(canExec, true);
        assertEq(
            execPayload,
            abi.encodeWithSelector(BaseFuroAutomated.executeTask.selector, "")
        );
    }

    function testCheckTask_canNotExec() public {
        //setup
        FuroAutomatedAmount furoAutomatedAmount = _createBasicFuroAutomatedAmount(
                false
            );

        //exec
        (bool canExec, bytes memory execPayload) = furoAutomatedAmount
            .checkTask();

        //assert
        assertEq(canExec, false);
        assertEq(execPayload, bytes(""));
    }

    function testExecTask() public {
        //setup
        FuroAutomatedAmount furoAutomatedAmount = _createBasicFuroAutomatedAmount(
                false
            );
        uint256 balance = WETH.balanceOf(furoAutomatedAmount.withdrawTo());
        //setup vm
        vm.warp(block.timestamp + 600);
        (, uint256 sharesToWithdraw) = FuroStream(furoAutomatedAmount.furo())
            .streamBalanceOf(furoAutomatedAmount.id());
        (, bytes memory execPayload) = furoAutomatedAmount.checkTask();
        vm.prank(address(ops));

        //exec
        (bool success, ) = address(furoAutomatedAmount).call(execPayload);

        //assert
        assertEq(success, true);
        assertEq(
            WETH.balanceOf(furoAutomatedAmount.withdrawTo()),
            balance +
                bentobox.toAmount(
                    IERC20(address(WETH)),
                    sharesToWithdraw,
                    false
                )
        );
    }

    function testCannotExecTask_ifNotEnoughToWithdraw() public {
        //setup
        FuroAutomatedAmount furoAutomatedAmount = _createBasicFuroAutomatedAmount(
                false
            );

        //setup vm
        vm.prank(address(ops));
        vm.expectRevert(FuroAutomatedAmount.NotEnoughToWithdraw.selector);

        //exec
        furoAutomatedAmount.executeTask("");
    }

    function testExecTask_toBentoBox() public {
        //setup
        FuroAutomatedAmount furoAutomatedAmount = _createBasicFuroAutomatedAmount(
                false
            );
        bytes memory data = abi.encode(
            furoAutomatedAmount.withdrawTo(),
            furoAutomatedAmount.minAmount(),
            true, //set bento to true
            furoAutomatedAmount.taskData()
        );
        furoAutomatedAmount.updateTask(data);
        uint256 balance = bentobox.balanceOf(
            IERC20(address(WETH)),
            furoAutomatedAmount.withdrawTo()
        );
        //setup vm
        vm.warp(block.timestamp + 600);
        (, uint256 sharesToWithdraw) = FuroStream(furoAutomatedAmount.furo())
            .streamBalanceOf(furoAutomatedAmount.id());
        vm.prank(address(ops));

        //exec
        furoAutomatedAmount.executeTask("");

        //assert
        assertEq(
            bentobox.balanceOf(
                IERC20(address(WETH)),
                furoAutomatedAmount.withdrawTo()
            ),
            balance + sharesToWithdraw
        );
    }

    function testExecTask_execTaskDataOnWithdrawTo() public {
        //setup
        FuroAutomatedAmount furoAutomatedAmount = _createBasicFuroAutomatedAmount(
                false
            );
        AutoUnwrap autoUnwrap = new AutoUnwrap(address(99), payable(WETH));
        //setup vm
        vm.warp(block.timestamp + 600);
        (, uint256 sharesToWithdraw) = FuroStream(furoAutomatedAmount.furo())
            .streamBalanceOf(furoAutomatedAmount.id());
        bytes memory data = abi.encode(
            address(autoUnwrap),
            furoAutomatedAmount.minAmount(),
            false,
            abi.encode(
                bentobox.toAmount(
                    IERC20(address(WETH)),
                    sharesToWithdraw,
                    false
                )
            )
        );
        furoAutomatedAmount.updateTask(data);
        vm.prank(address(ops));

        //exec
        furoAutomatedAmount.executeTask("");

        //assert
        assertEq(
            bentobox.toAmount(IERC20(address(WETH)), sharesToWithdraw, false),
            address(99).balance
        );
    }
}
