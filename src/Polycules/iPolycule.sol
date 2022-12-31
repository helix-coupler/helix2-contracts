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
    function register(bytes32 polyhash, bytes32 cation) external;

    function setCation(bytes32 polyhash, bytes32 cation) external;

    function setController(bytes32 polyhash, address controller) external;

    function addAnion(bytes32 polyhash, bytes32 anion) external;

    function setAnions(
        bytes32 polyhash,
        bytes32[] memory anion,
        address[] memory config,
        uint8[] memory rules
    ) external;

    function popAnion(bytes32 polyhash, bytes32 anion) external;

    function setAlias(bytes32 polyhash, bytes32 _alias) external;

    function setCovalence(bytes32 polyhash, bool covalence) external;

    function setExpiry(bytes32 polyhash, uint expiry) external;

    function renew(bytes32 molyhash, uint expiry) external;

    function setRecord(bytes32 polyhash, address resolver) external;

    function setResolver(bytes32 polyhash, address resolver) external;

    function hook(bytes32 polyhash, address config, uint8 rule) external;

    function rehook(bytes32 polyhash, address config, uint8 rule) external;

    function rehook(bytes32 polyhash, uint8 rule, bytes32 anion) external;

    function unhook(bytes32 polyhash, uint8 rule) external;

    function unhook(bytes32 polyhash, bytes32 anion) external;

    function unhookAll(bytes32 polyhash) external;

    function setApprovalForAll(address controller, bool approved) external;

    function changeDev(address newDev) external;

    // view functions
    function cation(bytes32 polyhash) external view returns (bytes32);

    function controller(bytes32 polyhash) external view returns (address);

    function anion(bytes32 polyhash) external view returns (bytes32[] memory);

    function alias_(bytes32 polyhash) external view returns (bytes32);

    function covalence(bytes32 polyhash) external view returns (bool);

    function expiry(bytes32 polyhash) external view returns (uint);

    function hooksWithRules(
        bytes32 polyhash
    ) external view returns (uint8[] memory, address[] memory);

    function resolver(bytes32 polyhash) external view returns (address);

    function recordExists(bytes32 polyhash) external view returns (bool);

    function isApprovedForAll(
        address cation,
        address controller
    ) external view returns (bool);
}
