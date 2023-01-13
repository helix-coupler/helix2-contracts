// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "./libraries/LibDiamond.sol";
import {iDiamondCut} from "./interfaces/iDiamondCut.sol";

/// @dev : used in diamond constructor
struct Initialiser {
    address Dev;
    address init;
    bytes initCalldata;
}

/**
 * @dev EIP-2535 Diamond
 */
contract Diamond {
    constructor(
        iDiamondCut.FacetCut[] memory _diamondCut,
        Initialiser memory _args
    ) payable {
        LibDiamond.setDev(_args.Dev);

        // Add the diamondCut external function from the diamondCutFacet
        LibDiamond.diamondCut(_diamondCut, _args.init, _args.initCalldata);
    }

    /// @dev : Find facet for function that is called and execute
    /// the function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds
            .facetAddressAndSelectorPosition[msg.sig]
            .facetAddress;
        require(facet != address(0), "FUNCTION_NOT_FOUND");
        // execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}
