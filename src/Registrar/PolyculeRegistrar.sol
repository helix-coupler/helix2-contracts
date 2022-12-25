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

    iHELIX2 public HELIX2 = iHELIX2(address(0x0));
    iNAME public NAMES = iNAME(HELIX2.getRegistry()[3]);

    /// @dev : Contract metadata
    string public constant polycule = "Helix2 Polycule Service";
    string public constant symbol = "HMS";

    /// @dev : Helix2 Polycule events
    event NewPolycule(bytes32 indexed polyculehash, bytes32 cation);
    event NewCation(bytes32 indexed polyculehash, bytes32 cation);
    event NewExpiry(bytes32 indexed polyculehash, uint expiry);
    event NewRecord(bytes32 indexed polyculehash, address resolver);
    event NewResolver(bytes32 indexed polyculehash, address resolver);
    event NewController(bytes32 indexed polyculehash, address controller);

    /// Constants
    mapping (address => mapping(address => bool)) Operators;
    uint256 public defaultLifespan = 7_776_000_000;    // default registration duration: 90 days
    uint256 public basePrice = HELIX2.getPrices()[3];  // default base price

    /// Polycule Registry
    iPOLYCULE public POLYCULES = iPOLYCULE(address(0x0));

    /// @dev : Default resolver used by this contract
    address public defaultResolver;

    constructor(address _registry) {
        POLYCULES = iPOLYCULE(_registry);
        Dev = msg.sender;
    }

    /**
     * @dev : verify alias has legal form
     * @param _alias : alias of polycule
     */
    modifier isLegal(string memory _alias) {
        require(
            bytes(_alias).length < sizes[1], 
            'ILLEGAL_LABEL'
        ); /// check for oversized label <<< SIZE LIMIT
        require(
            !_alias.existsIn4(illegalBlocks), 
            'ILLEGAL_CHARS'
        ); /// check for forbidden characters
        _;
    }

    /**
     * @dev : verify if each anion has a hook
     * @param _anion : array of anions
     * @param _config : array of config addresses
     */
    modifier isLegalMap(bytes32[] memory _anion, address[] memory _config) {
        require(
            _anion.length == _config.length, 
            'BAD_MAP'
        );
        _;
    }

    /**
     * @dev : verify ownership of polycule
     * @param polyculehash : hash of polycule
     */
    modifier onlyCation(bytes32 polyculehash) {
        require(
            block.timestamp < POLYCULES.expiry(polyculehash), 
            "POLYCULE_EXPIRED"
        ); // expiry check
        address cation = NAMES.owner(
            POLYCULES.cation(polyculehash)
        );
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
     * @param _alias : label of polycule without suffix (maxLength = 32)
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
    ) external 
      payable
      isLegal(_alias)
      isLegalMap(anion, config)
      returns(bytes32) 
    {
        address _cation = NAMES.owner(cation);
        require(lifespan >= defaultLifespan, 'LIFESPAN_TOO_SHORT');
        require(msg.value >= basePrice * lifespan, 'INSUFFICIENT_ETHER');
        bytes32 aliashash = keccak256(abi.encodePacked(_alias));
        bytes32 polyculehash = keccak256(
            abi.encodePacked(
                cation,
                roothash[3], 
                aliashash
            )
        );
        POLYCULES.setCation(polyculehash, cation);                       /// set new cation (= from)
        POLYCULES.setAnions(polyculehash, anion, config, rules);         /// set anions (= to)
        POLYCULES.setExpiry(polyculehash, block.timestamp + lifespan);   /// set new expiry
        POLYCULES.setController(polyculehash, _cation);                  /// set new controller
        POLYCULES.setResolver(polyculehash, defaultResolver);            /// set new resolver
        POLYCULES.setAlias(polyculehash, aliashash);                     /// set new alias
        _ownerOf[uint256(polyculehash)] = _cation;                       /// change ownership record
        unchecked {                                                      /// update balances
            _balanceOf[_cation]++;
        }
        emit NewPolycule(polyculehash, cation);
        return polyculehash;
    }

}
