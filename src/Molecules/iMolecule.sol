//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

/**
 * @dev Helix2 Molecules Global Interface
 * @notice Global interface for Storage and Registry
 */
interface iMOLECULE {
    // write functions
    function register(bytes32 molyhash, bytes32 cation) external;

    function setCation(bytes32 molyhash, bytes32 cation) external;

    function setController(bytes32 molyhash, address controller) external;

    function addAnion(bytes32 molyhash, bytes32 anion) external;

    function setAnions(bytes32 molyhash, bytes32[] memory anion) external;

    function popAnion(bytes32 molyhash, bytes32 anion) external;

    function popAnion(bytes32 molyhash, uint index) external;

    function setLabel(bytes32 molyhash, bytes32 label) external;

    function setCovalence(bytes32 molyhash, bool covalence) external;

    function setExpiry(bytes32 molyhash, uint expiry) external;

    function renew(bytes32 molyhash, uint expiry) external;

    function setResolver(bytes32 molyhash, address resolver) external;

    function hook(bytes32 molyhash, address config, uint256 rule) external;

    function rehook(bytes32 molyhash, address config, uint256 rule) external;

    function unhook(bytes32 molyhash, uint256 rule, uint index) external;

    function unhookAll(bytes32 molyhash) external;

    // view functions
    function cation(bytes32 molyhash) external view returns (bytes32);

    function controller(bytes32 molyhash) external view returns (address);

    function anions(bytes32 molyhash) external view returns (bytes32[] memory);

    function label(bytes32 molyhash) external view returns (bytes32);

    function covalence(bytes32 molyhash) external view returns (bool);

    function expiry(bytes32 molyhash) external view returns (uint);

    function hooksWithRules(
        bytes32 molyhash
    ) external view returns (uint256[] memory, address[] memory);

    function resolver(bytes32 molyhash) external view returns (address);

    function recordExists(bytes32 molyhash) external view returns (bool);
}
