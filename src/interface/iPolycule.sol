//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

/**
 * @dev Helix2 Polycules Interface
 */
interface iPOLYCULE {
    /// REGISTRAR

    /// REGISTRY
    /// @dev : HELIX2 Polycules external functions
    // write functions
    function setOwner(bytes32 polyculehash, bytes32 owner) external;
    function setController(bytes32 polyculehash, address controller) external;
    function setTarget(bytes32 polyculehash, bytes32[] calldata target) external;
    function setAlias(bytes32 polyculehash, bytes32 _alias) external;
    function setSecure(bytes32 polyculehash, bool[] memory secure) external;
    function setExpiry(bytes32 polyculehash, uint expiry) external;
    function setRecord(bytes32 polyculehash, address resolver) external;
    function setResolver(bytes32 polyculehash, address resolver) external;
    function setApprovalForAll(address controller, bool approved) external;
    function changeDev(address newDev) external;

    // view functions
    function owner(bytes32 polyculehash) external view returns(bytes32);
    function controller(bytes32 polyculehash) external view returns(address);
    function target(bytes32 polyculehash) external view returns(bytes32[] memory);
    function _alias(bytes32 polyculehash) external view returns(bytes32);
    function secure(bytes32 polyculehash) external view returns(bool[] memory);
    function expiry(bytes32 polyculehash) external view returns(uint);
    function resolver(bytes32 polyculehash) external view returns(address);
    function recordExists(bytes32 polyculehash) external view returns(bool);
    function isApprovedForAll(address owner, address controller) external view returns(bool);
}