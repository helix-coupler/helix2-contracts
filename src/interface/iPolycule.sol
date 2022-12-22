//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

/**
 * @dev Helix2 Polycules Interface
 */
interface iPOLYCULE {
    /// REGISTRAR

    /// REGISTRY
    /// @dev : HELIX2 Polycules events
    event NewPolycule(bytes32 indexed polyculehash, address owner);
    event NewOwner(bytes32 indexed polyculehash, address owner);
    event NewController(bytes32 indexed namehash, address controller);
    event NewExpiry(bytes32 indexed namehash, uint expiry);
    event NewRecord(bytes32 indexed namehash, address resolver);
    event NewResolver(bytes32 indexed polyculehash, address resolver);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    /// @dev : HELIX2 Polycules external functions
    // write functions
    function newPolycule(bytes32 labelhash, address owner) external;
    function setOwner(bytes32 polyculehash, address owner) external;
    function setResolver(bytes32 polyculehash, address resolver) external;
    function setApprovalForAll(address controller, bool approved) external;
    function changeDev(address newDev) external;

    // view functions
    function owner(bytes32 polyculehash) external view returns(address);
    function resolver(bytes32 polyculehash) external view returns(address);
    function recordExists(bytes32 polyculehash) external view returns(bool);
    function isApprovedForAll(address owner, address controller) external view returns(bool);
}