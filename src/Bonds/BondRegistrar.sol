//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/Names/iName.sol";
import "src/Bonds/iBond.sol";
import "src/Interface/iHelix2.sol";
import "src/Interface/iERC173.sol";
import "src/Oracle/iPriceOracle.sol";
import "src/Utils/LibString.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @notice GitHub: https://github.com/helix-coupler/helix2-contracts
 * @notice README: https://github.com/helix-coupler/resources
 * @dev testnet v0.0.1
 * @title Helix2 Bond Registrar
 */
contract Helix2BondRegistrar {
    using LibString for address[];
    using LibString for address;
    using LibString for string[];
    using LibString for string;
    using LibString for uint256;

    /// Dev
    address public Dev;

    /// @dev : Contract metadata
    string public constant bond = "Helix2 Bond Service";
    string public constant symbol = "HBS";

    /// @dev : Helix2 Bond events
    event NewBond(string label, bytes32 indexed bondhash, bytes32 cation);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    error OnlyDev(address _dev, address _you);

    /// Constants
    mapping(address => mapping(address => bool)) Operators;
    uint256 public defaultLifespan; // default registration duration: 90 days
    uint256 public basePrice; // default base price
    uint256[2] public sizeLimit; // name length limit
    bytes32 public roothash; // roothash
    string[4] public illegalBlocks; // illegal blocks

    /// Price Oracle
    iPriceOracle public PRICES;

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
     * @dev pauses or resumes contract
     */
    function toggleActive() external onlyDev {
        active = !active;
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
     * @dev Initialise a new HELIX2 Bonds Registrar
     * @notice
     * @param _helix2 : address of HELIX2 Manager
     * @param _registry : address of HELIX2 Name Registry
     * @param __registry : address of HELIX2 Bond Registry
     */
    constructor(
        address __registry,
        address _registry,
        address _helix2,
        address _priceOracle
    ) {
        HELIX2 = iHELIX2(_helix2);
        NAMES = iNAME(_registry);
        BONDS = iBOND(__registry);
        PRICES = iPriceOracle(_priceOracle);
        basePrice = PRICES.getPrices()[1];
        sizeLimit = HELIX2.getSizes()[1];
        defaultLifespan = HELIX2.getLifespans()[1];
        illegalBlocks = HELIX2.getIllegalBlocks();
        roothash = HELIX2.getRoothash()[1];
        Dev = msg.sender;
    }

    /**
     * @dev verify label has legal form
     * @param label : label of bond
     */
    modifier isLegal(string memory label) {
        require(
            label.strlen() > sizeLimit[0] && label.strlen() < sizeLimit[1],
            "ILLEGAL_LABEL"
        ); /// check for undersized or oversized label
        require(!label.existsIn(illegalBlocks), "ILLEGAL_CHARS"); /// check for forbidden characters
        _;
    }

    /**
     * @dev sets Default Resolver
     * @param _resolver : resolver address
     */
    function setDefaultResolver(address _resolver) external onlyDev {
        defaultResolver = _resolver;
    }

    /**
     * @dev sets Default Lifespan
     * @param _lifespan : new default value
     */
    function setDefaultLifespan(uint _lifespan) external onlyDev {
        defaultLifespan = _lifespan;
    }

    /**
     * @dev registers a new bond
     * @param label : label for the bond
     * @param cation : cation to set for new bond
     * @param anion : anion to set for new bond
     * @param lifespan : duration of registration
     * @return hash of new bond
     */
    function newBond(
        string memory label,
        bytes32 cation,
        bytes32 anion,
        uint lifespan
    ) external payable isLegal(label) returns (bytes32) {
        address _cation = NAMES.owner(cation);
        require(lifespan >= defaultLifespan, "LIFESPAN_TOO_SHORT");
        require(msg.value >= basePrice * lifespan, "INSUFFICIENT_ETHER");
        bytes32 labelhash = keccak256(abi.encodePacked(label));
        bytes32 bondhash = keccak256(
            abi.encodePacked(cation, roothash, labelhash)
        );
        /// @notice : availability is checked inline (not as modifier) to avoid deep stack
        require(!BONDS.recordExists(bondhash), "BOND_EXISTS");
        BONDS.register(bondhash, cation); /// set new cation (= from)
        BONDS.setAnion(bondhash, anion); /// set anion (= to)
        BONDS.setExpiry(bondhash, block.timestamp + lifespan); /// set new expiry
        BONDS.setController(bondhash, _cation); /// set new controller
        BONDS.setResolver(bondhash, defaultResolver); /// set new resolver
        BONDS.setLabel(bondhash, labelhash); /// set new label
        BONDS.setCovalence(bondhash, false); /// set new covalence flag
        BONDS.unhookAll(bondhash); /// reset hooks
        emit NewBond(label, bondhash, cation);
        return bondhash;
    }
}
