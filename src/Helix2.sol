//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/ERC721.sol";
import "src/Bond.sol";
import "src/Molecule.sol";
import "src/Polycule.sol";

interface iResolver {
    function contenthash(bytes32 bond) external view returns(bytes memory);
    function addr(bytes32 bond) external view returns(address payable);
    function addr2(bytes32 bond, uint256 coinType) external view returns(bytes memory);
    function pubkey(bytes32 bond) external view returns(bytes32 x, bytes32 y);
    function text(bytes32 bond, string calldata key) external view returns(string memory);
}

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Registrar
 */
contract HELIX2 is ERC721 {

    ENS = iENS(ensRegistry);

    modifier onlyDev() {
        require(msg.sender == Dev, "ONLY_DEV");
        _;
    }

    /**
     * @dev : transfer contract ownership to new Dev
     * @param newDev : new Dev
     */
    function changeDev(address newDev) external onlyDev {
        emit NewDev(Dev, newDev);
        Dev = newDev;
    }

    /**
     * @dev : migrate ENS Registry
     * @param newReg : new Registry
     */
    function setEnsRegistry(address newReg) external onlyDev {
        emit NewENSRegistry(newReg);
        ens = newReg;
    }

    /**
     * @dev : setInterface
     * @param sig : signature
     * @param value : boolean
     */
    function setInterface(bytes4 sig, bool value) external payable onlyDev {
        require(sig != 0xffffffff, "INVALID_INTERFACE_SELECTOR");
        supportsInterface[sig] = value;
    }
}
