// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev : ERC-165 Interface Standard
interface iERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
