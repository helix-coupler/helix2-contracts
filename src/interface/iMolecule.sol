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
    function setCation(bytes32 moleculehash, bytes32 cation) external;

    function setController(bytes32 moleculehash, address controller) external;

    function addAnion(bytes32 moleculehash, bytes32 anion) external;

    function setAnions(bytes32 moleculehash, bytes32[] memory anion) external;

    function popAnion(bytes32 moleculehash, bytes32 anion) external;

    function setAlias(bytes32 moleculehash, bytes32 _alias) external;

    function setSecure(bytes32 moleculehash, bool secure) external;

    function setExpiry(bytes32 moleculehash, uint expiry) external;

    function setRecord(bytes32 moleculehash, address resolver) external;

    function setResolver(bytes32 moleculehash, address resolver) external;

    function hook(bytes32 moleculehash, uint8 rule, address config) external;

    function rehook(bytes32 moleculehash, uint8 rule, address config) external;

    function unhook(bytes32 moleculehash, address config) external;

    function unhookAll(bytes32 moleculehash) external;

    function setApprovalForAll(address controller, bool approved) external;

    function changeDev(address newDev) external;

    // view functions
    function cation(bytes32 moleculehash) external view returns (bytes32);

    function controller(bytes32 moleculehash) external view returns (address);

    function anion(
        bytes32 moleculehash
    ) external view returns (bytes32[] memory);

    function _alias(bytes32 moleculehash) external view returns (bytes32);

    function secure(bytes32 moleculehash) external view returns (bool);

    function expiry(bytes32 moleculehash) external view returns (uint);

    function resolver(bytes32 moleculehash) external view returns (address);

    function recordExists(bytes32 moleculehash) external view returns (bool);

    function isApprovedForAll(
        address cation,
        address controller
    ) external view returns (bool);
}
