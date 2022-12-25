//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/ERC721.sol";
import "src/Interface/iBond.sol";
import "src/Utils/LibString.sol";
import "src/Interface/iName.sol";
import "src/Interface/iHelix2.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Bond Base
 */
contract BondRegistrar is ERC721 {
    using LibString for address[];
    using LibString for address;
    using LibString for string[];
    using LibString for string;

    iHELIX2 public HELIX2 = iHELIX2(address(0x0));
    iNAME public NAMES = iNAME(HELIX2.getRegistry()[1]);

    /// @dev : Contract metadata
    string public constant bond = "Helix2 Bond Service";
    string public constant symbol = "HBS";

    /// @dev : Helix2 Bond events
    event NewBond(bytes32 indexed bondhash, bytes32 cation);
    event NewCation(bytes32 indexed bondhash, bytes32 cation);
    event NewExpiry(bytes32 indexed bondhash, uint expiry);
    event NewRecord(bytes32 indexed bondhash, address resolver);
    event NewResolver(bytes32 indexed bondhash, address resolver);
    event NewController(bytes32 indexed bondhash, address controller);

    /// Constants
    mapping(address => mapping(address => bool)) Operators;
    uint256 public defaultLifespan = 7_776_000_000; // default registration duration: 90 days
    uint256 public basePrice = HELIX2.getPrices()[1]; // default base price

    /// Bond Registry
    iBOND public BONDS = iBOND(address(0x0));

    /// @dev : Default resolver used by this contract
    address public defaultResolver;

    constructor(address _registry) {
        BONDS = iBOND(_registry);
        Dev = msg.sender;
    }

    /**
     * @dev : verify alias has legal form
     * @param _alias : alias of bond
     */
    modifier isLegal(string memory _alias) {
        require(bytes(_alias).length < sizes[1], "ILLEGAL_LABEL"); /// check for oversized label <<< SIZE LIMIT
        require(!_alias.existsIn4(illegalBlocks), "ILLEGAL_CHARS"); /// check for forbidden characters
        _;
    }

    /**
     * @dev : verify ownership of bond
     * @param bondhash : hash of bond
     */
    modifier onlyCation(bytes32 bondhash) {
        require(block.timestamp < BONDS.expiry(bondhash), "BOND_EXPIRED"); // expiry check
        address owner = NAMES.owner(BONDS.cation(bondhash));
        require(
            owner == msg.sender || Operators[owner][msg.sender],
            "NOT_OWNER"
        );
        _;
    }

    /**
     * @dev : sets Default Resolver
     * @param _resolver : resolver address
     */
    function setDefaultResolver(address _resolver) external onlyDev {
        defaultResolver = _resolver;
    }

    /**
     * @dev : sets Default Lifespan
     * @param _lifespan : new default value
     */
    function setDefaultLifespan(uint _lifespan) external onlyDev {
        defaultLifespan = _lifespan;
    }

    /**
     * @dev registers a new bond
     * @param _alias : alias for the bond
     * @param cation : cation to set for new bond
     * @param anion : anion to set for new bond
     * @param lifespan : duration of registration
     * @return hash of new bond
     */
    function newBond(
        string memory _alias,
        bytes32 cation,
        bytes32 anion,
        uint lifespan
    ) external payable isLegal(_alias) returns (bytes32) {
        address _cation = NAMES.owner(cation);
        require(lifespan >= defaultLifespan, "LIFESPAN_TOO_SHORT");
        require(msg.value >= basePrice * lifespan, "INSUFFICIENT_ETHER");
        bytes32 aliashash = keccak256(abi.encodePacked(_alias));
        bytes32 bondhash = keccak256(
            abi.encodePacked(cation, roothash[1], aliashash)
        );
        BONDS.setCation(bondhash, cation); /// set new cation (= from)
        BONDS.setAnion(bondhash, anion); /// set anion (= to)
        BONDS.setExpiry(bondhash, block.timestamp + lifespan); /// set new expiry
        BONDS.setController(bondhash, _cation); /// set new controller
        BONDS.setResolver(bondhash, defaultResolver); /// set new resolver
        BONDS.setAlias(bondhash, aliashash); /// set new alias
        BONDS.setSecure(bondhash, false); /// set new secure flag
        BONDS.unhookAll(bondhash); /// reset hooks
        _ownerOf[uint256(bondhash)] = _cation; /// change ownership record
        unchecked {
            /// update balances
            _balanceOf[_cation]++;
        }
        emit NewBond(bondhash, cation);
        return bondhash;
    }
}
