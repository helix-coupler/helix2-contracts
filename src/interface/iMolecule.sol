//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

/**
 * @dev Helix2 Molecules Interface
 */
interface iMOLECULE {
    /// REGISTRAR

    /// REGISTRY
    /// @dev : HELIX2 Molecules external functions
    // write functions
    function setOwner(bytes32 moleculehash, address owner) external;
    function setController(bytes32 moleculehash, address controller) external;
    function setExpiry(bytes32 moleculehash, uint expiry) external;
    function setRecord(bytes32 moleculehash, address resolver) external;
    function setResolver(bytes32 moleculehash, address resolver) external;
    function setApprovalForAll(address controller, bool approved) external;
    function changeDev(address newDev) external;

    // view functions
    function owner(bytes32 moleculehash) external view returns(address);
    function controller(bytes32 moleculehash) external view returns(address);
    function expiry(bytes32 moleculehash) external view returns(uint);
    function resolver(bytes32 moleculehash) external view returns(address);
    function recordExists(bytes32 moleculehash) external view returns(bool);
    function isApprovedForAll(address owner, address controller) external view returns(bool);
}