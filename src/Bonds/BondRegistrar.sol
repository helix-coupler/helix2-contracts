//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/Names/iName.sol";
import "src/Bonds/iBond.sol";
import "src/Interface/iHelix2.sol";
import "src/Utils/LibString.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Bond Registrar
 */
contract Helix2BondRegistrar {
    using LibString for address[];
    using LibString for address;
    using LibString for string[];
    using LibString for string;

    /// Dev
    address public Dev;

    /// @dev : Contract metadata
    string public constant bond = "Helix2 Bond Service";
    string public constant symbol = "HBS";

    /// @dev : Helix2 Bond events
    event NewBond(bytes32 indexed bondhash, bytes32 cation);
    event NewDev(address Dev, address newDev);
    error OnlyDev(address _dev, address _you);

    /// Constants
    mapping(address => mapping(address => bool)) Operators;
    uint256 public defaultLifespan; // default registration duration: 90 days
    uint256 public basePrice; // default base price
    uint256 public sizeLimit; // name length limit
    string[4] public illegalBlocks; // illegal blocks

    /// Interfaces
    iHELIX2 public HELIX2;
    iNAME public NAMES;
    iBOND public BONDS;

    /// @dev : Default resolver used by this contract
    address public defaultResolver;

    /// @dev : Pause/Resume contract
    bool public active = true;

    /// @dev : Modifier to allow only dev
    modifier onlyDev() {
        if (msg.sender != Dev) {
            revert OnlyDev(Dev, msg.sender);
        }
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

    /**
     * @dev : Initialise a new HELIX2 Bonds Registrar
     * @notice : constructor notes
     * @param _helix2 : address of HELIX2 Manager
     * @param _registry : address of HELIX2 Name Registry
     * @param __registry : address of HELIX2 Bond Registry
     */
    constructor(address __registry, address _registry, address _helix2) {
        HELIX2 = iHELIX2(_helix2);
        NAMES = iNAME(_registry);
        BONDS = iBOND(__registry);
        basePrice = HELIX2.getPrices()[1];
        sizeLimit = HELIX2.getSizes()[1];
        defaultLifespan = HELIX2.getLifespans()[1];
        illegalBlocks = HELIX2.getIllegalBlocks();
        Dev = msg.sender;
    }

    /**
     * @dev : verify alias has legal form
     * @param _alias : alias of bond
     */
    modifier isLegal(string memory _alias) {
        require(bytes(_alias).length < sizeLimit, "ILLEGAL_LABEL"); /// check for oversized label <<< SIZE LIMIT
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
        bytes32 roothash = HELIX2.getRoothash()[1];
        bytes32 bondhash = keccak256(
            abi.encodePacked(cation, roothash, aliashash)
        );
        BONDS.setCation(bondhash, cation); /// set new cation (= from)
        BONDS.setAnion(bondhash, anion); /// set anion (= to)
        BONDS.setExpiry(bondhash, block.timestamp + lifespan); /// set new expiry
        BONDS.setController(bondhash, _cation); /// set new controller
        BONDS.setResolver(bondhash, defaultResolver); /// set new resolver
        BONDS.setAlias(bondhash, aliashash); /// set new alias
        BONDS.setCovalence(bondhash, false); /// set new covalence flag
        BONDS.unhookAll(bondhash); /// reset hooks
        emit NewBond(bondhash, cation);
        return bondhash;
    }
}
