//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/ERC721.sol";
import "src/Interface/iPolycule.sol";
import "src/Utils/LibString.sol";
import "src/Interface/iName.sol";
import "src/Interface/iHelix2.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Polycule Base
 */
contract PolyculeRegistrar is ERC721 {
    using LibString for bytes32[];
    using LibString for bytes32;
    using LibString for address[];
    using LibString for address;
    using LibString for string[];
    using LibString for string;

    /// @dev : Contract metadata
    string public constant polycule = "Helix2 Polycule Service";
    string public constant symbol = "HPS";

    /// @dev : Helix2 Polycule events
    event NewPolycule(bytes32 indexed polyhash, bytes32 cation);
    event NewCation(bytes32 indexed polyhash, bytes32 cation);
    event NewExpiry(bytes32 indexed polyhash, uint expiry);
    event NewRecord(bytes32 indexed polyhash, address resolver);
    event NewResolver(bytes32 indexed polyhash, address resolver);
    event NewController(bytes32 indexed polyhash, address controller);

    /// Constants
    mapping(address => mapping(address => bool)) Operators;
    uint256 public defaultLifespan = 7_776_000_000; // default registration duration: 90 days
    uint256 public basePrice; // default base price

    /// Name Registry
    iNAME public NAMES;
    /// Molecule Registry
    iPOLYCULE public POLYCULES;
    /// HELIX2 Manager
    iHELIX2 public HELIX2;

    /// @dev : Default resolver used by this contract
    address public defaultResolver;

    /**
     * @dev : Initialise a new HELIX2 Polycules Registrar
     * @notice : constructor notes
     * @param _helix2 : address of HELIX2 Manager
     * @param _registry : address of HELIX2 Name Registry
     * @param __registry : address of HELIX2 Polycule Registry
     */
    constructor(address __registry, address _registry, address _helix2) {
        HELIX2 = iHELIX2(_helix2);
        NAMES = iNAME(_registry);
        POLYCULES = iPOLYCULE(__registry);
        basePrice = HELIX2.getPrices()[3];
        Dev = msg.sender;
    }

    /**
     * @dev : verify alias has legal form
     * @param _alias : alias of polycule
     */
    modifier isLegal(string memory _alias) {
        require(bytes(_alias).length < sizes[1], "ILLEGAL_LABEL"); /// check for oversized label <<< SIZE LIMIT
        require(!_alias.existsIn4(illegalBlocks), "ILLEGAL_CHARS"); /// check for forbidden characters
        _;
    }

    /**
     * @dev : verify if each anion has a hook
     * @param _anion : array of anions
     * @param _config : array of config addresses
     */
    modifier isLegalMap(bytes32[] memory _anion, address[] memory _config) {
        require(_anion.length == _config.length, "BAD_MAP");
        _;
    }

    /**
     * @dev : verify ownership of polycule
     * @param polyhash : hash of polycule
     */
    modifier onlyCation(bytes32 polyhash) {
        require(
            block.timestamp < POLYCULES.expiry(polyhash),
            "POLYCULE_EXPIRED"
        ); // expiry check
        address cation = NAMES.owner(POLYCULES.cation(polyhash));
        require(
            cation == msg.sender || Operators[cation][msg.sender],
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
     * @dev registers a new polycule
     * @param _alias : alias of polycule without suffix
     * @param cation : cation to set for new polycule
     * @param anion : array of target anions
     * @param lifespan : duration of registration
     * @param config : array of contract config addresses
     * @param rules : rules for hooks
     * @return hash of new polycule
     */
    function newPolycule(
        string memory _alias,
        bytes32 cation,
        bytes32[] memory anion,
        uint lifespan,
        address[] memory config,
        uint8[] memory rules
    )
        external
        payable
        isLegal(_alias)
        isLegalMap(anion, config)
        returns (bytes32)
    {
        address _cation = NAMES.owner(cation);
        require(lifespan >= defaultLifespan, "LIFESPAN_TOO_SHORT");
        require(msg.value >= basePrice * lifespan, "INSUFFICIENT_ETHER");
        bytes32 aliashash = keccak256(abi.encodePacked(_alias));
        bytes32 polyhash = keccak256(
            abi.encodePacked(cation, roothash[3], aliashash)
        );
        POLYCULES.setCation(polyhash, cation); /// set new cation (= from)
        POLYCULES.setAnions(polyhash, anion, config, rules); /// set anions (= to)
        POLYCULES.setExpiry(polyhash, block.timestamp + lifespan); /// set new expiry
        POLYCULES.setController(polyhash, _cation); /// set new controller
        POLYCULES.setResolver(polyhash, defaultResolver); /// set new resolver
        POLYCULES.setAlias(polyhash, aliashash); /// set new alias
        _ownerOf[uint256(polyhash)] = _cation; /// change ownership record
        unchecked {
            /// update balances
            _balanceOf[_cation]++;
        }
        emit NewPolycule(polyhash, cation);
        return polyhash;
    }
}
