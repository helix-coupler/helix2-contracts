//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

/**
 * @dev EIP-173
 */
interface iERC173 {
    function owner() external view returns (address);

    function transferOwnership(address _newOwner) external;
}
