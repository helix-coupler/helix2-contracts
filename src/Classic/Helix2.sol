//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

/// @dev : ERC Compatible Base
import "src/Classic/Base.sol";
import "src/Interface/iHelix2.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @notice GitHub: https://github.com/helix-coupler/helix2-contracts
 * @notice README: https://github.com/helix-coupler/resources
 * @dev testnet v0.0.1
 * @title Helix2 Registrar
 */
contract HELIX2 is Base {
    /// @dev : Contract metadata
    string public constant name = "Helix2 Link Service";
    string public constant symbol = "HELIX2";

    /// @dev : Events
    event NewENSRegistry(address newReg);
    event NewRegisteries(address[4] newReg);
    event NewRegistry(uint256 index, address newReg);
    event NewRegistrars(address[4] newReg);
    event NewRegistrar(uint256 index, address newReg);
    event NewLives(uint256[4] newLives);
    event NewLife(uint256 index, uint256 newLife);

    /**
     * @dev sets new list of lifespans
     * @param newLives : list of new lifespans
     */
    function setLives(uint256[4] calldata newLives) external onlyDev {
        emit NewLives(newLives);
        lifespans = newLives;
    }

    /**
     * @dev replace single lifespan value
     * @param index : index to replace (starts from 0)
     * @param newLife : new lifespan for index
     */
    function setLife(uint256 index, uint256 newLife) external onlyDev {
        emit NewLife(index, newLife);
        lifespans[index] = newLife;
    }

    /**
     * @dev migrate all Helix2 Registeries
     * @param newReg : new Registry array
     */
    function setRegisteries(address[4] calldata newReg) external onlyDev {
        emit NewRegisteries(newReg);
        helix2Registry = newReg;
    }

    /**
     * @dev replace one index of Helix2 Register
     * @param index : index to replace (starts from 0)
     * @param newReg : new Register for index
     */
    function setRegistry(uint256 index, address newReg) external onlyDev {
        emit NewRegistry(index, newReg);
        helix2Registry[index] = newReg;
    }

    /**
     * @dev migrate all Helix2 Registrars
     * @param newReg : new Registrar array
     */
    function setRegistrars(address[4] calldata newReg) external onlyDev {
        emit NewRegistrars(newReg);
        helix2Registrar = newReg;
    }

    /**
     * @dev replace one index of Helix2 Registrar
     * @param index : index to replace (starts from 0)
     * @param newReg : new Registrar for index
     */
    function setRegistrar(uint256 index, address newReg) external onlyDev {
        emit NewRegistrar(index, newReg);
        helix2Registrar[index] = newReg;
    }

    /**
     * @dev sets ENS Registry if it migrates
     * @param newReg : new Register for index
     */
    function setENSRegistry(address newReg) external onlyDev {
        emit NewENSRegistry(newReg);
        ensRegistry = newReg;
    }
}
