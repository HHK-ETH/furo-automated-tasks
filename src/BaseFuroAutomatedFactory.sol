// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import "./interfaces/IBentoBoxMinimal.sol";
import "./interfaces/IGelatoOps.sol";
import "./furo/FuroStream.sol";
import "./furo/FuroVesting.sol";
import {BaseFuroAutomated} from "./BaseFuroAutomated.sol";
import {ClonesWithImmutableArgs} from "./clonesWithImmutableArgs/ClonesWithImmutableArgs.sol";

abstract contract BaseFuroAutomatedFactory {
    using ClonesWithImmutableArgs for address;
    /// -----------------------------------------------------------------------
    /// Immutable variables
    /// -----------------------------------------------------------------------

    IBentoBoxMinimal internal immutable bentoBox;
    FuroStream internal immutable furoStream;
    FuroVesting internal immutable furoVesting;
    IGelatoOps internal immutable gelatoOps;
    BaseFuroAutomated public immutable implementation;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    ///@param _bentoBox Address of the BentoBox contract
    ///@param _furoStream Address of the furoStream contract
    ///@param _furoVesting Address of the furoVesting contract
    ///@param _gelatoOps Address of the gelato OPS to create new tasks
    ///@param _implementation Address of the implementation to clone from
    constructor(
        address _bentoBox,
        address _furoStream,
        address _furoVesting,
        address _gelatoOps,
        address _implementation
    ) {
        bentoBox = IBentoBoxMinimal(_bentoBox);
        furoStream = FuroStream(_furoStream);
        furoVesting = FuroVesting(_furoVesting);
        gelatoOps = IGelatoOps(_gelatoOps);
        implementation = BaseFuroAutomated(_implementation);
    }

    /// -----------------------------------------------------------------------
    /// Functions
    /// -----------------------------------------------------------------------

    ///@notice Deploy a new automated furoAutomated contract clone
    function createFuroAutomated(bytes calldata data)
        external
        returns (BaseFuroAutomated furoAutomated)
    {
        furoAutomated = _createFuroAutomated(data);

        gelatoOps.createTask(
            address(furoAutomated),
            furoAutomated.executeTask.selector,
            address(furoAutomated),
            abi.encodeWithSelector(furoAutomated.checkTask.selector)
        );
    }

    ///@notice Contract creation logic
    function _createFuroAutomated(bytes calldata data)
        internal
        virtual
        returns (BaseFuroAutomated furoAutomated);
}
