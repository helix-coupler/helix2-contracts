//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

/**
 * @dev Helix2 Names Interface
 */
interface iNAME {
    /// REGISTRAR

    /// REGISTRY
    /// @dev : HELIX2 Names external functions
    // write functions
    function setOwner(bytes32 namehash, address owner) external;

    function setController(bytes32 namehash, address controller) external;

    function setExpiry(bytes32 namehash, uint expiry) external;

    function setRecord(bytes32 namehash, address resolver) external;

    function setResolver(bytes32 namehash, address resolver) external;

    function setApprovalForAll(address controller, bool approved) external;

    function changeDev(address newDev) external;

    // view functions
    function owner(bytes32 namehash) external view returns (address);

    function controller(bytes32 namehash) external view returns (address);

    function expiry(bytes32 namehash) external view returns (uint);

    function resolver(bytes32 namehash) external view returns (address);

    function recordExists(bytes32 namehash) external view returns (bool);

    function isApprovedForAll(
        address owner,
        address controller
    ) external view returns (bool);
}
