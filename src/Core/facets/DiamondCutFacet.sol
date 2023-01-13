// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {iDiamondCut} from "../interfaces/iDiamondCut.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";

/**
 * @dev EIP-2535 Diamond Cut Facet
 */
contract DiamondCutFacet is iDiamondCut {
    /// @notice add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut contains the facet addresses and function selectors
    /// @param _init address of the contract or facet to execute _calldata
    /// @param _calldata function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {
        LibDiamond.onlyDev();
        LibDiamond.diamondCut(_diamondCut, _init, _calldata);
    }
}
