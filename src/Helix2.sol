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
    /// @dev : Events
    event NewRegistry(address[4] newReg);
    event NewSubRegistry(uint256 index, address newReg);

    /// @dev : Initialise Registers
    
    iENS public ENS = iENS(ensRegistry);
    iNAME public NAMES = iNAME(helix2Registry[0]);
    iBOND public BONDS = iBOND(helix2Registry[1]);
    iMOLECULE public MOLECULES = iMOLECULE(helix2Registry[2]);
    iPOLYCULE public POLYCULES = iPOLYCULE(helix2Registry[3]);

    /**
     * @dev : transfer contract ownership to new Dev
     * @param newDev : new Dev
     */
    function changeDev(address newDev) external onlyDev {
        emit NewDev(Dev, newDev);
        Dev = newDev;
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