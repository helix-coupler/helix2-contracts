// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import "../interfaces/iHelix2.sol";

/**
 * @dev Helix2 Core View Facet
 */
contract ViewFacet {
    function getIllegalBlocks() public view returns (string[4] memory) {
        return LibDiamond.illegalBlocks();
    }

    function getSizes() public view returns (uint256[2][4] memory) {
        return LibDiamond.sizes();
    }

    function getLifespans() public view returns (uint256[4] memory) {
        return LibDiamond.lifespans();
    }

    function getRegistry() public view returns (address[4] memory) {
        return LibDiamond.registries();
    }

    function getRegistrar() public view returns (address[4] memory) {
        return LibDiamond.registrars();
    }

    function getRoothash() public view returns (bytes32[4] memory) {
        return LibDiamond.roothash();
    }

    function getENSRegistry() public view returns (address) {
        return LibDiamond.ensRegistry();
    }
}
