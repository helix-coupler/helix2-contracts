//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

/// @dev : ERC Compatible Base
import "src/Base.sol";
import "src/Interface/iHelix2.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Registrar
 */
contract HELIX2 is Base {
    /// @dev : Contract metadata
    string public constant name = "Helix2 Link Service";
    string public constant symbol = "HELIX2";

    /// @dev : Events
    event NewRegisteries(address[4] newReg);
    event NewRegistry(uint256 index, address newReg);
    event NewRegistrars(address[4] newReg);
    event NewRegistrar(uint256 index, address newReg);
    event NewPrices(uint256[4] newPrices);
    event NewPrice(uint256 index, uint256 newPrice);
    event NewLives(uint256[4] newLives);
    event NewLife(uint256 index, uint256 newLife);

    /**
     * @dev : sets new list of lifespans
     * @param newLives : list of new lifespans
     */
    function setLives(uint256[4] calldata newLives) external onlyDev {
        emit NewLives(newLives);
        lifespans = newLives;
    }

    /**
     * @dev : replace single lifespan value
     * @param index : index to replace (starts from 0)
     * @param newLife : new lifespan for index
     */
    function setLife(uint256 index, uint256 newLife) external onlyDev {
        emit NewLife(index, newLife);
        lifespans[index] = newLife;
    }

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
    function setPrice(uint256 index, uint256 newPrice) external onlyDev {
        emit NewPrice(index, newPrice);
        prices[index] = newPrice;
    }

    /**
     * @dev : migrate all Helix2 Registeries
     * @param newReg : new Registry array
     */
    function setRegisteries(address[4] calldata newReg) external onlyDev {
        emit NewRegisteries(newReg);
        helix2Registry = newReg;
    }

    /**
     * @dev : replace one index of Helix2 Register
     * @param index : index to replace (starts from 0)
     * @param newReg : new Register for index
     */
    function setRegistry(uint256 index, address newReg) external onlyDev {
        emit NewRegistry(index, newReg);
        helix2Registry[index] = newReg;
    }

    /**
     * @dev : migrate all Helix2 Registrars
     * @param newReg : new Registrar array
     */
    function setRegistrars(address[4] calldata newReg) external onlyDev {
        emit NewRegistrars(newReg);
        helix2Registrar = newReg;
    }

    /**
     * @dev : replace one index of Helix2 Registrar
     * @param index : index to replace (starts from 0)
     * @param newReg : new Registrar for index
     */
    function setRegistrar(uint256 index, address newReg) external onlyDev {
        emit NewRegistrar(index, newReg);
        helix2Registrar[index] = newReg;
    }
}
