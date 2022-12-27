// SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/Names/Base.sol";
import "src/Names/iName.sol";
import "src/Names/iERC721.sol";

/**
 * @dev : Helix2 ERC721 Wrapper
 */
abstract contract ERC721 is BaseRegistrar {
    mapping(address => uint256) internal _balanceOf;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /// @dev : Modifier to allow Registry
    modifier isRegistry() {
        require(msg.sender == HELIX2.getRegistry()[0], "NOT_REGISTRY");
        _;
    }

    /// @dev : ERC721 events
    error CannotBurn();
    error ERC721IncompatibleReceiver(address to);
    error Unauthorized(address operator, address owner, uint256 tokenID);
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenID
    );
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed tokenID
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev : returns owner of a token ID
     * @param tokenID : token ID
     */
    function ownerOf(uint256 tokenID) public view returns (address) {
        bytes32 _namehash = bytes32(tokenID);
        require(block.timestamp < NAMES.expiry(_namehash), "INVALID_TOKENID");
        address _owner = NAMES.owner(_namehash);
        return _owner;
    }

    /**
     * @dev : returns token balance of a wallet
     * @param wallet : wallet address
     */
    function balanceOf(address wallet) public view returns (uint256) {
        return _balanceOf[wallet];
    }

    /**
     * @dev : updates the balance of wallet by 1
     * @param wallet : wallet address
     * @param balance : new balance
     */
    function setBalance(address wallet, uint256 balance) external isRegistry {
        _balanceOf[wallet] = balance;
    }

    /**
     * @dev : sets Controller for one token
     * @param operator : operator address to be set as Controller
     * @param tokenID : token ID
     */
    function approve(address operator, uint256 tokenID) external {
        bytes32 _namehash = bytes32(tokenID);
        require(block.timestamp < NAMES.expiry(_namehash), "INVALID_TOKENID");
        address _owner = NAMES.owner(_namehash);
        address _controller = NAMES.controller(_namehash);
        if (
            msg.sender != _owner &&
            msg.sender != _controller &&
            !isApprovedForAll[_owner][msg.sender]
        ) {
            revert Unauthorized(msg.sender, _owner, tokenID);
        }
        NAMES.setControllerERC721(bytes32(tokenID), operator); // change operator record in Registry
        emit Approval(msg.sender, operator, tokenID);
    }

    /**
     * @dev : sets Controller (for an owner)
     * @param operator : operator address to be set as Controller
     * @param flag : bool to set
     */
    function setApprovalForAll(address operator, bool flag) external {
        isApprovedForAll[msg.sender][operator] = flag;
        emit ApprovalForAll(msg.sender, operator, flag);
    }

    /**
     * @dev : transferFrom() function
     * @param from : from address
     * @param to : to address
     * @param tokenID : token
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenID
    ) external {
        _transfer(from, to, tokenID, ""); // standard fallback
    }

    /**
     * @dev : safeTransferFrom() function
     * @param from : from address
     * @param to : to address
     * @param tokenID : token
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenID
    ) external {
        _transfer(from, to, tokenID, ""); // standard fallback
    }

    /**
     * @dev : safeTransferFrom() function with extra data
     * @param from : from address
     * @param to : to address
     * @param tokenID : token
     * @param data : extra data
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenID,
        bytes memory data
    ) external {
        _transfer(from, to, tokenID, data);
    }

    /**
     * @dev : custom _transfer() function that also mints
     * @param from : address of sender
     * @param to : address of receiver
     * @param tokenID : token
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenID,
        bytes memory data
    ) internal {
        bytes32 _namehash = bytes32(tokenID);
        require(block.timestamp < NAMES.expiry(_namehash), "INVALID_TOKENID");
        address _owner = NAMES.owner(_namehash);
        // cannot burn
        if (to == address(0)) {
            revert CannotBurn();
        }
        // check ownership of <from>
        if (_owner != from) {
            revert Unauthorized(_owner, from, tokenID);
        }
        // check permissions of <sender>
        if (msg.sender != _owner) {
            revert Unauthorized(msg.sender, from, tokenID);
        }
        NAMES.setOwnerERC721(bytes32(tokenID), to); // change ownership record in registry
        unchecked {
            // update balances
            _balanceOf[from]--;
            _balanceOf[to]++;
        }
        emit Transfer(from, to, tokenID);
        if (to.code.length > 0) {
            try
                iERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenID,
                    data
                )
            returns (bytes4 retval) {
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
