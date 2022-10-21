// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import "./../base/BaseFuroAutomatedFactory.sol";
import {FuroAutomatedTime} from "./FuroAutomatedTime.sol";

contract FuroAutomatedTimeFactory is BaseFuroAutomatedFactory {
    using ClonesWithImmutableArgs for address;

    /// -----------------------------------------------------------------------
    /// Immutable variables
    /// -----------------------------------------------------------------------
    FuroStream internal immutable furoStream;
    FuroVesting internal immutable furoVesting;

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
        address payable _implementation
    ) BaseFuroAutomatedFactory(_bentoBox, _gelatoOps, _implementation) {
        furoStream = FuroStream(_furoStream);
        furoVesting = FuroVesting(_furoVesting);
    }

    /// -----------------------------------------------------------------------
    /// Functions
    /// -----------------------------------------------------------------------

    ///@notice Contract creation logic
    function _createFuroAutomated(bytes calldata data)
        internal
        override
        returns (BaseFuroAutomated furoAutomated, bytes memory initData)
    {
        (
            uint256 id,
            address token,
            address withdrawTo,
            uint32 withdrawPeriod,
            bool vesting,
            bool toBentoBox,
            bytes memory taskData
        ) = abi.decode(
                data,
                (uint256, address, address, uint32, bool, bool, bytes)
            );

        furoAutomated = FuroAutomatedTime(
            address(implementation).clone(
                abi.encodePacked(
                    address(bentoBox),
                    address(ops),
                    ops.gelato(),
                    vesting ? address(furoVesting) : address(furoStream),
                    msg.sender,
                    token,
                    vesting,
                    id
                )
            )
        );

        if (vesting) {
            furoVesting.safeTransferFrom(
                msg.sender,
                address(furoAutomated),
                id
            );
        } else {
            furoStream.safeTransferFrom(msg.sender, address(furoAutomated), id);
        }

        initData = abi.encode(withdrawTo, withdrawPeriod, toBentoBox, taskData);
    }
}
