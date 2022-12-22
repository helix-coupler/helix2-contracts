//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

/**
 * @dev Helix2 Bonds Interface
 */
interface iBOND {

    /// @dev : HELIX2 Bonds events
    event NewOwner(bytes32 indexed bondhash, address owner);
    event NewResolver(bytes32 indexed bondhash, address resolver);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    /// @dev : HELIX2 Bonds external functions
    // write functions
    function setOwner(bytes32 bondhash, address owner) external;
    function setResolver(bytes32 bondhash, address resolver) external;
    function setApprovalForAll(address controller, bool approved) external;

    // view functions
    function owner(bytes32 bondhash) external view returns(address);
    function resolver(bytes32 bondhash) external view returns(address);
    function recordExists(bytes32 bondhash) external view returns(bool);
    function isApprovedForAll(address owner, address controller) external view returns(bool);
}