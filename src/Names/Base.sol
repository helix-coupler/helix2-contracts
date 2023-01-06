// SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/Names/iName.sol";
import "src/Names/iERC721.sol";
import "src/Interface/iHelix2.sol";
import "src/Interface/iERC165.sol";
import "src/Interface/iERC173.sol";
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
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    error OnlyDev(address _dev, address _you);

    /// Interface
    iNAME public NAMES;
    iENS public ENS;
    iHELIX2 public HELIX2;

    /// @dev : Default resolver used by this contract
    address public defaultResolver;

    /// @dev : Pause/Resume contract
    bool public active = true;
    /// @dev : EIP-165
    mapping(bytes4 => bool) public supportsInterface;

    constructor() {
        Dev = msg.sender;
        // Interface
        supportsInterface[type(iERC165).interfaceId] = true;
        supportsInterface[type(iERC173).interfaceId] = true;
        supportsInterface[type(iERC721Metadata).interfaceId] = true;
        supportsInterface[type(iERC721).interfaceId] = true;
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
     * @dev get owner of contract
     * @return address of controlling dev or multi-sig wallet
     */
    function owner() external view returns (address) {
        return Dev;
    }

    /**
     * @dev transfer contract ownership to new Dev
     * @param newDev : new Dev
     */
    function transferOwnership(address newDev) external onlyDev {
        emit OwnershipTransferred(Dev, newDev);
        Dev = newDev;
    }

    /**
     * @dev setInterface
     * @notice EIP-165
     * @param sig : signature
     * @param value : boolean
     */
    function setInterface(bytes4 sig, bool value) external payable onlyDev {
        require(sig != 0xffffffff, "INVALID_INTERFACE_SELECTOR");
        supportsInterface[sig] = value;
    }
}
