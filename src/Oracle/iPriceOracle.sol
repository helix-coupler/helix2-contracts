// SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

/**
 * @dev Helix2 Price Oracle
 */
interface iPriceOracle {
    /// @dev : HELIX2 Price Oracle functions
    // view functions

    function getPrices() external view returns (uint256[4] memory);

    // write functions
    function setPrices(uint256[4] calldata newPrices) external;

    function setPrice(uint256 index, uint256 newPrice) external;
}
