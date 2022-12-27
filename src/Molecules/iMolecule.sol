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
    function register(bytes32 molyhash, bytes32 cation) external;

    function setCation(bytes32 molyhash, bytes32 cation) external;

    function setController(bytes32 molyhash, address controller) external;

    function addAnion(bytes32 molyhash, bytes32 anion) external;

    function setAnions(bytes32 molyhash, bytes32[] memory anion) external;

    function popAnion(bytes32 molyhash, bytes32 anion) external;

    function setAlias(bytes32 molyhash, bytes32 _alias) external;

    function setCovalence(bytes32 molyhash, bool covalence) external;

    function setExpiry(bytes32 molyhash, uint expiry) external;

    function setRecord(bytes32 molyhash, address resolver) external;

    function setResolver(bytes32 molyhash, address resolver) external;

    function hook(bytes32 molyhash, uint8 rule, address config) external;

    function rehook(bytes32 molyhash, uint8 rule, address config) external;

    function unhook(bytes32 molyhash, address config) external;

    function unhookAll(bytes32 molyhash) external;

    function setApprovalForAll(address controller, bool approved) external;

    function changeDev(address newDev) external;

    // view functions
    function cation(bytes32 molyhash) external view returns (bytes32);

    function controller(bytes32 molyhash) external view returns (address);

    function anion(bytes32 molyhash) external view returns (bytes32[] memory);

    function alias_(bytes32 molyhash) external view returns (bytes32);

    function covalence(bytes32 molyhash) external view returns (bool);

    function expiry(bytes32 molyhash) external view returns (uint);

    function hooksWithRules(
        bytes32 molyhash
    ) external view returns (address[] memory, uint8[] memory);

    function resolver(bytes32 molyhash) external view returns (address);

    function recordExists(bytes32 molyhash) external view returns (bool);

    function isApprovedForAll(
        address cation,
        address controller
    ) external view returns (bool);
}
