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
}
