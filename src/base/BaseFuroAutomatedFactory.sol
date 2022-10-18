// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import {IBentoBoxMinimal} from "./../interfaces/IBentoBoxMinimal.sol";
import {IOps} from "./../interfaces/IOps.sol";
import {FuroStream} from "./../furo/FuroStream.sol";
import {FuroVesting} from "./../furo/FuroVesting.sol";
import {BaseFuroAutomated} from "./BaseFuroAutomated.sol";
import {ClonesWithImmutableArgs} from "./../clonesWithImmutableArgs/ClonesWithImmutableArgs.sol";

abstract contract BaseFuroAutomatedFactory {
    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event CreateFuroAutomated(BaseFuroAutomated indexed clone, bytes data);

    /// -----------------------------------------------------------------------
    /// Immutable variables
    /// -----------------------------------------------------------------------

    IBentoBoxMinimal internal immutable bentoBox;
    IOps public immutable ops;
    BaseFuroAutomated public immutable implementation;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    ///@param _bentoBox Address of the BentoBox contract
    ///@param _ops Address of the gelato OPS to create new tasks
    ///@param _implementation Address of the implementation to clone from
    constructor(
        address _bentoBox,
        address _ops,
        address payable _implementation
    ) {
        bentoBox = IBentoBoxMinimal(_bentoBox);
        ops = IOps(_ops);
        implementation = BaseFuroAutomated(_implementation);
    }

    /// -----------------------------------------------------------------------
    /// Functions
    /// -----------------------------------------------------------------------

    ///@notice Deploy a new automated furoAutomated contract clone
    function createFuroAutomated(bytes calldata data)
        external
        payable
        returns (BaseFuroAutomated furoAutomated)
    {
        bytes memory initData;
        (furoAutomated, initData) = _createFuroAutomated(data);

        furoAutomated.init(initData);

        if (msg.value > 0) {
            furoAutomated.fund{value: msg.value}();
        }

        emit CreateFuroAutomated(furoAutomated, data);
    }

    ///@notice Contract creation logic
    function _createFuroAutomated(bytes calldata data)
        internal
        virtual
        returns (BaseFuroAutomated furoAutomated, bytes memory initData);
}
