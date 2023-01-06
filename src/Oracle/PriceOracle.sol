//SPDX-License-Identifier: WTFPL v6.9
pragma solidity >0.8.0 <0.9.0;

import "src/Oracle/iPriceOracle.sol";

/**
 * @dev : Helix2 Resolver Base
 * @notice : sshmatrix (BeenSick Labs)
 */

abstract contract PriceOracleBase {
    // @dev : Revert on fallback
    fallback() external payable {
        revert();
    }

    /// @dev : Revert on receive
    receive() external payable {
        revert();
    }
}

/**
 * @dev : Helix2 Price Oracle
 */
contract Helix2PriceOracle is PriceOracleBase {
    /// Dev
    address public Dev;

    /// Events
    event NewPrices(uint256[4] newPrices);
    event NewPrice(uint256 index, uint256 newPrice);
    error OnlyDev(address _dev, address _you);

    /// @dev : Helix2 base prices per second (Wei/second value)
    uint256[4] public prices = [
        0.0000000000002 ether, /// Name Base Price (= 200 Kwei/second)
        0.0000000000002 ether, /// Bond Base Price (= 200 Kwei/second)
        0.0000000000002 ether, /// Molecule Base Price (= 200 Kwei/second)
        0.0000000000002 ether /// Polycule Base Price (= 200 Kwei/second)
    ];

    constructor() {
        Dev = msg.sender;
    }

    /// @dev : Modifier to allow only dev
    modifier onlyDev() {
        if (msg.sender != Dev) {
            revert OnlyDev(Dev, msg.sender);
        }
        _;
    }

    /**
     * @dev sets new base price list
     * @param newPrices : list of base prices
     */
    function setPrices(uint256[4] calldata newPrices) external onlyDev {
        emit NewPrices(newPrices);
        prices = newPrices;
    }

    /**
     * @dev replace single base price value
     * @param index : index to replace (starts from 0)
     * @param newPrice : new base price for index
     */
    function setPrice(uint256 index, uint256 newPrice) external onlyDev {
        emit NewPrice(index, newPrice);
        prices[index] = newPrice;
    }

    /**
     * @dev returns Base Price list
     */
    function getPrices() public view returns (uint256[4] memory) {
        return prices;
    }
}
