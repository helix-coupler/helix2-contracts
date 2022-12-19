//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

/**
 * @dev Helix2 Interface
 */
interface iHELIX2 {

    /// @dev : HELIX2 global events
    event NewENSRegistry(address newReg);

    /*//////////////////////////////////////////////////////////////
                                NAMES
    //////////////////////////////////////////////////////////////*/
    /// @dev : HELIX2 name functions (native)
    function setNameOwner(bytes32 namehash, address owner) external returns(bytes32);


    /*//////////////////////////////////////////////////////////////
                                BONDS
    //////////////////////////////////////////////////////////////*/
    /// @dev : HELIX2 events (similar to ENS minus TTL)
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);
    event Transfer(bytes32 indexed bond, address owner);
    event NewResolver(bytes32 indexed bond, address resolver);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /// @dev : HELIX2 external functions (similar to ENS minus TTL)
    // write functions
    function setRecord(bytes32 bond, address owner, address resolver) external;
    function setResolver(bytes32 bond, address resolver) external;
    function setOwner(bytes32 bond, address owner) external;
    function setApprovalForAll(address operator, bool approved) external;
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver) external;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external returns(bytes32);

    // view functions
    function Dev() external view returns (address);
    function owner(bytes32 bond) external view returns (address);
    function resolver(bytes32 bond) external view returns (address);
    function recordExists(bytes32 bond) external view returns (bool);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}