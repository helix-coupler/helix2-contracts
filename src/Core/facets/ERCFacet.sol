// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {iERC173} from "../../Interface/iERC173.sol";
import {iERC165} from "../../Interface/iERC165.sol";

/**
 * @dev ERC-165, ERC-173 Facet
 */
contract ERCFacet is iERC173, iERC165 {
    /// @dev ERC-173
    function transferOwnership(address _newOwner) external override {
        LibDiamond.onlyDev();
        LibDiamond.setDev(_newOwner);
    }

    function owner() external view override returns (address) {
        return LibDiamond.Dev();
    }

    /// @dev ERC-165
    function supportsInterface(
        bytes4 sig
    ) external view override returns (bool) {
        return LibDiamond.checkInterface(sig);
    }

    function setInterface(bytes4 sig, bool value) external {
        require(sig != 0xffffffff, "INVALID_INTERFACE_SELECTOR");
        LibDiamond._setInterface(sig, value);
    }
}
