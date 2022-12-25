//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

/**
 * @dev Helix2 Bonds Interface
 */
interface iBOND {
    /// REGISTRAR

    /// REGISTRY
    /// @dev : HELIX2 Bonds external functions
    // write functions
    function setOwner(bytes32 bondhash, bytes32 owner) external;
    function setController(bytes32 bondhash, address controller) external;
    function setTarget(bytes32 bondhash, bytes32 target) external;
    function setAlias(bytes32 bondhash, bytes32 _alias) external;
    function setSecure(bytes32 bondhash, bool secure) external;
    function setExpiry(bytes32 bondhash, uint expiry) external;
    function setRecord(bytes32 bondhash, address resolver) external;
    function setResolver(bytes32 bondhash, address resolver) external;
    function setApprovalForAll(address controller, bool approved) external;
    function changeDev(address newDev) external;

    // view functions
    function owner(bytes32 bondhash) external view returns(bytes32);
    function controller(bytes32 bondhash) external view returns(address);
    function target(bytes32 bondhash) external view returns(bytes32);
    function _alias(bytes32 bondhash) external view returns(bytes32);
    function secure(bytes32 bondhash) external view returns(bool);
    function expiry(bytes32 bondhash) external view returns(uint);
    function resolver(bytes32 bondhash) external view returns(address);
    function recordExists(bytes32 bondhash) external view returns(bool);
    function isApprovedForAll(address owner, address controller) external view returns(bool);
}