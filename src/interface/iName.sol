//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

/**
 * @dev Helix2 Names Interface
 */
interface iNAME {

    /// @dev : HELIX2 Names events
    event NewOwner(bytes32 indexed namehash, address owner);
    event NewResolver(bytes32 indexed namehash, address resolver);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    /// @dev : HELIX2 Names external functions
    // write functions
    function setOwner(bytes32 namehash, address owner) external;
    function setResolver(bytes32 namehash, address resolver) external;
    function setApprovalForAll(address controller, bool approved) external;

    // view functions
    function owner(bytes32 namehash) external view returns(address);
    function resolver(bytes32 namehash) external view returns(address);
    function recordExists(bytes32 namehash) external view returns(bool);
    function isApprovedForAll(address owner, address controller) external view returns(bool);
}