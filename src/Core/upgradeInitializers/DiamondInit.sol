// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {iDiamondLoupe} from "../interfaces/iDiamondLoupe.sol";
import {iDiamondCut} from "../interfaces/iDiamondCut.sol";
import {iERC173} from "../../Interface/iERC173.sol";
import {iERC165} from "../../Interface/iERC165.sol";
import {iFacets} from "../interfaces/iFacets.sol";

/**
 * @dev EIP-2535 Diamond Init
 */
contract DiamondInit {
    /// @dev : Set state variables
    function init() external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(iERC165).interfaceId] = true;
        ds.supportedInterfaces[type(iDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(iDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(iERC173).interfaceId] = true;
        ds.supportedInterfaces[type(iFacets).interfaceId] = true;
        /// @dev : set custom variables here
        // Helix2 Core Variables
        ds.illegalBlocks = [".", "-", "#", ""];
        ds.sizes = [[3, 32], [3, 32], [3, 32], [3, 32]];
        ds.lifespans = [1, 1, 1, 1];
        ds.roothash = [
            keccak256(abi.encodePacked(bytes32(0), keccak256("."))), /// Name Roothash
            keccak256(abi.encodePacked(bytes32(0), keccak256("-"))), /// Bond Roothash
            keccak256(abi.encodePacked(bytes32(0), keccak256("-"))), /// Molecule Roothash
            keccak256(abi.encodePacked(bytes32(0), keccak256("-"))) /// Polycule Roothash
        ];
        ds.ensRegistry = 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;
        ds.helix2Registry = [
            address(0), /// Name Registry
            address(0), /// Bond Registry
            address(0), /// Molecule Registry
            address(0) /// Polycule Registry
        ];
        ds.helix2Registrar = [
            address(0), /// Name Registry
            address(0), /// Bond Registry
            address(0), /// Molecule Registry
            address(0) /// Polycule Registry
        ];
        ds.active = true;
    }
}
