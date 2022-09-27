// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {FuroAutomatedTimeWithdraw} from "./../FuroAutomatedTimeWithdraw.sol";
import {ERC20Mock} from "./../mock/ERC20Mock.sol";
import {BentoBoxV1, IERC20} from "./../flat/BentoBoxFlat.sol";
import {FuroStream} from "./../base/FuroStream.sol";
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

    function setUp() public {
        //Deploy contracts needed
        WETH = new ERC20Mock("WETH", "WETH", 18);
        bentobox = new BentoBoxV1(IERC20(address(WETH)));
        furoStream = new FuroStream(address(bentobox), address(WETH));
        furoStreamRouter = new FuroStreamRouter(
            address(bentobox),
            address(furoStream),
            address(WETH)
        );
        furoVesting = new FuroVesting(address(bentobox), address(WETH));
        furoVestingRouter = new FuroVestingRouter(
            address(bentobox),
            address(furoVesting),
            address(WETH)
        );
        furoAutomatedTimeWithdraw = new FuroAutomatedTimeWithdraw(
            address(bentobox),
            address(furoStream),
            address(furoVesting)
        );

        //Mint ETH & WETH tokens
        vm.deal(address(this), 100 * 1e18);
        address(WETH).call{value: 20 * 1e18}("");

        //Create a test stream and approve it
        WETH.approve(address(furoStreamRouter), 10 * 1e18);
        furoStreamRouter.createStream(
            address(this),
            address(WETH),
            uint64(block.timestamp),
            uint64(block.timestamp + 3600),
            10 * 1e18,
            false,
            0
        );
        furoStream.approve(address(furoAutomatedTimeWithdraw), 0);

        //Create a test vesting and approve it
        WETH.approve(address(furoVestingRouter), 10 * 1e18);
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
        furoVesting.approve(address(furoAutomatedTimeWithdraw), 0);
    }
}
