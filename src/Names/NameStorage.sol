//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/Interface/iERC173.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @notice GitHub: https://github.com/helix-coupler/helix2-contracts
 * @notice README: https://github.com/helix-coupler/resources
 * @dev testnet v0.0.1
 * @title Helix2 Name Storage
 */
contract Helix2NameStorage {
    /// @dev : Helix2 Name events
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// Dev
    address public Dev;
    /// Registry
    address public Registry;

    /// @dev : Pause/Resume contract
    bool public active = true;

    /// @dev : Helix2 Name struct
    struct Name {
        string _label; /// Label of Name
        address _owner; /// Owner of Name
        address _resolver; /// Resolver of Name
        address _controller; /// Controller of Name
        uint _expiry; /// Expiry of Name
    }
    mapping(bytes32 => Name) public Names;
    mapping(address => mapping(address => bool)) Operators;

    /**
     * @dev sets permissions for 0x0
     * @notice
     */
    function catalyse() internal onlyDev {}

    /**
     * @dev Initialise a new HELIX2 Names Storage
     * @notice
     * @param _registry : address of HELIX2 Name Registry
     */
    constructor(address _registry) {
        Registry = _registry;
        Dev = msg.sender;
        /// give ownership of '0x0' to Dev
        catalyse();
    }

    /// @dev : Modifier to allow only dev
    modifier onlyDev() {
        require(msg.sender == Dev, "NOT_DEV");
        _;
    }

    /// @dev : Modifier to allow only parent registry
    modifier onlyRegistry() {
        require(msg.sender == Registry, "NOT_ALLOWED");
        _;
    }

    /**
     * @dev check if name is already registered
     * @param namehash : hash of name
     */
    modifier isOwned(bytes32 namehash) {
        require(block.timestamp < Names[namehash]._expiry, "NAME_EXPIRED");
        _;
    }

    /**
     * @dev pauses or resumes contract
     */
    function toggleActive() external onlyDev {
        active = !active;
    }

    /**
     * @dev sets config
     * @notice
     * @param _registry : address of new HELIX2 Name Registry
     */
    function setConfig(address _registry) external onlyDev {
        Registry = _registry;
    }

    /**
     * @dev get owner of contract
     * @return address of controlling dev or multi-sig wallet
     */
    function owner() external view returns (address) {
        return Dev;
    }

    /**
     * @dev transfer contract ownership to new Dev
     * @param newDev : new Dev
     */
    function transferOwnership(address newDev) external onlyDev {
        emit OwnershipTransferred(Dev, newDev);
        Dev = newDev;
    }

    /**
     * @dev set label of a name
     * @param namehash : hash of name
     * @param _label : label to set
     */
    function setLabel(
        bytes32 namehash,
        string calldata _label
    ) external onlyRegistry {
        Names[namehash]._label = _label;
    }

    /**
     * @dev set owner of a name
     * @param namehash : hash of name
     * @param _owner : new owner
     */
    function setOwner(bytes32 namehash, address _owner) external onlyRegistry {
        Names[namehash]._owner = _owner;
    }

    /**
     * @dev set controller of a name
     * @param namehash : hash of name
     * @param _controller : new controller
     */
    function setController(
        bytes32 namehash,
        address _controller
    ) external onlyRegistry {
        Names[namehash]._controller = _controller;
    }

    /**
     * @dev set resolver for a name
     * @param namehash : hash of name
     * @param _resolver : new resolver
     */
    function setResolver(
        bytes32 namehash,
        address _resolver
    ) external onlyRegistry {
        Names[namehash]._resolver = _resolver;
    }

    /**
     * @dev set expiry for a name
     * @param namehash : hash of name
     * @param _expiry : new expiry
     */
    function setExpiry(bytes32 namehash, uint _expiry) external onlyRegistry {
        Names[namehash]._expiry = _expiry;
    }

    /**
     * @dev sets Controller for all your tokens
     * @param caller : original caller
     * @param operator : operator address to be set as Controller
     * @param approved : bool to set
     */
    function setApprovalForAll(
        address caller,
        address operator,
        bool approved
    ) external onlyRegistry {
        Operators[caller][operator] = approved;
    }

    /**
     * @dev return owner of a name
     * @param namehash hash of name to query
     * @return address of owner
     */
    function owner(bytes32 namehash) public view returns (address) {
        address addr = Names[namehash]._owner;
        return addr;
    }

    /**
     * @dev return label of a name
     * @param namehash hash of name to query
     * @return label of name
     */
    function label(bytes32 namehash) public view returns (string memory) {
        string memory _label = Names[namehash]._label;
        return _label;
    }

    /**
     * @dev return controller of a name
     * @param namehash hash of name to query
     * @return address of controller
     */
    function controller(
        bytes32 namehash
    ) public view isOwned(namehash) returns (address) {
        address _controller = Names[namehash]._controller;
        return _controller;
    }

    /**
     * @dev return expiry of a name
     * @param namehash hash of name to query
     * @return expiry
     */
    function expiry(bytes32 namehash) public view returns (uint) {
        uint _expiry = Names[namehash]._expiry;
        return _expiry;
    }

    /**
     * @dev return resolver of a name
     * @param namehash hash of name to query
     * @return address of resolver
     */
    function resolver(
        bytes32 namehash
    ) public view isOwned(namehash) returns (address) {
        address _resolver = Names[namehash]._resolver;
        return _resolver;
    }

    /**
     * @dev check if an address is set as operator
     * @param _owner owner of name to query
     * @param operator operator to check
     * @return true or false
     */
    function isApprovedForAll(
        address _owner,
        address operator
    ) external view returns (bool) {
        return Operators[_owner][operator];
    }

    /**
     * @dev withdraw ether to Dev, anyone can trigger
     */
    function withdrawEther() external {
        (bool ok, ) = Dev.call{value: address(this).balance}("");
        require(ok, "ETH_TRANSFER_FAILED");
    }
}
