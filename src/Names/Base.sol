// SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/Names/iName.sol";
import "src/Interface/iHelix2.sol";
import "src/Interface/iENS.sol";

/**
 * @author sshmatrix
 * @title Helix2 Base
 */
abstract contract BaseRegistrar {
    /// Dev
    address public Dev;

    /// @dev : Contract metadata
    string public constant name = "Helix2 Name Service";
    string public constant symbol = "HNS";

    /// @dev : Helix2 Dev events
    event NewDev(address Dev, address newDev);
    error OnlyDev(address _dev, address _you);

    /// Interface
    iNAME public NAMES;
    iENS public ENS;
    iHELIX2 public HELIX2;

    /// @dev : Default resolver used by this contract
    address public defaultResolver;

    /// @dev : Pause/Resume contract
    bool public active = true;

    constructor() {
        Dev = msg.sender;
    }

    /// @dev : Modifier to allow only dev
    modifier onlyDev() {
        if (msg.sender != Dev) {
            revert OnlyDev(Dev, msg.sender);
        }
        _;
    }

    /**
     * @dev : Toggle if contract is active or paused, only Dev can toggle
     */
    function toggleActive() external onlyDev {
        active = !active;
    }

    /**
     * @dev : transfer contract ownership to new Dev
     * @param newDev : new Dev
     */
    function changeDev(address newDev) external onlyDev {
        emit NewDev(Dev, newDev);
        Dev = newDev;
    }
}
