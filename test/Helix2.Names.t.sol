// SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "test/GenAddr.sol";
// Helix2 Manager Contract
import "src/Classic/Helix2.sol";
// Price Oracle
import "src/Oracle/PriceOracle.sol";
// Registrar
import "src/Names/NameRegistrar.sol";
// Registry
import "src/Names/NameRegistry.sol";
// Storage
import "src/Names/NameStorage.sol";
// Resolver
import "src/Names/NameResolver.sol";
// Interface
import "src/Names/iName.sol";
import "src/Names/iERC721.sol";
import "src/Names/iNameResolver.sol";
import "src/Interface/iHelix2.sol";
import "src/Interface/iENS.sol";
import "src/Oracle/iPriceOracle.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Registrar and Registry Tests
 * @notice Tests functions of Helix2 Name Registrar and Name Registry
 */
contract Helix2NamesTest is Test {
    using GenAddr for address;

    HELIX2 public HELIX2_;
    NameResolver public NameResolver_;
    // Registry
    Helix2NameRegistry public NAMES;
    // Storage
    Helix2NameStorage public NAMESTORE;
    // Registrar
    Helix2NameRegistrar public _NAME_;
    // Price Oracle
    Helix2PriceOracle public PriceOracle;
    // ENS Registry
    iENS public ENS;

    /// Constants
    address public deployer;
    uint256 public theEnd = 250_000_000_000_000_000; // roughly 80,000,000,000 years in the future
    uint256 public basePrice;
    bytes32 public roothash;
    address public defaultResolver;

    /// Global test variables
    address public pill = address(0xc0de4c0ca19e);
    string public label = "vitalik";
    uint256 public lifespan = 50;
    bytes32 public namehash;
    address public taker = address(0xc0de4c0cac01a);
    address public faker = address(0xc0de4cafec0ca);
    uint256 public tokenID;
    string public ens = "00075";
    string public _ens = string.concat(ens, ".eth");

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

        // RESOLVERS ---------------------------------------------
        // deploy Name Resolver
        NameResolver_ = new NameResolver(address(HELIX2_));

        // remaining values
        basePrice = PriceOracle.getPrices()[0];
        HELIX2_.setRegistrar(0, address(_NAME_));
        HELIX2_.setRegistry(0, _NAMES);
        NAMES.setConfig(
            address(HELIX2_),
            address(PriceOracle),
            address(NAMESTORE)
        );
        roothash = HELIX2_.getRoothash()[0];
        ENS = iENS(HELIX2_.getENSRegistry());
    }

    /// forge setup
    function setUp() public {}

    /// Register a name
    function testRegisterName() public {
        // register test name
        namehash = _NAME_.newName{value: basePrice * lifespan}(
            label,
            pill,
            lifespan
        );
        // expected hash of registered name
        bytes32 _namehash = keccak256(
            abi.encodePacked(keccak256(abi.encodePacked(label)), roothash)
        );
        assertEq(namehash, _namehash);
        assertEq(_NAME_.balanceOf(pill), 1);
    }

    /// Attempt to register a name for free
    function testCannotRegisterNameWithBadPrice() public {
        vm.expectRevert(abi.encodePacked("INSUFFICIENT_ETHER"));
        // register test name
        namehash = _NAME_.newName{value: 0}(label, pill, lifespan);
    }

    /// Attempt to register a name with bad size
    function testCannotRegisterNameWithBadSize() public {
        vm.expectRevert(abi.encodePacked("ILLEGAL_LABEL"));
        // register test name
        namehash = _NAME_.newName{value: basePrice * lifespan}(
            "hi",
            pill,
            lifespan
        );
        vm.expectRevert(abi.encodePacked("ILLEGAL_LABEL"));
        // register test name
        namehash = _NAME_.newName{value: basePrice * lifespan}(
            "hihihihihihihihihihihihihihihihihihihi",
            pill,
            lifespan
        );
    }

    /// claim ENS name
    function testClaimENS() public {
        // calculate ENS node
        bytes32 node = keccak256(
            abi.encodePacked(
                keccak256(abi.encodePacked(bytes32(0), keccak256("eth"))),
                keccak256(abi.encodePacked(ens))
            )
        );
        address mill = ENS.owner(node);
        vm.prank(mill);
        // register test name
        namehash = _NAME_.claimENS{value: basePrice * lifespan}(_ens, lifespan);
        // expected hash of registered name
        bytes32 _namehash = keccak256(abi.encodePacked(node, roothash));
        assertEq(namehash, _namehash);
        assertEq(_NAME_.balanceOf(mill), 1);
        assertEq(NAMES.label(namehash), _ens);
    }

    /// attempt to claim illegal ENS
    function testCannotClainIllegalENS() public {
        // calculate ENS node
        vm.deal(pill, basePrice * lifespan);
        vm.prank(pill);
        vm.expectRevert(abi.encodePacked("NOT_ENS_OWNER"));
        // register test name
        _NAME_.claimENS{value: basePrice * lifespan}(_ens, lifespan);
    }

    /// Register a name, let it expire, and verify records
    function testExpiration() public {
        // register test name
        namehash = _NAME_.newName{value: basePrice * lifespan}(
            label,
            pill,
            lifespan
        );
        tokenID = uint256(namehash);
        vm.warp(block.timestamp + 10);
        assertEq(NAMES.recordExists(namehash), true);
        uint256 _expiry = NAMES.expiry(namehash);
        vm.prank(pill);
        vm.deal(pill, basePrice * 10);
        vm.expectRevert(abi.encodePacked("BAD_EXPIRY"));
        NAMES.renew{value: basePrice * 10}(namehash, 10);
        vm.prank(pill);
        vm.deal(pill, basePrice * 100);
        NAMES.renew{value: basePrice * 100}(namehash, _expiry + 100);
        vm.prank(pill);
        NAMES.setController(namehash, taker);
        vm.prank(pill);
        NAMES.setResolver(namehash, taker);
        vm.warp(block.timestamp + 200);
        assertEq(NAMES.recordExists(namehash), false);
    }

    /// Register a name and verify records
    function testVerifyResolvers() public {
        // register test name
        namehash = _NAME_.newName{value: basePrice * lifespan}(
            label,
            pill,
            lifespan
        );
        roothash = HELIX2_.getRoothash()[0];
        bytes32 _namehash = keccak256(
            abi.encodePacked(keccak256(abi.encodePacked(label)), roothash)
        );
        assertEq(namehash, _namehash);
        assertEq(NAMES.owner(namehash), pill);
        assertEq(NAMES.label(namehash), label);
        assertEq(NAMES.controller(namehash), pill);
        assertEq(NAMES.resolver(namehash), defaultResolver);
        assertEq(NAMES.expiry(namehash), block.timestamp + lifespan);
    }

    /// Register a name and change Ownership record
    function testOwnerCanChangeOwner() public {
        // register test name
        namehash = _NAME_.newName{value: basePrice * lifespan}(
            label,
            pill,
            lifespan
        );
        vm.prank(pill);
        NAMES.setOwner(namehash, taker);
        assertEq(NAMES.owner(namehash), taker);
        assertEq(_NAME_.ownerOf(uint256(namehash)), taker);
        assertEq(_NAME_.balanceOf(pill), 0);
        assertEq(_NAME_.balanceOf(taker), 1);
    }

    /// Register a name and change Controller record as Owner
    function testOwnerCanSetController() public {
        // register test name
        namehash = _NAME_.newName{value: basePrice * lifespan}(
            label,
            pill,
            lifespan
        );
        vm.prank(pill);
        NAMES.setController(namehash, taker);
        assertEq(NAMES.controller(namehash), taker);
    }

    /// Register a name, set new controller, and test owner and controller's permissions
    function testOwnerOrControllerCanControl() public {
        // register test name
        namehash = _NAME_.newName{value: basePrice * lifespan}(
            label,
            pill,
            lifespan
        );
        vm.prank(pill);
        NAMES.setResolver(namehash, address(0));
        vm.prank(pill);
        NAMES.setResolver(namehash, address(0));
        vm.prank(pill);
        NAMES.setController(namehash, taker);
        assertEq(NAMES.controller(namehash), taker);
        vm.prank(taker);
        NAMES.setController(namehash, faker);
        vm.prank(faker);
        NAMES.setResolver(namehash, address(0));
        assertEq(NAMES.resolver(namehash), address(0));
        vm.prank(faker);
        vm.expectRevert(abi.encodePacked("NOT_OWNER"));
        NAMES.setOwner(namehash, faker);
    }

    /// Register a name and transfer to new owner via ERC721 interface
    function testOwnerCanTransferERC721() public {
        // register test name
        namehash = _NAME_.newName{value: basePrice * lifespan}(
            label,
            pill,
            lifespan
        );
        tokenID = uint256(namehash);
        assertEq(_NAME_.ownerOf(tokenID), pill);
        assertEq(_NAME_.balanceOf(pill), 1);
        assertEq(_NAME_.balanceOf(taker), 0);
        vm.prank(pill);
        _NAME_.safeTransferFrom(pill, taker, tokenID);
        assertEq(_NAME_.ownerOf(tokenID), taker);
        assertEq(_NAME_.balanceOf(pill), 0);
        assertEq(_NAME_.balanceOf(taker), 1);
        assertEq(NAMES.owner(namehash), taker);
    }

    /// Register a name and set another address as controller
    function testOwnerCanApproveERC721() public {
        // register test name
        namehash = _NAME_.newName{value: basePrice * lifespan}(
            label,
            pill,
            lifespan
        );
        tokenID = uint256(namehash);
        vm.prank(pill);
        _NAME_.approve(taker, tokenID);
        assertEq(NAMES.controller(namehash), taker);
    }

    /// Register a name and verify controller can set new controller
    function testControllerCanApproveERC721() public {
        // register test name
        namehash = _NAME_.newName{value: basePrice * lifespan}(
            label,
            pill,
            lifespan
        );
        tokenID = uint256(namehash);
        vm.prank(pill);
        NAMES.setController(namehash, taker);
        vm.prank(taker);
        _NAME_.approve(pill, tokenID);
        assertEq(NAMES.controller(namehash), pill);
    }

    /// Register a name and attempt to make unauthorised calls
    function testCannotMakeUnauthorisedCalls() public {
        // register test name
        namehash = _NAME_.newName{value: basePrice * lifespan}(
            label,
            pill,
            lifespan
        );
        tokenID = uint256(namehash);
        vm.prank(taker);
        vm.expectRevert(abi.encodePacked("NOT_OWNER"));
        NAMES.setOwner(namehash, taker);
        vm.prank(taker);
        vm.expectRevert(abi.encodePacked("NOT_AUTHORISED"));
        NAMES.setController(namehash, taker);
        vm.prank(taker);
        vm.expectRevert(abi.encodePacked("NOT_AUTHORISED"));
        NAMES.setResolver(namehash, taker);
        uint256 _expiry = NAMES.expiry(namehash);
        vm.deal(taker, basePrice * 100);
        vm.prank(taker);
        vm.expectRevert(abi.encodePacked("NOT_OWNER_OR_CONTROLLER"));
        NAMES.renew{value: basePrice * 100}(namehash, _expiry + 100);
    }

    /// Register a name, let it expire, and then attempt to re-register it
    function testRegisterExpiredName() public {
        // register test name
        namehash = _NAME_.newName{value: basePrice * lifespan}(
            label,
            pill,
            lifespan
        );
        tokenID = uint256(namehash);
        vm.warp(block.timestamp + 60);
        assertEq(NAMES.recordExists(namehash), false);
        namehash = _NAME_.newName{value: basePrice * lifespan}(
            label,
            pill,
            lifespan
        );
        assertEq(NAMES.recordExists(namehash), true);
    }

    /// Attempt to register an expired name (accounted to someone else's balance)
    function testOnlyOwnerOrControllerCanRenew() public {
        // register test name
        namehash = _NAME_.newName{value: basePrice * lifespan}(
            label,
            pill,
            lifespan
        );
        tokenID = uint256(namehash);
        assertEq(NAMES.recordExists(namehash), true);
        uint256 _expiry = NAMES.expiry(namehash);
        vm.prank(pill);
        vm.deal(pill, basePrice * lifespan);
        NAMES.renew{value: basePrice * lifespan}(namehash, _expiry + lifespan);
        assertEq(NAMES.expiry(namehash), _expiry + lifespan);
        vm.prank(pill);
        NAMES.setController(namehash, faker);
        _expiry = NAMES.expiry(namehash);
        vm.prank(faker);
        vm.deal(faker, basePrice * lifespan);
        NAMES.renew{value: basePrice * lifespan}(namehash, _expiry + lifespan);
        vm.warp(block.timestamp + 200);
        assertEq(NAMES.recordExists(namehash), false);
        _expiry = NAMES.expiry(namehash);
        vm.prank(pill);
        vm.deal(pill, basePrice * lifespan);
        vm.expectRevert(abi.encodePacked("NAME_EXPIRED"));
        NAMES.renew{value: basePrice * lifespan}(namehash, _expiry + lifespan);
    }
}
