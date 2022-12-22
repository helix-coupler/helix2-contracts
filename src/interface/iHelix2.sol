//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

/**
 * @dev Helix2 Interface
 */
interface iHELIX2 {
    error OnlyDev(address _dev, address _you);

    /// @dev : Helix2 global events
    event NewRegistry(address[4] newReg);
    event NewSubRegistry(uint256 index, address newReg);

    function isDev() external view returns(address);
}