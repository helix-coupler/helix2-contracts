// SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

/**
 * @dev Helix2 Default Resolver Interface
 */
interface iMoleculeResolver {
    function contenthash(bytes32 molyhash) external view returns (bytes memory);

    function addr(bytes32 molyhash) external view returns (address payable);

    function addr2(
        bytes32 molyhash,
        uint256 coinType
    ) external view returns (bytes memory);

    function pubkey(
        bytes32 molyhash
    ) external view returns (bytes32 x, bytes32 y);

    function text(
        bytes32 molyhash,
        string calldata key
    ) external view returns (string memory);
}
