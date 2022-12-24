//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/Interface/iName.sol";
import "src/Interface/iHelix2.sol";
import "src/Interface/iERC721.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Name Base
 */
abstract contract Helix2Names {

    iHELIX2 public HELIX2 = iHELIX2(address(0x0));

    /// @dev : Helix2 Name events
    event NewDev(address Dev, address newDev);
    event NewName(bytes32 indexed namehash, address owner);
    event NewOwner(bytes32 indexed namehash, address owner);
    event NewController(bytes32 indexed namehash, address controller);
    event NewExpiry(bytes32 indexed namehash, uint expiry);
    event NewRecord(bytes32 indexed namehash, address resolver);
    event NewResolver(bytes32 indexed namehash, address resolver);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /// Dev
    address public Dev;

    /// @dev : Name roothash
    bytes32 public roothash = HELIX2.getRoothash()[0];

    /// @dev : Helix2 Name struct
    struct Name {
        address _owner;         /// Owner of Name
        address _resolver;      /// Resolver of Name
        address _controller;    /// Controller of Name
        uint _expiry;           /// Expiry of Name
    }
    mapping (bytes32 => Name) public Names;
    mapping (address => mapping(address => bool)) Operators;

    /**
    * @dev : Initialise a new HELIX2 Names Registry
    * @notice : grants ownership of '0x0' to contract
    */
    constructor() {
        /// give ownership of '0x0' and <roothash> to Dev
        Names[0x0]._owner = msg.sender;
        Names[roothash]._owner = msg.sender;
        Dev = msg.sender;
    }

    /// @dev : Modifier to allow only dev
    modifier onlyDev() {
        require(msg.sender == Dev, "NOT_DEV");
        _;
    }

    /**
     * @dev : transfer contract ownership to new Dev
     * @param newDev : new Dev
     */
    function changeDev(address newDev) external onlyDev {
        emit NewDev(Dev, newDev);
        Dev = newDev;
    }

    /// @dev : Modifier to allow only Controller
    modifier onlyController(bytes32 namehash) {
        require(msg.sender == Names[namehash]._controller, 'NOT_CONTROLLER');
        _;
    }

    /// @dev : Modifier to allow Owner or Controller
    modifier isOwnerOrController(bytes32 namehash) {
        address _owner = Names[namehash]._owner;
        require(_owner == msg.sender || Operators[_owner][msg.sender] || msg.sender == Names[namehash]._controller, "NOT_OWNER_OR_CONTROLLER");
        _;
    }

    /**
     * @dev : verify name belongs to root
     * @param labelhash : hash of name
     */
    modifier isNew(bytes32 labelhash) {
        address _owner =  Names[keccak256(abi.encodePacked(roothash, labelhash))]._owner;
        require(_owner == address(0x0), "NAME_EXISTS");
        _;
    }

    /**
     * @dev : verify ownership of name
     * @param namehash : hash of name
     */
    modifier onlyOwner(bytes32 namehash) {
        address _owner = Names[namehash]._owner;
        require(_owner == msg.sender || Operators[_owner][msg.sender], "NOT_OWNER");
        _;
    }

    /**
     * @dev : set owner of a name
     * @param namehash : hash of name
     * @param _owner : new owner
     */
    function setOwner(bytes32 namehash, address _owner) external onlyOwner(namehash) {
        Names[namehash]._owner = _owner;
        emit NewOwner(namehash, _owner);
    }

    /**
     * @dev : set controller of a name
     * @param namehash : hash of name
     * @param _controller : new controller
     */
    function setController(bytes32 namehash, address _controller) external isOwnerOrController(namehash) {
        Names[namehash]._controller = _controller;
        emit NewController(namehash, _controller);
    }

    /**
     * @dev : set resolver for a name
     * @param namehash : hash of name
     * @param _resolver : new resolver
     */
    function setResolver(bytes32 namehash, address _resolver) external isOwnerOrController(namehash) {
        Names[namehash]._resolver = _resolver;
        emit NewResolver(namehash, _resolver);
    }

    /**
     * @dev : set expiry for a name
     * @param namehash : hash of name
     * @param _expiry : new expiry
     */
    function setExpiry(bytes32 namehash, uint _expiry) external isOwnerOrController(namehash) {
        Names[namehash]._expiry = _expiry;
        emit NewExpiry(namehash, _expiry);
    }

    /**
     * @dev : set record for a name
     * @param namehash : hash of name
     * @param _resolver : new record
     */
    function setRecord(bytes32 namehash, address _resolver) external isOwnerOrController(namehash) {
        Names[namehash]._resolver = _resolver;
        emit NewRecord(namehash, _resolver);
    }

    /**
     * @dev : set operator for a name
     * @param operator : new operator
     * @param approved : state to set
     */
    function setApprovalForAll(address operator, bool approved) external payable {
        Operators[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev return owner of a name
     * @param namehash hash of name to query
     * @return address of owner
     */
    function owner(bytes32 namehash) public view returns (address) {
        address addr = Names[namehash]._owner;
        if (addr == address(this)) {
            return address(0x0);
        }
        return addr;
    }

    /**
     * @dev return controller of a name
     * @param namehash hash of name to query
     * @return address of controller
     */
    function controller(bytes32 namehash) public view returns (address) {
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
    function resolver(bytes32 namehash) public view returns (address) {
        address _resolver = Names[namehash]._resolver;
        return _resolver;
    }

    /**
     * @dev check if a name is registered
     * @param namehash hash of name to query
     * @return true or false
     */
    function recordExists(bytes32 namehash) public view returns (bool) {
        return Names[namehash]._owner != address(0x0);
    }

    /**
     * @dev check if an address is set as operator
     * @param _owner owner of name to query
     * @param operator operator to check
     * @return true or false
     */
    function isApprovedForAll(address _owner, address operator) external view returns (bool) {
        return Operators[_owner][operator];
    }

    /**
     * @dev : withdraw ether to Dev, anyone can trigger
     */
    function withdrawEther() external payable {
        (bool ok,) = Dev.call{value: address(this).balance}("");
        require(ok, "ETH_TRANSFER_FAILED");
    }

    /**
     * @dev : to be used in case some tokens get locked in the contract
     * @param token : token to release
     */
    function withdrawToken(address token) external payable {
        iERC20(token).transferFrom(address(this), Dev, iERC20(token).balanceOf(address(this)));
    }
}
