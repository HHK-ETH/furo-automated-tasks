// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import {IBentoBoxMinimal} from "./../interfaces/IBentoBoxMinimal.sol";
import {IOps} from "./../interfaces/IOps.sol";
import {FuroStream} from "./../furo/FuroStream.sol";
import {FuroVesting} from "./../furo/FuroVesting.sol";
import {FuroAutomatedTimeNoClone} from "./FuroAutomatedTimeNoClone.sol";

contract FuroAutomatedTimeFactoryNoClone {
    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event CreateFuroAutomated(
        FuroAutomatedTimeNoClone indexed clone,
        uint256 amount
    );

    /// -----------------------------------------------------------------------
    /// Immutable variables
    /// -----------------------------------------------------------------------

    IBentoBoxMinimal internal immutable bentoBox;
    IOps public immutable ops;
    FuroStream public immutable furoStream;
    FuroVesting public immutable furoVesting;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    ///@param _bentoBox Address of the BentoBox contract
    ///@param _ops Address of the gelato OPS to create new tasks
    constructor(
        address _bentoBox,
        address _ops,
        address _furoStream,
        address _furoVesting
    ) {
        bentoBox = IBentoBoxMinimal(_bentoBox);
        ops = IOps(_ops);
        furoStream = FuroStream(_furoStream);
        furoVesting = FuroVesting(_furoVesting);
    }

    /// -----------------------------------------------------------------------
    /// Functions
    /// -----------------------------------------------------------------------

    ///@notice Deploy a new automated furoAutomated contract clone
    ///@return furoAutomated Address of the contract created
    function createFuroAutomated(
        bool _vesting,
        uint256 _id,
        address _withdrawTo,
        uint32 _withdrawPeriod,
        bool _toBentoBox,
        bytes memory _taskData
    ) external payable returns (FuroAutomatedTimeNoClone furoAutomated) {
        furoAutomated = new FuroAutomatedTimeNoClone(
            address(bentoBox),
            address(ops),
            _vesting ? address(furoVesting) : address(furoStream),
            msg.sender,
            _vesting,
            _id,
            _withdrawTo,
            _withdrawPeriod,
            _toBentoBox,
            _taskData
        );

        if (_vesting) {
            furoVesting.safeTransferFrom(
                msg.sender,
                address(furoAutomated),
                _id
            );
        } else {
            furoStream.safeTransferFrom(
                msg.sender,
                address(furoAutomated),
                _id
            );
        }

        if (msg.value > 0) {
            furoAutomated.fund{value: msg.value}();
        }

        emit CreateFuroAutomated(furoAutomated, msg.value);
    }
}
