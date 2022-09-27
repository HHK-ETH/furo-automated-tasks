// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {FuroAutomatedTimeWithdraw} from "./../FuroAutomatedTimeWithdraw.sol";
import {ERC20Mock} from "./../mock/ERC20Mock.sol";
import {BentoBoxV1, IERC20} from "./../flat/BentoBoxFlat.sol";
import {FuroStream} from "./../base/FuroStream.sol";
import {FuroStreamRouter} from "./../base/FuroStreamRouter.sol";
import {FuroVesting} from "./../base/FuroVesting.sol";
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
    }
}
