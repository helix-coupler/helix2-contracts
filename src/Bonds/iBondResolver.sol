// SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

/**
 * @dev Helix2 Default Resolver Interface
 */
interface iBondResolver {
    function contenthash(bytes32 bondhash) external view returns (bytes memory);

    function addr(bytes32 bondhash) external view returns (address payable);

    function addr2(
        bytes32 bondhash,
        uint256 coinType
    ) external view returns (bytes memory);

    function pubkey(
        bytes32 bondhash
    ) external view returns (bytes32 x, bytes32 y);

    function text(
        bytes32 bondhash,
        string calldata key
    ) external view returns (string memory);
}
