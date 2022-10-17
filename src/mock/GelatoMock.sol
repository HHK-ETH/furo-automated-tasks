// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import {IOps} from "./../interfaces/IOps.sol";

contract GelatoMock is IOps {
    address payable internal _gelato;
    address internal _feeToken;
    uint256 internal _fee;

    constructor(
        address payable _newGelato,
        address _newFeeToken,
        uint256 _newFee
    ) {
        _gelato = _newGelato;
        _feeToken = _newFeeToken;
        _fee = _newFee;
    }

    function gelato() external view returns (address payable) {
        return _gelato;
    }

    function getFeeDetails() external view returns (uint256, address) {
        return (_fee, _feeToken);
    }

    function createTask(
        address _execAddress,
        bytes4 _execSelector,
        address _resolverAddress,
        bytes calldata _resolverData
    ) external returns (bytes32 task) {}
}
