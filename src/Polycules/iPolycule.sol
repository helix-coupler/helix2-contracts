//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

/**
 * @dev Helix2 Polycules Global Interface
 * @notice Global interface for Storage and Registry
 */
interface iPOLYCULE {
    // write functions
    function register(bytes32 polyhash, bytes32 cation) external;

    function setCation(bytes32 polyhash, bytes32 cation) external;

    function setController(bytes32 polyhash, address controller) external;

    function addAnionWithConfig(
        bytes32 polyhash,
        bytes32 anion,
        address config,
        uint8 rule
    ) external;

    function setAnions(
        bytes32 polyhash,
        bytes32[] memory anions,
        address[] memory config,
        uint8[] memory rules
    ) external;

    function popAnion(bytes32 polyhash, bytes32 anion) external;

    function popAnion(bytes32 polyhash, uint index) external;

    function setLabel(bytes32 polyhash, bytes32 label) external;

    function setCovalence(bytes32 polyhash, bool covalence) external;

    function setExpiry(bytes32 polyhash, uint expiry) external;

    function renew(bytes32 molyhash, uint expiry) external;

    function setResolver(bytes32 polyhash, address resolver) external;

    function hook(
        bytes32 anion,
        bytes32 polyhash,
        address config,
        uint8 rule
    ) external;

    function rehook(bytes32 polyhash, address config, uint8 rule) external;

    function unhook(bytes32 polyhash, uint8 rule, uint index) external;

    function unhookAll(bytes32 polyhash) external;

    // view functions
    function cation(bytes32 polyhash) external view returns (bytes32);

    function controller(bytes32 polyhash) external view returns (address);

    function anions(bytes32 polyhash) external view returns (bytes32[] memory);

    function label(bytes32 polyhash) external view returns (bytes32);

    function covalence(bytes32 polyhash) external view returns (bool);

    function expiry(bytes32 polyhash) external view returns (uint);

    function hooksWithRules(
        bytes32 polyhash
    ) external view returns (uint8[] memory, address[] memory);

    function resolver(bytes32 polyhash) external view returns (address);

    function recordExists(bytes32 polyhash) external view returns (bool);
}
