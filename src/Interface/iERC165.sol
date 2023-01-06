//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

/**
 * @dev EIP-165
 */
interface iERC165 {
    // view functions
    function supportsInterface(bytes4 interfaceID) external view returns (bool);

    // write functions
    function setInterface(bytes4 interfaceID, bool flag) external;
}
