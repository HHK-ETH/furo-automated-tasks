// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import {ERC20Mock} from "./ERC20Mock.sol";
import {ITasker} from "./../interfaces/ITasker.sol";

contract AutoUnwrap is ITasker {
    address immutable owner;
    ERC20Mock immutable WETH;

    constructor(address _owner, address payable _WETH) {
        owner = _owner;
        WETH = ERC20Mock(_WETH);
    }

    function onTaskReceived(bytes calldata data) public {
        uint256 wad = abi.decode(data, (uint256));
        WETH.withdraw(wad);
        payable(owner).call{value: wad}("");
    }

    receive() external payable {}
}
