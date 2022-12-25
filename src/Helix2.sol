//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

/// @dev : ERC Standards
import "src/ERC721.sol";

/// @dev : Helix2 Structs
import "src/Registry/NameRegistry.sol";
import "src/Registry/BondRegistry.sol";
import "src/Registry/MoleculeRegistry.sol";
import "src/Registry/PolyculeRegistry.sol";

/// @dev : Helix2 Interfaces
import "src/Interface/iHelix2.sol";
import "src/Interface/iName.sol";
import "src/Interface/iBond.sol";
import "src/Interface/iMolecule.sol";
import "src/Interface/iPolycule.sol";
//import "src/interface/iResolver.sol";

/// @dev : Other Interfaces
import "src/Interface/iENS.sol";
import "src/Interface/iERC721.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Registrar
 */
contract HELIX2 is ERC721 {
    /// @dev : Contract metadata
    string public constant name = "Helix2 Link Service";
    string public constant symbol = "HELIX2";

    /// @dev : Events
    event NewRegistry(address[4] newReg);
    event NewSubRegistry(uint256 index, address newReg);
    event NewPrices(uint256[4] newPrices);
    event NewSubPrice(uint256 index, uint256 newPrice);

    /// @dev : Initialise Registers

    iENS public ENS = iENS(ensRegistry);
    iNAME public NAMES = iNAME(helix2Registry[0]);
    iBOND public BONDS = iBOND(helix2Registry[1]);
    iMOLECULE public MOLECULES = iMOLECULE(helix2Registry[2]);
    iPOLYCULE public POLYCULES = iPOLYCULE(helix2Registry[3]);

    /**
     * @dev : sets new base price list
     * @param newPrices : list of base prices
     */
    function setPrices(uint256[4] calldata newPrices) external onlyDev {
        emit NewPrices(newPrices);
        prices = newPrices;
    }

    /**
     * @dev : replace single base price value
     * @param index : index to replace (starts from 0)
     * @param newPrice : new base price for index
     */
    function setSubPrice(uint256 index, uint256 newPrice) external onlyDev {
        emit NewSubPrice(index, newPrice);
        prices[index] = newPrice;
    }

    /**
     * @dev : migrate all Helix2 Registers
     * @param newReg : new Registry array
     */
    function setRegistry(address[4] calldata newReg) external onlyDev {
        emit NewRegistry(newReg);
        helix2Registry = newReg;
    }

    /**
     * @dev : replace one index of Helix2 Register
     * @param index : index to replace (starts from 0)
     * @param newReg : new Register for index
     */
    function setSubRegistry(uint256 index, address newReg) external onlyDev {
        emit NewSubRegistry(index, newReg);
        helix2Registry[index] = newReg;
    }
}
