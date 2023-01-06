//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

/**
 * @dev EIP-165
 */
interface iERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}
