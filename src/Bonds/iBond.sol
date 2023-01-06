//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

/**
 * @dev Helix2 Bonds Interface
 */
interface iBOND {
    /// @dev : HELIX2 Bonds external functions
    // write functions
    function register(bytes32 bondhash, bytes32 cation) external;

    function setCation(bytes32 bondhash, bytes32 cation) external;

    function setController(bytes32 bondhash, address controller) external;

    function setAnion(bytes32 bondhash, bytes32 anion) external;

    function setAlias(bytes32 bondhash, bytes32 _alias) external;

    function setCovalence(bytes32 bondhash, bool covalence) external;

    function setExpiry(bytes32 bondhash, uint expiry) external;

    function renew(bytes32 bondhash, uint expiry) external;

    function setRecord(bytes32 bondhash, address resolver) external;

    function setResolver(bytes32 bondhash, address resolver) external;

    function hook(bytes32 bondhash, address config, uint8 rule) external;

    function rehook(bytes32 bondhash, address config, uint8 rule) external;

    function unhook(bytes32 bondhash, uint8 rule) external;

    function unhookAll(bytes32 bondhash) external;

    function setApprovalForAll(address controller, bool approved) external;

    function changeDev(address newDev) external;

    function setConfig(address helix2) external;

    function toggleActive() external;

    // view functions
    function cation(bytes32 bondhash) external view returns (bytes32);

    function controller(bytes32 bondhash) external view returns (address);

    function anion(bytes32 bondhash) external view returns (bytes32);

    function alias_(bytes32 bondhash) external view returns (bytes32);

    function covalence(bytes32 bondhash) external view returns (bool);

    function expiry(bytes32 bondhash) external view returns (uint);

    function hooksWithRules(
        bytes32 bondhash
    ) external view returns (uint8[] memory, address[] memory);

    function resolver(bytes32 bondhash) external view returns (address);

    function recordExists(bytes32 bondhash) external view returns (bool);

    function isApprovedForAll(
        address cation,
        address controller
    ) external view returns (bool);
}
