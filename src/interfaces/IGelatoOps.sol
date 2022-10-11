// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

interface IGelatoOps {
    function fee() external returns (uint256);

    function feeToken() external returns (address);

    function createTask(
        address _execAddress,
        bytes4 _execSelector,
        address _resolverAddress,
        bytes calldata _resolverData
    ) external returns (bytes32 task);
}
