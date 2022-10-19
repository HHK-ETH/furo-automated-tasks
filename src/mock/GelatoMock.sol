// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import {IOps} from "./../interfaces/IOps.sol";

contract GelatoMock is IOps {
    address payable internal gelatoAddr;
    address internal feeToken;
    uint256 internal fee;

    constructor(
        address payable _gelato,
        address _feeToken,
        uint256 _fee
    ) {
        gelatoAddr = _gelato;
        feeToken = _feeToken;
        fee = _fee;
    }

    function gelato() external view returns (address payable) {
        return gelatoAddr;
    }

    function getFeeDetails() external view returns (uint256, address) {
        return (fee, feeToken);
    }

    function createTask(
        address _execAddress,
        bytes4 _execSelector,
        address _resolverAddress,
        bytes calldata _resolverData
    ) external returns (bytes32 task) {
        return "random";
    }

    function createTaskNoPrepayment(
        address _execAddress,
        bytes4 _execSelector,
        address _resolverAddress,
        bytes calldata _resolverData,
        address _feeToken
    ) external returns (bytes32 task) {
        return "random";
    }

    function cancelTask(bytes32 _taskId) external {
        return;
    }
}
