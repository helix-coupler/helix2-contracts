//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

/**
 * @dev EIP-173
 */
interface iERC173 {
    // view functions
    function owner() external view returns (address);

    // write functions
    function transferOwnership(address _newOwner) external;
}
