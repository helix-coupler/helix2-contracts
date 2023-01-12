//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

/**
 * @dev Helix2 Names Global Interface
 * @notice Global interface for Storage and Registry
 */
interface iNAME {
    // write functions
    function register(
        string memory label,
        bytes32 namehash,
        address owner
    ) external;

    function setLabel(bytes32 namehash, string calldata label) external;

    function setOwner(bytes32 namehash, address owner) external;

    function setBalance(address owner, uint256 balance) external;

    function setOwnerERC721(bytes32 namehash, address owner) external;

    function setController(bytes32 namehash, address controller) external;

    function setControllerERC721(bytes32 namehash, address controller) external;

    function setExpiry(bytes32 namehash, uint expiry) external;

    function renew(bytes32 namehash, uint expiry) external;

    function setResolver(bytes32 namehash, address resolver) external;

    // view functions
    function owner(bytes32 namehash) external view returns (address);

    function label(bytes32 namehash) external view returns (string memory);

    function controller(bytes32 namehash) external view returns (address);

    function expiry(bytes32 namehash) external view returns (uint);

    function resolver(bytes32 namehash) external view returns (address);

    function recordExists(bytes32 namehash) external view returns (bool);
}
