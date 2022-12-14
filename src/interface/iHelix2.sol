//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

/**
 * @dev Helix2 Interface
 */
interface iWOOLBALL {
    event Transfer(bytes32 indexed link, address owner);
    event NewResolver(bytes32 indexed link, address resolver);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setRecord(bytes32 link, address owner, address resolver) external;
    function setResolver(bytes32 link, address resolver) external;
    function setOwner(bytes32 link, address owner) external;
    function setApprovalForAll(address operator, bool approved) external;

    function Dev() external view returns (address);
    function owner(bytes32 link) external view returns (address);
    function resolver(bytes32 link) external view returns (address);
    function recordExists(bytes32 link) external view returns (bool);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}