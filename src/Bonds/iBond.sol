//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

/**
 * @dev Helix2 Bonds Global Interface
 * @notice Global interface for Storage and Registry
 */
interface iBOND {
    // write functions
    function register(bytes32 bondhash, bytes32 cation) external;

    function setCation(bytes32 bondhash, bytes32 cation) external;

    function setController(bytes32 bondhash, address controller) external;

    function setAnion(bytes32 bondhash, bytes32 anion) external;

    function setLabel(bytes32 bondhash, bytes32 label) external;

    function setCovalence(bytes32 bondhash, bool covalence) external;

    function setExpiry(bytes32 bondhash, uint expiry) external;

    function renew(bytes32 bondhash, uint expiry) external;

    function setResolver(bytes32 bondhash, address resolver) external;

    function hook(bytes32 bondhash, address config, uint8 rule) external;

    function rehook(bytes32 bondhash, address config, uint8 rule) external;

    function unhook(bytes32 bondhash, uint8 rule, uint index) external;

    function unhookAll(bytes32 bondhash) external;

    // view functions
    function cation(bytes32 bondhash) external view returns (bytes32);

    function controller(bytes32 bondhash) external view returns (address);

    function anion(bytes32 bondhash) external view returns (bytes32);

    function label(bytes32 bondhash) external view returns (bytes32);

    function covalence(bytes32 bondhash) external view returns (bool);

    function expiry(bytes32 bondhash) external view returns (uint);

    function hooksWithRules(
        bytes32 bondhash
    ) external view returns (uint8[] memory, address[] memory);

    function resolver(bytes32 bondhash) external view returns (address);

    function recordExists(bytes32 bondhash) external view returns (bool);
}
