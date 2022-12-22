// SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/Interface/iERC721.sol";

/**
 * @author sshmatrix
 * @title Helix2 Base
 */
abstract contract Base {
    /// Events
    error OnlyDev(address _dev, address _you);
    
    /// Dev
    address public Dev;
    
    /// @dev : Forbidden characters
    string[4] public illegal = [".", "?", "!", "#"];

    /// @dev : Root Identifier
    bytes32[4] public roothash = [
        keccak256(abi.encodePacked(bytes32(0), keccak256("."))), /// Name Roothash
        keccak256(abi.encodePacked(bytes32(0), keccak256("?"))), /// Bond Roothash
        keccak256(abi.encodePacked(bytes32(0), keccak256("!"))), /// Molecule Roothash
        keccak256(abi.encodePacked(bytes32(0), keccak256("#")))  /// Polycule Roothash
    ];

    /// @dev : Default resolver used by this contract
    address public DefaultResolver;

    /// @dev : ENS Registry
    address public ensRegistry = 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;

    /// @dev : Helix2 Registry array
    address[4] public helix2Registry = [
        0x0000000000000000000000000000000000000001, /// Name Registry
        0x0000000000000000000000000000000000000002, /// Bond Registry
        0x0000000000000000000000000000000000000003, /// Molecule Registry
        0x0000000000000000000000000000000000000004  /// Polycule Registry
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

    /**
     * @dev : returns Dev address
     */
    function isDev() public view returns(address) {
        return Dev;
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