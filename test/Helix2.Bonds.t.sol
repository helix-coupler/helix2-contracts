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
import "src/Bonds/BondRegistrar.sol";
// Registry
import "src/Names/NameRegistry.sol";
import "src/Bonds/BondRegistry.sol";
// Storage
import "src/Names/NameStorage.sol";
// Resolver
import "src/Names/NameResolver.sol";
import "src/Bonds/BondResolver.sol";
// Interface
import "src/Names/iName.sol";
import "src/Bonds/iBond.sol";
import "src/Names/iERC721.sol";
import "src/Names/iNameResolver.sol";
import "src/Bonds/iBondResolver.sol";
import "src/Interface/iHelix2.sol";
import "src/Interface/iENS.sol";
import "src/Oracle/iPriceOracle.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Registrar and Registry Tests
 * @notice Tests functions of Helix2 Bond Registrar and Bond Registry
 */
contract Helix2BondsTest is Test {
    using GenAddr for address;

    HELIX2 public HELIX2_;
    NameResolver public NameResolver_;
    BondResolver public BondResolver_;
    // Registry
    Helix2NameRegistry public NAMES;
    Helix2BondRegistry public BONDS;
    // Registrar
    Helix2NameRegistrar public _NAME_;
    Helix2BondRegistrar public _BOND_;
    // Storage
    Helix2NameStorage public NAMESTORE;
    // Price Oracle
    Helix2PriceOracle public PriceOracle;

    /// Constants
    address public deployer;
    uint256 public theEnd = 250_000_000_000_000_000; // roughly 80,000,000,000 years in the future
    uint256 public namePrice;
    uint256 public bondPrice;
    bytes32 public roothash;
    address public defaultResolver;

    /// Global test variables
    address public pill = address(0xc0de4c0ca19e);
    string public black = "vitalik";
    address public taker = address(0xc0de4c0cac01a);
    string public crook = "virgil";
    address public faker = address(0xc0de4d1ccc555);
    string public brown = "nick";
    string public _alias = "virgin";
    uint256 public lifespan = 50;
    uint8[2] public rules = [uint8(uint256(404)), uint8(uint256(400))];
    address[2] public config = [
        address(0x0101010101010),
        address(0x0101010101011)
    ];
    bytes32 public cation;
    bytes32 public anion;
    bytes32 public bondhash;
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

        // BONDS -------------------------------------------------
        // deploy BondRegistry
        BONDS = new Helix2BondRegistry(
            _NAMES,
            address(HELIX2_),
            address(PriceOracle)
        );
        address _BONDS = address(BONDS);
        // deploy BondRegistrar
        _BOND_ = new Helix2BondRegistrar(
            _BONDS,
            _NAMES,
            address(HELIX2_),
            address(PriceOracle)
        );

        // RESOLVERS ---------------------------------------------
        // deploy Name Resolver
        NameResolver_ = new NameResolver(address(HELIX2_));
        // deploy Bond Resolver
        BondResolver_ = new BondResolver(address(HELIX2_));

        // remaining values
        namePrice = PriceOracle.getPrices()[0];
        bondPrice = PriceOracle.getPrices()[1];
        HELIX2_.setRegistrar(0, address(_NAME_));
        HELIX2_.setRegistry(0, _NAMES);
        NAMES.setConfig(
            address(HELIX2_),
            address(PriceOracle),
            address(NAMESTORE)
        );
        HELIX2_.setRegistrar(1, address(_BOND_));
        HELIX2_.setRegistry(1, _BONDS);
        BONDS.setConfig(address(HELIX2_), address(PriceOracle));
    }

    /// forge setup
    function setUp() public {}

    /// Register a bond
    function testRegisterBond() public {
        // register two names
        cation = _NAME_.newName{value: namePrice * lifespan}(
            black,
            pill,
            lifespan
        );
        anion = _NAME_.newName{value: namePrice * lifespan}(
            crook,
            taker,
            lifespan
        );
        roothash = HELIX2_.getRoothash()[1];
        // expected hash of registered bond
        bytes32 _bondhash = keccak256(
            abi.encodePacked(
                cation,
                roothash,
                keccak256(abi.encodePacked(_alias))
            )
        );
        // register test bond linking two names
        bondhash = _BOND_.newBond{value: bondPrice * lifespan}(
            _alias,
            cation,
            anion,
            lifespan
        );
        assertEq(bondhash, _bondhash);
        bytes32 taker_ = BONDS.anion(bondhash);
        assertEq(anion, taker_);
    }

    /// Register a bond, let it expire, and verify records
    function testExpiration() public {
        // register two names
        cation = _NAME_.newName{value: namePrice * lifespan}(
            black,
            pill,
            lifespan
        );
        anion = _NAME_.newName{value: namePrice * lifespan}(
            crook,
            taker,
            lifespan
        );
        // register test bond linking two names
        bondhash = _BOND_.newBond{value: bondPrice * lifespan}(
            _alias,
            cation,
            anion,
            lifespan
        );
        vm.warp(block.timestamp + 10);
        assertEq(BONDS.recordExists(bondhash), true);
        uint256 _expiry = BONDS.expiry(bondhash);
        vm.prank(pill);
        vm.deal(pill, bondPrice * 10);
        vm.expectRevert(abi.encodePacked("BAD_EXPIRY"));
        BONDS.renew{value: bondPrice * 10}(bondhash, 10);
        vm.prank(pill);
        vm.deal(pill, bondPrice * 100);
        BONDS.renew{value: bondPrice * 100}(bondhash, _expiry + 100);
        vm.prank(pill);
        BONDS.setController(bondhash, taker);
        vm.prank(pill);
        BONDS.setRecord(bondhash, taker);
        vm.warp(block.timestamp + 200);
        assertEq(BONDS.recordExists(bondhash), false);
    }

    /// Register a bond and verify records
    function testVerifyRecords() public {
        // register two names
        cation = _NAME_.newName{value: namePrice * lifespan}(
            black,
            pill,
            lifespan
        );
        anion = _NAME_.newName{value: namePrice * lifespan}(
            crook,
            taker,
            lifespan
        );
        // register test bond linking two names
        bondhash = _BOND_.newBond{value: bondPrice * lifespan}(
            _alias,
            cation,
            anion,
            lifespan
        );
        assertEq(NAMES.owner(BONDS.cation(bondhash)), pill);
        assertEq(NAMES.owner(BONDS.anion(bondhash)), taker);
        assertEq(BONDS.cation(bondhash), cation);
        assertEq(BONDS.anion(bondhash), anion);
        assertEq(BONDS.controller(bondhash), pill);
        assertEq(BONDS.resolver(bondhash), defaultResolver);
        assertEq(BONDS.expiry(bondhash), block.timestamp + lifespan);
        (uint8[] memory rules_, address[] memory hooks_) = BONDS.hooksWithRules(
            bondhash
        );
        assertEq(hooks_.length, 0);
        assertEq(rules_.length, 0);
    }

    /// Register a bond and change Cationship record
    function testCationCanChangeCation() public {
        // register two names
        cation = _NAME_.newName{value: namePrice * lifespan}(
            black,
            pill,
            lifespan
        );
        anion = _NAME_.newName{value: namePrice * lifespan}(
            crook,
            taker,
            lifespan
        );
        // register test bond linking two names
        bondhash = _BOND_.newBond{value: bondPrice * lifespan}(
            _alias,
            cation,
            anion,
            lifespan
        );
        // register name to transfer to
        fakehash = _NAME_.newName{value: namePrice * (lifespan + 1)}(
            brown,
            faker,
            lifespan + 1
        );
        vm.prank(pill);
        BONDS.setCation(bondhash, fakehash);
        assertEq(NAMES.owner(BONDS.cation(bondhash)), faker);
    }

    /// Register a bond and set new controller, and test controller's permissions
    function testCationOrControllerCanControl() public {
        // register two names
        cation = _NAME_.newName{value: namePrice * lifespan}(
            black,
            pill,
            lifespan
        );
        anion = _NAME_.newName{value: namePrice * lifespan}(
            crook,
            taker,
            lifespan
        );
        // register test bond linking two names
        bondhash = _BOND_.newBond{value: bondPrice * lifespan}(
            _alias,
            cation,
            anion,
            lifespan
        );
        // register name to transfer to
        fakehash = _NAME_.newName{value: namePrice * (lifespan + 1)}(
            brown,
            faker,
            lifespan + 1
        );
        vm.prank(pill);
        BONDS.setRecord(bondhash, address(0));
        vm.prank(pill);
        BONDS.setCovalence(bondhash, false);
        vm.prank(pill);
        BONDS.setController(bondhash, faker);
        assertEq(BONDS.controller(bondhash), faker);
        vm.prank(faker);
        BONDS.setController(bondhash, taker);
        assertEq(BONDS.controller(bondhash), taker);
        vm.prank(taker);
        BONDS.setRecord(bondhash, address(0));
        assertEq(BONDS.resolver(bondhash), address(0));
        vm.prank(taker);
        vm.expectRevert(abi.encodePacked("NOT_OWNER"));
        BONDS.setCation(bondhash, fakehash);
    }

    /// Register a bond and attempt to make unauthorised calls
    function testCannotMakeUnauthorisedCalls() public {
        // register two names
        cation = _NAME_.newName{value: namePrice * lifespan}(
            black,
            pill,
            lifespan
        );
        anion = _NAME_.newName{value: namePrice * lifespan}(
            crook,
            taker,
            lifespan
        );
        // register test bond linking two names
        bondhash = _BOND_.newBond{value: bondPrice * lifespan}(
            _alias,
            cation,
            anion,
            lifespan
        );
        // register name to transfer to
        fakehash = _NAME_.newName{value: namePrice * (lifespan + 1)}(
            brown,
            faker,
            lifespan + 1
        );
        vm.prank(faker);
        vm.expectRevert(abi.encodePacked("NOT_OWNER"));
        BONDS.setCation(bondhash, fakehash);
        vm.expectRevert(abi.encodePacked("NOT_AUTHORISED"));
        BONDS.setRecord(bondhash, address(0));
        vm.expectRevert(abi.encodePacked("NOT_AUTHORISED"));
        BONDS.setController(bondhash, faker);
    }

    /// Register a bond, let it expire, and then re-register it
    function testRegisterExpiredBond() public {
        // register two names
        cation = _NAME_.newName{value: namePrice * lifespan}(
            black,
            pill,
            lifespan
        );
        anion = _NAME_.newName{value: namePrice * lifespan}(
            crook,
            taker,
            lifespan
        );
        // register test bond linking two names
        bondhash = _BOND_.newBond{value: bondPrice * lifespan}(
            _alias,
            cation,
            anion,
            lifespan
        );
        assertEq(BONDS.recordExists(bondhash), true);
        vm.warp(block.timestamp + 60);
        assertEq(BONDS.recordExists(bondhash), false);
        // register test bond linking two names
        bondhash = _BOND_.newBond{value: bondPrice * lifespan}(
            _alias,
            cation,
            anion,
            lifespan
        );
        assertEq(BONDS.recordExists(bondhash), true);
    }

    /// Register a bond and attempt to renew it
    function testOnlyCationOrControllerCanRenew() public {
        // register two names
        cation = _NAME_.newName{value: namePrice * lifespan}(
            black,
            pill,
            lifespan
        );
        anion = _NAME_.newName{value: namePrice * lifespan}(
            crook,
            taker,
            lifespan
        );
        // register test bond linking two names
        bondhash = _BOND_.newBond{value: bondPrice * lifespan}(
            _alias,
            cation,
            anion,
            lifespan
        );
        assertEq(BONDS.recordExists(bondhash), true);
        uint256 _expiry = BONDS.expiry(bondhash);
        vm.prank(pill);
        vm.deal(pill, bondPrice * lifespan);
        BONDS.renew{value: bondPrice * lifespan}(bondhash, _expiry + lifespan);
        assertEq(BONDS.expiry(bondhash), _expiry + lifespan);
        vm.prank(pill);
        BONDS.setController(bondhash, faker);
        assertEq(BONDS.controller(bondhash), faker);
        _expiry = BONDS.expiry(bondhash);
        vm.prank(faker);
        vm.deal(faker, bondPrice * lifespan);
        BONDS.renew{value: bondPrice * lifespan}(bondhash, _expiry + lifespan);
        vm.warp(block.timestamp + 200);
        assertEq(BONDS.recordExists(bondhash), false);
        _expiry = BONDS.expiry(bondhash);
        vm.prank(faker);
        vm.deal(faker, bondPrice * lifespan);
        vm.expectRevert(abi.encodePacked("BOND_EXPIRED"));
        BONDS.renew{value: bondPrice * lifespan}(bondhash, _expiry + lifespan);
    }

    /// Register a bond and attempt to change its anion
    function testOnlyCationOrControllerCanChangeAnion() public {
        // register two names
        cation = _NAME_.newName{value: namePrice * lifespan}(
            black,
            pill,
            lifespan
        );
        anion = _NAME_.newName{value: namePrice * lifespan}(
            crook,
            taker,
            lifespan
        );
        // register test bond linking two names
        bondhash = _BOND_.newBond{value: bondPrice * lifespan}(
            _alias,
            cation,
            anion,
            lifespan
        );
        // register name to transfer to
        fakehash = _NAME_.newName{value: namePrice * (lifespan + 1)}(
            brown,
            faker,
            lifespan + 1
        );
        assertEq(BONDS.recordExists(bondhash), true);
        vm.prank(faker);
        vm.expectRevert(abi.encodePacked("NOT_AUTHORISED"));
        BONDS.setAnion(bondhash, fakehash);
        vm.prank(pill);
        BONDS.setAnion(bondhash, fakehash);
        vm.prank(pill);
        BONDS.setController(bondhash, faker);
        vm.prank(faker);
        BONDS.setAnion(bondhash, jokehash);
    }

    /// Register a bond and attempt to add a hook
    function testOnlyCationOrControllerCanHook() public {
        // register two names
        cation = _NAME_.newName{value: namePrice * lifespan}(
            black,
            pill,
            lifespan
        );
        anion = _NAME_.newName{value: namePrice * lifespan}(
            crook,
            taker,
            lifespan
        );
        // register test bond linking two names
        bondhash = _BOND_.newBond{value: bondPrice * lifespan}(
            _alias,
            cation,
            anion,
            lifespan
        );
        // register name to transfer to
        fakehash = _NAME_.newName{value: namePrice * (lifespan + 1)}(
            brown,
            faker,
            lifespan + 1
        );
        assertEq(BONDS.recordExists(bondhash), true);
        vm.prank(pill);
        BONDS.hook(bondhash, config[0], rules[0]);
        (uint8[] memory rules_, address[] memory hooks_) = BONDS.hooksWithRules(
            bondhash
        );
        assertEq(rules[0], rules_[0]);
        assertEq(config[0], hooks_[0]);
        vm.prank(pill);
        BONDS.setController(bondhash, faker);
        vm.prank(faker);
        vm.expectRevert(abi.encodePacked("HOOK_EXISTS"));
        BONDS.hook(bondhash, config[0], rules[0]);
        vm.prank(faker);
        vm.expectRevert(abi.encodePacked("HOOK_EXISTS"));
        BONDS.hook(bondhash, config[0], rules[0]);
        vm.prank(faker);
        BONDS.hook(bondhash, config[1], rules[1]);
        (uint8[] memory rules__, address[] memory hooks__) = BONDS
            .hooksWithRules(bondhash);
        assertEq(config[1], hooks__[1]);
        assertEq(rules[1], rules__[1]);
    }

    /// Register a bond and attempt to rehook a hook to new config[0]
    function testOnlyCationOrControllerCanRehook() public {
        // register two names
        cation = _NAME_.newName{value: namePrice * lifespan}(
            black,
            pill,
            lifespan
        );
        anion = _NAME_.newName{value: namePrice * lifespan}(
            crook,
            taker,
            lifespan
        );
        // register test bond linking two names
        bondhash = _BOND_.newBond{value: bondPrice * lifespan}(
            _alias,
            cation,
            anion,
            lifespan
        );
        // register name to transfer to
        fakehash = _NAME_.newName{value: namePrice * (lifespan + 1)}(
            brown,
            faker,
            lifespan + 1
        );
        assertEq(BONDS.recordExists(bondhash), true);
        vm.prank(pill);
        BONDS.hook(bondhash, config[0], rules[0]);
        vm.prank(pill);
        BONDS.rehook(bondhash, config[1], rules[0]);
        (uint8[] memory rules_, address[] memory hooks_) = BONDS.hooksWithRules(
            bondhash
        );
        assertEq(rules[0], rules_[0]);
        assertEq(config[1], hooks_[0]);
        vm.prank(pill);
        BONDS.setController(bondhash, faker);
        vm.prank(faker);
        vm.expectRevert(abi.encodePacked("HOOK_EXISTS"));
        BONDS.hook(bondhash, config[0], rules[0]);
        vm.prank(faker);
        vm.expectRevert(abi.encodePacked("HOOK_EXISTS"));
        BONDS.hook(bondhash, config[0], rules[0]);
        vm.prank(faker);
        BONDS.hook(bondhash, config[1], rules[1]);
        vm.prank(faker);
        BONDS.rehook(bondhash, config[0], rules[1]);
        (uint8[] memory rules__, address[] memory hooks__) = BONDS
            .hooksWithRules(bondhash);
        assertEq(config[0], hooks__[1]);
        assertEq(rules[1], rules__[1]);
    }

    /// Register a bond and attempt to unhook a hook
    function testOnlyCationOrControllerCanUnhook() public {
        // register two names
        cation = _NAME_.newName{value: namePrice * lifespan}(
            black,
            pill,
            lifespan
        );
        anion = _NAME_.newName{value: namePrice * lifespan}(
            crook,
            taker,
            lifespan
        );
        // register test bond linking two names
        bondhash = _BOND_.newBond{value: bondPrice * lifespan}(
            _alias,
            cation,
            anion,
            lifespan
        );
        // register name to transfer to
        fakehash = _NAME_.newName{value: namePrice * (lifespan + 1)}(
            brown,
            faker,
            lifespan + 1
        );
        assertEq(BONDS.recordExists(bondhash), true);
        vm.prank(pill);
        BONDS.hook(bondhash, config[0], rules[0]);
        vm.prank(pill);
        BONDS.unhook(bondhash, rules[0]);
        (uint8[] memory rules_, address[] memory hooks_) = BONDS.hooksWithRules(
            bondhash
        );
        assertEq(hooks_.length, 1);
        assertEq(rules_.length, 1);
        vm.prank(pill);
        BONDS.setController(bondhash, faker);
        vm.prank(faker);
        vm.expectRevert(
            abi.encodeWithSelector(Helix2BondRegistry.BAD_HOOK.selector)
        );
        BONDS.unhook(bondhash, rules[0]);
        vm.prank(faker);
        BONDS.hook(bondhash, config[1], rules[1]);
        (uint8[] memory rules__, address[] memory hooks__) = BONDS
            .hooksWithRules(bondhash);
        assertEq(config[1], hooks__[1]);
        assertEq(rules[1], rules__[1]);
        assertEq(hooks__.length, uint(2));
        assertEq(rules__.length, uint(2));
    }
}
