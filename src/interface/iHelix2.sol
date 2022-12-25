//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

/**
 * @dev Helix2 Interface
 */
interface iHELIX2 {
    /// @dev : HELIX2 Names external functions
    // write functions

    // view functions
    function isDev() external view returns (address);

    function getRegistry() external view returns (address[4] memory);

    function getRoothash() external view returns (bytes32[4] memory);

    function getPrices() external view returns (uint256[4] memory);
}
