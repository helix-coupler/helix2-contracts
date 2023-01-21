// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import "../interfaces/iFacets.sol";

/**
 * @dev Helix2 Core View Facet
 */
contract WriteFacet {
    function setLives(uint256[4] calldata _newLives) external {
        LibDiamond.setLives(_newLives);
    }

    function setLife(uint256 index, uint256 _newLife) external {
        LibDiamond.setLife(index, _newLife);
    }

    function setRegisteries(address[4] calldata newReg) external {
        LibDiamond.setRegisteries(newReg);
    }

    function setRegistry(uint256 index, address newReg) external {
        LibDiamond.setRegistry(index, newReg);
    }

    function setRegistrars(address[4] calldata newReg) external {
        LibDiamond.setRegistrars(newReg);
    }

    function setRegistrar(uint256 index, address newReg) external {
        LibDiamond.setRegistrar(index, newReg);
    }

    function setENSRegistry(address newReg) external {
        LibDiamond.setENSRegistry(newReg);
    }
}
