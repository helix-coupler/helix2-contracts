// SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/Base.sol";
import "src/interface/iERC721.sol";

/**
 * @dev : Helix2 ERC721 Base
 */
abstract contract ERC721 is Base {
    mapping(uint256 => address) internal _ownerOf;
    mapping(uint256 => address) public _approved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    error CannotBurn();
    event NewDev(address Dev, address newDev);
    error ERC721IncompatibleReceiver(address to);
    error Unauthorized(address operator, address owner, uint256 tokenID);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenID);
    event Approval(address indexed owner, address indexed spender, uint256 indexed tokenID);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function ownerOf(uint256 tokenID) public view returns (address) {
        require(_ownerOf[tokenID] != address(0), "INVALID_TOKENID");
        return _ownerOf[tokenID];
    }

    /**
     * @dev : sets Controller for one token
     * @param controller : operator address to be set as Controller
     * @param tokenID : token ID
     */
    function approve(address controller, uint256 tokenID) external payable {
        if (msg.sender != _ownerOf[tokenID] || !isApprovedForAll[_ownerOf[tokenID]][msg.sender]) {
            revert Unauthorized(msg.sender, _ownerOf[tokenID], tokenID);
        }
        _approved[tokenID] = controller;
        emit Approval(msg.sender, controller, tokenID);
    }

    /**
     * @dev : sets Controller (for an owner)
     * @param controller : operator address to be set as Controller
     * @param flag : bool to set
     */
    function setApprovalForAll(address controller, bool flag) external payable {
        isApprovedForAll[msg.sender][controller] = flag;
        emit ApprovalForAll(msg.sender, controller, flag);
    }

    /**
     * @dev : transferFrom() function
     * @param from : from address
     * @param to : to address
     * @param tokenID : token
     */
    function transferFrom(address from, address to, uint256 tokenID) external payable {
        _transfer(from, to, tokenID, "");   // standard fallback
    }

    /**
     * @dev : safeTransferFrom() function
     * @param from : from address
     * @param to : to address
     * @param tokenID : token
     */
    function safeTransferFrom(address from, address to, uint256 tokenID) external payable {
        _transfer(from, to, tokenID, "");   // standard fallback
    }

     /**
     * @dev : safeTransferFrom() function with extra data
     * @param from : from address
     * @param to : to address
     * @param tokenID : token
     * @param data : extra data
     */
    function safeTransferFrom(address from, address to, uint256 tokenID, bytes memory data) external payable {
        _transfer(from, to, tokenID, data); // standard fallback
    }

    /**
     * @dev : custom _transfer() function
     * @param from : address of sender
     * @param to : address of receiver
     * @param tokenID : token
     */
    function _transfer(address from, address to, uint256 tokenID, bytes memory data) internal {
        // cannot burn
        if (to == address(0)) {
            revert CannotBurn();
        }
        // check ownership of <from>
        if (_ownerOf[tokenID] != from) {
            revert Unauthorized(_ownerOf[tokenID], from, tokenID);
        }
        // check permissions of <sender>
        if (msg.sender != _ownerOf[tokenID] && !isApprovedForAll[from][msg.sender] && msg.sender != _approved[tokenID]) {
            revert Unauthorized(msg.sender, from, tokenID);
        }

        delete _approved[tokenID]; // reset approved
        _ownerOf[tokenID] = to;    // change ownership
        emit Transfer(from, to, tokenID);
        if (to.code.length > 0) {
            try iERC721Receiver(to).onERC721Received(msg.sender, from, tokenID, data) returns (bytes4 retval) {
                if (retval != iERC721Receiver.onERC721Received.selector) {
                    revert ERC721IncompatibleReceiver(to);
                }
            } catch {
                revert ERC721IncompatibleReceiver(to);
            }
        }
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}
