// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

interface IOps {
    function gelato() external view returns (address payable);

    function getFeeDetails() external view returns (uint256, address);

    function createTask(
        address _execAddress,
        bytes4 _execSelector,
        address _resolverAddress,
        bytes calldata _resolverData
    ) external returns (bytes32 task);

    function createTaskNoPrepayment(
        address _execAddress,
        bytes4 _execSelector,
        address _resolverAddress,
        bytes calldata _resolverData,
        address _feeToken
    ) external returns (bytes32 task);
}
