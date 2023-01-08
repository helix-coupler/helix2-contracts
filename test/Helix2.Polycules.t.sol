// SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "test/GenAddr.sol";
// Helix2 Manager Contract
import "src/Helix2.sol";
// Price Oracle
import "src/Oracle/PriceOracle.sol";
// Registrar
import "src/Names/NameRegistrar.sol";
import "src/Polycules/PolyculeRegistrar.sol";
// Registry
import "src/Names/NameRegistry.sol";
import "src/Polycules/PolyculeRegistry.sol";
// Storage
import "src/Names/NameStorage.sol";
import "src/Polycules/PolyculeStorage.sol";
// Resolver
import "src/Names/NameResolver.sol";
import "src/Polycules/PolyculeResolver.sol";
// Interface
import "src/Names/iName.sol";
import "src/Polycules/iPolycule.sol";
import "src/Names/iERC721.sol";
import "src/Names/iNameResolver.sol";
import "src/Polycules/iPolyculeResolver.sol";
import "src/Interface/iHelix2.sol";
import "src/Interface/iENS.sol";
import "src/Oracle/iPriceOracle.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Registrar and Registry Tests
 * @notice Tests functions of Helix2 Polycule Registrar and Polycule Registry
 */
contract Helix2PolyculesTest is Test {
    using GenAddr for address;

    HELIX2 public HELIX2_;
    NameResolver public NameResolver_;
    PolyculeResolver public PolyculeResolver_;
    // Registry
    Helix2NameRegistry public NAMES;
    Helix2PolyculeRegistry public POLYCULES;
    // Storage
    Helix2NameStorage public NAMESTORE;
    Helix2PolyculeStorage public POLYSTORE;
    // Registrar
    Helix2NameRegistrar public _NAME_;
    Helix2PolyculeRegistrar public _POLY_;
    // Price Oracle
    Helix2PriceOracle public PriceOracle;

    /// Constants
    address public deployer;
    uint256 public theEnd = 250_000_000_000_000_000; // roughly 80,000,000,000 years in the future
    uint256 public namePrice;
    uint256 public polyprice;
    bytes32 public roothash;
    address public defaultResolver;

    /// Global test variables
    address public pill = address(0xc0de4c0ca19e);
    string public black = "vitalik";
    address[3] public taker = [
        address(0xc0de4c0cac01a),
        address(0xc0de4c0cac01b),
        address(0xc0de4c0cac01c)
    ];
    address[2] public _taker_ = [
        address(0xc0de4c0cac01d),
        address(0xc0de4c0cac01e)
    ];
    string[3] public crook = ["virgil", "virgil_", "virgil__"];
    string[2] public _crook_ = ["virgil___", "virgil____"];
    address public faker = address(0xc0de4d1ccc555);
    string public brown = "nick";
    string public _label = "virgin";
    uint256 public lifespan = 50;
    uint8[] public rules = [
        uint8(uint256(404)),
        uint8(uint256(400)),
        uint8(uint256(500))
    ];
    uint8[] public _rules_ = [uint8(uint256(504)), uint8(uint256(401))];
    address[] public config = [
        address(0x0101010101010),
        address(0x0101010101011),
        address(0x0101010101012)
    ];
    address[] public _config_ = [
        address(0x0101010101013),
        address(0x0101010101014)
    ];
    bytes32 public cation;
    bytes32[] public anions;
    bytes32[] public _anions_;
    bytes32 public polyhash;
    bytes32 public fakehash;
    bytes32 public jokehash;
    uint256 public tokenID;

    constructor() {
        deployer = address(this);

        // HELIX2 ------------------------------------------------
        // deploy Helix2
        HELIX2_ = new HELIX2();
        // deploy Price Oracle
        PriceOracle = new Helix2PriceOracle();

        // NAMES -------------------------------------------------
        // deploy NameRegistry
        NAMES = new Helix2NameRegistry(address(HELIX2_), address(PriceOracle));
        address _NAMES = address(NAMES);
        // deploy NameStorage
        NAMESTORE = new Helix2NameStorage(_NAMES);
        // deploy NameRegistrar
        _NAME_ = new Helix2NameRegistrar(
            _NAMES,
            address(HELIX2_),
            address(PriceOracle)
        );

        // POLYCULES -------------------------------------------------
        // deploy PolyculeRegistry
        POLYCULES = new Helix2PolyculeRegistry(
            _NAMES,
            address(HELIX2_),
            address(PriceOracle)
        );
        address _POLYCULES = address(POLYCULES);
        // deploy PolyculeStorage
        POLYSTORE = new Helix2PolyculeStorage(_POLYCULES);
        // deploy PolyculeRegistrar
        _POLY_ = new Helix2PolyculeRegistrar(
            _POLYCULES,
            _NAMES,
            address(HELIX2_),
            address(PriceOracle)
        );

        // RESOLVERS ---------------------------------------------
        // deploy Name Resolver
        NameResolver_ = new NameResolver(address(HELIX2_));
        // deploy Polycule Resolver
        PolyculeResolver_ = new PolyculeResolver(address(HELIX2_));

        // remaining values
        namePrice = PriceOracle.getPrices()[0];
        polyprice = PriceOracle.getPrices()[3];
        HELIX2_.setRegistrar(0, address(_NAME_));
        HELIX2_.setRegistry(0, _NAMES);
        NAMES.setConfig(
            address(HELIX2_),
            address(PriceOracle),
            address(NAMESTORE)
        );
        HELIX2_.setRegistrar(3, address(_POLY_));
        HELIX2_.setRegistry(3, _POLYCULES);
        POLYCULES.setConfig(
            address(HELIX2_),
            address(PriceOracle),
            address(POLYSTORE)
        );
    }

    /// forge setup
    function setUp() public {}

    /// Register a polycule
    function testRegisterPolycule() public {
        // register (1 + n) names
        cation = _NAME_.newName{value: namePrice * lifespan}(
            black,
            pill,
            lifespan
        );
        for (uint i = 0; i < crook.length; i++) {
            anions.push(
                _NAME_.newName{value: namePrice * lifespan}(
                    crook[i],
                    taker[i],
                    lifespan
                )
            );
        }
        roothash = HELIX2_.getRoothash()[3];
        // expected hash of registered polycule
        bytes32 _polyhash = keccak256(
            abi.encodePacked(
                cation,
                roothash,
                keccak256(abi.encodePacked(_label))
            )
        );
        // register test polycule linking (1 + n) names
        polyhash = _POLY_.newPolycule{value: polyprice * lifespan}(
            _label,
            cation,
            anions,
            lifespan,
            config,
            rules
        );
        assertEq(polyhash, _polyhash);
        bytes32[] memory taker_ = POLYCULES.anions(polyhash);
        assertEq(taker.length, anions.length);
        assertEq(taker.length, taker_.length);
        (uint8[] memory rules__, address[] memory hooks__) = POLYCULES
            .hooksWithRules(polyhash);
        assertEq(taker.length, hooks__.length);
        assertEq(taker.length, rules__.length);
    }

    /// Register a polycule, let it expire, and verify records
    function testExpiration() public {
        // register (1 + n) names
        cation = _NAME_.newName{value: namePrice * lifespan}(
            black,
            pill,
            lifespan
        );
        for (uint i = 0; i < crook.length; i++) {
            anions.push(
                _NAME_.newName{value: namePrice * lifespan}(
                    crook[i],
                    taker[i],
                    lifespan
                )
            );
        }
        // register test polycule linking (1 + n) names
        polyhash = _POLY_.newPolycule{value: polyprice * lifespan}(
            _label,
            cation,
            anions,
            lifespan,
            config,
            rules
        );
        vm.warp(block.timestamp + 10);
        assertEq(POLYCULES.recordExists(polyhash), true);
        uint256 _expiry = POLYCULES.expiry(polyhash);
        vm.prank(pill);
        vm.deal(pill, polyprice * 10);
        vm.expectRevert(abi.encodePacked("BAD_EXPIRY"));
        POLYCULES.renew{value: polyprice * 10}(polyhash, 10);
        vm.prank(pill);
        vm.deal(pill, polyprice * 100);
        POLYCULES.renew{value: polyprice * 100}(polyhash, _expiry + 100);
        vm.prank(pill);
        POLYCULES.setController(polyhash, faker);
        vm.prank(pill);
        POLYCULES.setResolver(polyhash, faker);
        vm.warp(block.timestamp + 200);
        assertEq(POLYCULES.recordExists(polyhash), false);
    }

    /// Register a polycule and verify records
    function testVerifyRecords() public {
        // register (1 + n) names
        cation = _NAME_.newName{value: namePrice * lifespan}(
            black,
            pill,
            lifespan
        );
        for (uint i = 0; i < crook.length; i++) {
            anions.push(
                _NAME_.newName{value: namePrice * lifespan}(
                    crook[i],
                    taker[i],
                    lifespan
                )
            );
        }
        // register test polycule linking (1 + n) names
        polyhash = _POLY_.newPolycule{value: polyprice * lifespan}(
            _label,
            cation,
            anions,
            lifespan,
            config,
            rules
        );
        assertEq(NAMES.owner(POLYCULES.cation(polyhash)), pill);
        bytes32[] memory taker_ = POLYCULES.anions(polyhash);
        assertEq(taker.length, anions.length);
        assertEq(taker.length, taker_.length);
        for (uint i = 0; i < crook.length; i++) {
            assertEq(NAMES.owner(taker_[i]), taker[i]);
        }
        assertEq(POLYCULES.cation(polyhash), cation);
        for (uint i = 0; i < crook.length; i++) {
            assertEq(taker_[i], anions[i]);
        }
        assertEq(POLYCULES.controller(polyhash), pill);
        assertEq(POLYCULES.resolver(polyhash), defaultResolver);
        assertEq(POLYCULES.expiry(polyhash), block.timestamp + lifespan);
        (uint8[] memory rules_, address[] memory hooks_) = POLYCULES
            .hooksWithRules(polyhash);
        assertEq(hooks_.length, config.length);
        assertEq(rules_.length, rules.length);
    }

    /// Register a polycule and change cation
    function testCationCanChangeCation() public {
        // register (1 + n) names
        cation = _NAME_.newName{value: namePrice * lifespan}(
            black,
            pill,
            lifespan
        );
        for (uint i = 0; i < crook.length; i++) {
            anions.push(
                _NAME_.newName{value: namePrice * lifespan}(
                    crook[i],
                    taker[i],
                    lifespan
                )
            );
        }
        // register test polycule linking (1 + n) names
        polyhash = _POLY_.newPolycule{value: polyprice * lifespan}(
            _label,
            cation,
            anions,
            lifespan,
            config,
            rules
        );
        // register name to transfer to
        fakehash = _NAME_.newName{value: namePrice * (lifespan + 1)}(
            brown,
            faker,
            lifespan + 1
        );
        vm.prank(pill);
        POLYCULES.setCation(polyhash, fakehash);
        assertEq(NAMES.owner(POLYCULES.cation(polyhash)), faker);
    }

    /// Register a polycule and set new controller, and test controller's permissions
    function testCationOrControllerCanControl() public {
        // register (1 + n) names
        cation = _NAME_.newName{value: namePrice * lifespan}(
            black,
            pill,
            lifespan
        );
        for (uint i = 0; i < crook.length; i++) {
            anions.push(
                _NAME_.newName{value: namePrice * lifespan}(
                    crook[i],
                    taker[i],
                    lifespan
                )
            );
        }
        // register test polycule linking (1 + n) names
        polyhash = _POLY_.newPolycule{value: polyprice * lifespan}(
            _label,
            cation,
            anions,
            lifespan,
            config,
            rules
        );
        // register name to transfer to
        fakehash = _NAME_.newName{value: namePrice * (lifespan + 1)}(
            brown,
            faker,
            lifespan + 1
        );
        vm.prank(pill);
        POLYCULES.setResolver(polyhash, address(0));
        vm.prank(pill);
        POLYCULES.setCovalence(polyhash, false);
        vm.prank(pill);
        POLYCULES.setController(polyhash, faker);
        assertEq(POLYCULES.controller(polyhash), faker);
        vm.prank(faker);
        POLYCULES.setResolver(polyhash, address(0));
        assertEq(POLYCULES.resolver(polyhash), address(0));
        vm.prank(faker);
        vm.expectRevert(abi.encodePacked("NOT_OWNER"));
        POLYCULES.setCation(polyhash, fakehash);
    }

    /// Register a polycule and attempt to make unauthorised calls
    function testCannotMakeUnauthorisedCalls() public {
        // register (1 + n) names
        cation = _NAME_.newName{value: namePrice * lifespan}(
            black,
            pill,
            lifespan
        );
        for (uint i = 0; i < crook.length; i++) {
            anions.push(
                _NAME_.newName{value: namePrice * lifespan}(
                    crook[i],
                    taker[i],
                    lifespan
                )
            );
        }
        // register test polycule linking (1 + n) names
        polyhash = _POLY_.newPolycule{value: polyprice * lifespan}(
            _label,
            cation,
            anions,
            lifespan,
            config,
            rules
        );
        // register name to transfer to
        fakehash = _NAME_.newName{value: namePrice * (lifespan + 1)}(
            brown,
            faker,
            lifespan + 1
        );
        vm.prank(faker);
        vm.expectRevert(abi.encodePacked("NOT_OWNER"));
        POLYCULES.setCation(polyhash, fakehash);
        vm.expectRevert(abi.encodePacked("NOT_AUTHORISED"));
        POLYCULES.setResolver(polyhash, address(0));
        vm.expectRevert(abi.encodePacked("NOT_AUTHORISED"));
        POLYCULES.setController(polyhash, faker);
    }

    /// Register a polycule, let it expire, and then re-register it
    function testRegisterExpiredPolycule() public {
        // register (1 + n) names
        cation = _NAME_.newName{value: namePrice * lifespan}(
            black,
            pill,
            lifespan
        );
        for (uint i = 0; i < crook.length; i++) {
            anions.push(
                _NAME_.newName{value: namePrice * lifespan}(
                    crook[i],
                    taker[i],
                    lifespan
                )
            );
        }
        // register test polycule linking (1 + n) names
        polyhash = _POLY_.newPolycule{value: polyprice * lifespan}(
            _label,
            cation,
            anions,
            lifespan,
            config,
            rules
        );
        assertEq(POLYCULES.recordExists(polyhash), true);
        vm.warp(block.timestamp + 60);
        assertEq(POLYCULES.recordExists(polyhash), false);
        // register test polycule linking (1 + n) names
        polyhash = _POLY_.newPolycule{value: polyprice * lifespan}(
            _label,
            cation,
            anions,
            lifespan,
            config,
            rules
        );
        assertEq(POLYCULES.recordExists(polyhash), true);
    }

    /// Register a polycule and attempt to renew it
    function testOnlyCationOrControllerCanRenew() public {
        // register (1 + n) names
        cation = _NAME_.newName{value: namePrice * lifespan}(
            black,
            pill,
            lifespan
        );
        for (uint i = 0; i < crook.length; i++) {
            anions.push(
                _NAME_.newName{value: namePrice * lifespan}(
                    crook[i],
                    taker[i],
                    lifespan
                )
            );
        }
        // register test polycule linking (1 + n) names
        polyhash = _POLY_.newPolycule{value: polyprice * lifespan}(
            _label,
            cation,
            anions,
            lifespan,
            config,
            rules
        );
        assertEq(POLYCULES.recordExists(polyhash), true);
        uint256 _expiry = POLYCULES.expiry(polyhash);
        vm.prank(pill);
        vm.deal(pill, polyprice * lifespan);
        POLYCULES.renew{value: polyprice * lifespan}(
            polyhash,
            _expiry + lifespan
        );
        assertEq(POLYCULES.expiry(polyhash), _expiry + lifespan);
        vm.prank(pill);
        POLYCULES.setController(polyhash, faker);
        assertEq(POLYCULES.controller(polyhash), faker);
        _expiry = POLYCULES.expiry(polyhash);
        vm.prank(faker);
        vm.deal(faker, polyprice * lifespan);
        POLYCULES.renew{value: polyprice * lifespan}(
            polyhash,
            _expiry + lifespan
        );
        vm.warp(block.timestamp + 200);
        assertEq(POLYCULES.recordExists(polyhash), false);
        _expiry = POLYCULES.expiry(polyhash);
        vm.prank(faker);
        vm.deal(faker, polyprice * lifespan);
        vm.expectRevert(abi.encodePacked("POLYCULE_EXPIRED"));
        POLYCULES.renew{value: polyprice * lifespan}(
            polyhash,
            _expiry + lifespan
        );
    }

    /// Register a polycule and attempt to add & pop anions
    function testOnlyCationOrControllerCanChangeAnions() public {
        // register (1 + n) names
        cation = _NAME_.newName{value: namePrice * lifespan}(
            black,
            pill,
            lifespan
        );
        for (uint i = 0; i < crook.length; i++) {
            anions.push(
                _NAME_.newName{value: namePrice * lifespan}(
                    crook[i],
                    taker[i],
                    lifespan
                )
            );
        }
        for (uint i = 0; i < _crook_.length; i++) {
            _anions_.push(
                _NAME_.newName{value: namePrice * lifespan}(
                    _crook_[i],
                    _taker_[i],
                    lifespan
                )
            );
        }
        // register test polycule linking (1 + n) names
        polyhash = _POLY_.newPolycule{value: polyprice * lifespan}(
            _label,
            cation,
            anions,
            lifespan,
            config,
            rules
        );
        // register name to transfer to
        fakehash = _NAME_.newName{value: namePrice * (lifespan + 1)}(
            brown,
            faker,
            lifespan + 1
        );
        assertEq(POLYCULES.recordExists(polyhash), true);
        vm.prank(faker);
        vm.expectRevert(abi.encodePacked("NOT_OWNER_OR_CONTROLLER"));
        POLYCULES.addAnionWithConfig(
            polyhash,
            _anions_[0],
            _config_[0],
            _rules_[0]
        );
        vm.prank(pill);
        POLYCULES.addAnionWithConfig(
            polyhash,
            _anions_[0],
            _config_[0],
            _rules_[0]
        );
        assertEq(POLYCULES.anions(polyhash).length, anions.length + 1);
        vm.prank(pill);
        POLYCULES.popAnion(polyhash, _anions_[0]);
        assertEq(POLYCULES.anions(polyhash).length, anions.length + 1);
        vm.prank(pill);
        POLYCULES.setAnions(polyhash, _anions_, _config_, _rules_);
        assertEq(
            POLYCULES.anions(polyhash).length - 1,
            anions.length + _anions_.length
        );
    }

    /// Register a polycule and attempt to add a hook
    function testOnlyCationOrControllerCanHook() public {
        // register (1 + n) names
        cation = _NAME_.newName{value: namePrice * lifespan}(
            black,
            pill,
            lifespan
        );
        for (uint i = 0; i < crook.length; i++) {
            anions.push(
                _NAME_.newName{value: namePrice * lifespan}(
                    crook[i],
                    taker[i],
                    lifespan
                )
            );
        }
        for (uint i = 0; i < _crook_.length; i++) {
            _anions_.push(
                _NAME_.newName{value: namePrice * lifespan}(
                    _crook_[i],
                    _taker_[i],
                    lifespan
                )
            );
        }
        // register test polycule linking (1 + n) names
        polyhash = _POLY_.newPolycule{value: polyprice * lifespan}(
            _label,
            cation,
            anions,
            lifespan,
            config,
            rules
        );
        // register name to transfer to
        fakehash = _NAME_.newName{value: namePrice * (lifespan + 1)}(
            brown,
            faker,
            lifespan + 1
        );
        assertEq(POLYCULES.recordExists(polyhash), true);
        vm.prank(pill);
        POLYCULES.hook(_anions_[0], polyhash, _config_[0], _rules_[0]);
        (uint8[] memory rules_, address[] memory hooks_) = POLYCULES
            .hooksWithRules(polyhash);
        assertEq(_config_[0], hooks_[config.length]);
        assertEq(_rules_[0], rules_[rules.length]);
        vm.prank(pill);
        POLYCULES.setController(polyhash, faker);
        vm.prank(faker);
        vm.expectRevert(abi.encodePacked("ANION_OR_RULE_EXISTS"));
        POLYCULES.hook(_anions_[0], polyhash, _config_[0], _rules_[0]);
        vm.prank(faker);
        vm.expectRevert(abi.encodePacked("ANION_OR_RULE_EXISTS"));
        POLYCULES.hook(anions[0], polyhash, _config_[0], _rules_[0]);
        vm.prank(faker);
        POLYCULES.hook(_anions_[1], polyhash, _config_[1], _rules_[1]);
        (uint8[] memory rules__, address[] memory hooks__) = POLYCULES
            .hooksWithRules(polyhash);
        assertEq(_config_[1], hooks__[config.length + 1]);
        assertEq(_rules_[1], rules__[rules.length + 1]);
    }

    /// Register a polycule and attempt to rehook a hook to new _rules_[0]
    function testOnlyCationOrControllerCanRehook() public {
        // register (1 + n) names
        cation = _NAME_.newName{value: namePrice * lifespan}(
            black,
            pill,
            lifespan
        );
        for (uint i = 0; i < crook.length; i++) {
            anions.push(
                _NAME_.newName{value: namePrice * lifespan}(
                    crook[i],
                    taker[i],
                    lifespan
                )
            );
        }
        for (uint i = 0; i < _crook_.length; i++) {
            _anions_.push(
                _NAME_.newName{value: namePrice * lifespan}(
                    _crook_[i],
                    _taker_[i],
                    lifespan
                )
            );
        }
        // register test polycule linking (1 + n) names
        polyhash = _POLY_.newPolycule{value: polyprice * lifespan}(
            _label,
            cation,
            anions,
            lifespan,
            config,
            rules
        );
        // register name to transfer to
        fakehash = _NAME_.newName{value: namePrice * (lifespan + 1)}(
            brown,
            faker,
            lifespan + 1
        );
        assertEq(POLYCULES.recordExists(polyhash), true);
        vm.prank(pill);
        POLYCULES.hook(_anions_[0], polyhash, _config_[0], _rules_[0]);
        vm.prank(pill);
        POLYCULES.rehook(polyhash, _config_[1], _rules_[0]);
        (uint8[] memory rules_, address[] memory hooks_) = POLYCULES
            .hooksWithRules(polyhash);
        assertEq(_config_[1], hooks_[anions.length]);
        assertEq(_rules_[0], rules_[anions.length]);
        vm.prank(pill);
        POLYCULES.setController(polyhash, faker);
        vm.prank(faker);
        vm.expectRevert(abi.encodePacked("ANION_OR_RULE_EXISTS"));
        POLYCULES.hook(_anions_[0], polyhash, _config_[0], _rules_[0]);
        vm.prank(faker);
        vm.expectRevert(abi.encodePacked("ANION_OR_RULE_EXISTS"));
        POLYCULES.hook(_anions_[0], polyhash, _config_[0], _rules_[0]);
        vm.prank(faker);
        POLYCULES.rehook(polyhash, _config_[0], _rules_[0]);
        (uint8[] memory rules__, address[] memory hooks__) = POLYCULES
            .hooksWithRules(polyhash);
        assertEq(_config_[0], hooks__[anions.length]);
        assertEq(_rules_[0], rules__[anions.length]);
    }

    /// Register a polycule and attempt to unhook a hook
    function testOnlyCationOrControllerCanUnhook() public {
        // register (1 + n) names
        cation = _NAME_.newName{value: namePrice * lifespan}(
            black,
            pill,
            lifespan
        );
        for (uint i = 0; i < crook.length; i++) {
            anions.push(
                _NAME_.newName{value: namePrice * lifespan}(
                    crook[i],
                    taker[i],
                    lifespan
                )
            );
        }
        for (uint i = 0; i < _crook_.length; i++) {
            _anions_.push(
                _NAME_.newName{value: namePrice * lifespan}(
                    _crook_[i],
                    _taker_[i],
                    lifespan
                )
            );
        }
        // register test polycule linking (1 + n) names
        polyhash = _POLY_.newPolycule{value: polyprice * lifespan}(
            _label,
            cation,
            anions,
            lifespan,
            config,
            rules
        );
        // register name to transfer to
        fakehash = _NAME_.newName{value: namePrice * (lifespan + 1)}(
            brown,
            faker,
            lifespan + 1
        );
        assertEq(POLYCULES.recordExists(polyhash), true);
        vm.prank(pill);
        POLYCULES.hook(_anions_[0], polyhash, _config_[0], _rules_[0]);
        vm.prank(pill);
        POLYCULES.unhook(polyhash, _rules_[0]);
        (uint8[] memory rules_, address[] memory hooks_) = POLYCULES
            .hooksWithRules(polyhash);
        assertEq(hooks_.length, anions.length + 1);
        assertEq(rules_.length, anions.length + 1);
        vm.prank(pill);
        POLYCULES.setController(polyhash, faker);
        vm.prank(faker);
        vm.expectRevert(
            abi.encodeWithSelector(Helix2PolyculeRegistry.BAD_HOOK.selector)
        );
        POLYCULES.unhook(polyhash, _rules_[0]);
        vm.prank(faker);
        POLYCULES.hook(_anions_[0], polyhash, _config_[1], _rules_[1]);
        (uint8[] memory rules__, address[] memory hooks__) = POLYCULES
            .hooksWithRules(polyhash);
        assertEq(_config_[1], hooks__[anions.length + 1]);
        assertEq(_rules_[1], rules__[anions.length + 1]);
        assertEq(rules__.length, anions.length + 2);
        assertEq(hooks__.length, anions.length + 2);
    }
}
