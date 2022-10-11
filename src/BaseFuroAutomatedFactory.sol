// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import "./interfaces/IBentoBoxMinimal.sol";
import "./interfaces/IGelatoOps.sol";
import "./furo/FuroStream.sol";
import "./furo/FuroVesting.sol";
import {BaseFuroAutomated} from "./BaseFuroAutomated.sol";

abstract contract BaseFuroAutomatedFactory {
    error NotOwner();

    /// -----------------------------------------------------------------------
    /// Immutable variables
    /// -----------------------------------------------------------------------

    IBentoBoxMinimal public immutable bentoBox;
    FuroStream internal immutable furoStream;
    FuroVesting internal immutable furoVesting;
    IGelatoOps internal immutable gelatoOps;

    /// -----------------------------------------------------------------------
    /// mutable variables
    /// -----------------------------------------------------------------------

    address public owner;
    address public implementation;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    ///@param _bentoBox Address of the BentoBox contract
    ///@param _furoStream Address of the furoStream contract
    ///@param _furoVesting Address of the furoVesting contract
    constructor(
        address _bentoBox,
        address _furoStream,
        address _furoVesting,
        address _gelatoOps
    ) {
        bentoBox = IBentoBoxMinimal(_bentoBox);
        furoStream = FuroStream(_furoStream);
        furoVesting = FuroVesting(_furoVesting);
        gelatoOps = IGelatoOps(_gelatoOps);
    }

    /// -----------------------------------------------------------------------
    /// Functions and modifiers
    /// -----------------------------------------------------------------------

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    ///@notice Set the implementation to clone
    function setImplementation(address newImplementation) external onlyOwner {
        implementation = newImplementation;
    }

    ///@notice Set the owner of the factory
    function setOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    ///@notice Deploy a new automated furoAutomated contract clone
    function createFuroAutomated(bytes calldata data) external {
        BaseFuroAutomated furoAutomated = _createFuroAutomated(data);

        gelatoOps.createTask(
            address(furoAutomated),
            furoAutomated.executeTask.selector,
            address(furoAutomated),
            abi.encodeWithSelector(furoAutomated.checker.selector)
        );
    }

    ///@notice Contract creation logic
    function _createFuroAutomated(bytes calldata data)
        internal
        virtual
        returns (BaseFuroAutomated);
}
