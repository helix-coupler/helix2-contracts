// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev : ERC-173 Contract Ownership Standard
interface iERC173 {
    function owner() external view returns (address owner_);

    function transferOwnership(address _newOwner) external;
}
