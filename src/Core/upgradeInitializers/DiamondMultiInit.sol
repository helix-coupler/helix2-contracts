// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";

contract DiamondMultiInit {
    // This function is provided in the third parameter of the diamondCut() function
    // The diamondCut() function executes this function to execute multiple initializer functions for a single upgrade
    function multiInit(
        address[] calldata _addresses,
        bytes[] calldata _calldata
    ) external {
        require(_addresses.length == _calldata.length, "LENGTH_MISMATCH");
        for (uint i; i < _addresses.length; i++) {
            LibDiamond.initializeDiamondCut(_addresses[i], _calldata[i]);
        }
    }
}
