// SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/interface/iERC721.sol";

/**
 * @author sshmatrix
 * @title Helix2 Base
 */
abstract contract Base {
    /// Dev
    address public Dev;

    /// @dev : Root Identifier
    bytes32 public constant roothash = keccak256(abi.encodePacked(bytes32(0), keccak256("?")));

    /// @dev : Default resolver used by this contract
    address public DefaultResolver;

    /// @dev : ENS Registry
    address public ensRegistry = 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;

    /// @dev : Helix2 Registry array
    address[4] public helix2Registry = [
        0xC0de4C0Cac01AC0de4C0Cac01AC0de4C0Cac01A0, /// Name Registry
        0xC0de4C0Cac01A0Cac01AC0d04C0Cac01AC0d01A0, /// Bond Registry
        0xC0e4C0Cac0C0C0C0C0C0Cac01AC0de4C0Cac01A0, /// Molecule Registry
        0xC0dc01ACc01AC10deedee4C0c01AC0deC0de01A0, /// Polycule Registry
    ];

    /// @dev : Pause/Resume contract
    bool public active = true;
    
    /// @dev : Contract metadata
    string public constant name = "Helix2 Link Service";
    string public constant symbol = "HELIX2";
    mapping(bytes4 => bool) public supportsInterface;

    constructor() {
        Dev = msg.sender;
        supportsInterface[type(iERC165).interfaceId] = true;
        supportsInterface[type(iERC721).interfaceId] = true;
        supportsInterface[type(iERC721Metadata).interfaceId] = true;

    }

    /// @dev : Modifier to allow only dev
    modifier onlyDev() {
        if (msg.sender != Dev) {
            revert OnlyDev(Dev, msg.sender);
        }
        _;
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

    /**
     * @dev : withdraw ether to Dev, anyone can trigger
     */
    function withdrawEther() external payable {
        (bool ok,) = Dev.call{value: address(this).balance}("");
        require(ok, "ETH_TRANSFER_FAILED");
    }

    /**
     * @dev : to be used in case some tokens get locked in the contract
     * @param token : token to release
     */
    function withdrawToken(address token) external payable {
        iERC20(token).transferFrom(address(this), Dev, iERC20(token).balanceOf(address(this)));
    }

    /// @dev : revert on fallback
    fallback() external payable {
        revert();
    }

    /// @dev : revert on receive
    receive() external payable {
        revert();
    }
}