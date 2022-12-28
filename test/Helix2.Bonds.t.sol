// SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "test/GenAddr.sol";
// Helix2 Manager Contract
import "src/Helix2.sol";
// Registrar
import "src/Names/NameRegistrar.sol";
import "src/Bonds/BondRegistrar.sol";
// Registry
import "src/Names/NameRegistry.sol";
import "src/Bonds/BondRegistry.sol";
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
    address public will = address(0xc0de4c0cac01a);
    string public white = "virgil";
    string public label = "virgin";
    uint256 public lifespan = 500;
    bytes32 public _cation;
    bytes32 public cation_;
    bytes32 public bondhash;
    uint256 public tokenID;

    constructor() {
        deployer = address(this);

        // HELIX2 ------------------------------------------------
        // deploy Helix2
        HELIX2_ = new HELIX2();
        address _HELIX2 = address(HELIX2_);

        // NAMES -------------------------------------------------
        // deploy NameRegistry
        NAMES = new Helix2NameRegistry(_HELIX2);
        address _NAMES = address(NAMES);
        // deploy NameRegistrar
        _NAME_ = new Helix2NameRegistrar(_NAMES, _HELIX2);

        // BONDS -------------------------------------------------
        // deploy BondRegistry
        BONDS = new Helix2BondRegistry(_NAMES, _HELIX2);
        address _BONDS = address(BONDS);
        // deploy BondRegistrar
        _BOND_ = new Helix2BondRegistrar(_BONDS, _NAMES, _HELIX2);

        // RESOLVERS ---------------------------------------------
        // deploy Name Resolver
        NameResolver_ = new NameResolver(_HELIX2);
        // deploy Bond Resolver
        BondResolver_ = new BondResolver(_HELIX2);

        // remaining values
        namePrice = HELIX2_.getPrices()[0];
        bondPrice = HELIX2_.getPrices()[1];
        HELIX2_.setRegistrar(0, address(_NAME_));
        HELIX2_.setRegistry(0, _NAMES);
        HELIX2_.setRegistrar(1, address(_BOND_));
        HELIX2_.setRegistry(1, _BONDS);
    }

    /// forge setup
    function setUp() public {}

    /// Register a bond
    function testRegisterBond() public {
        // register two names
        _cation = _NAME_.newName{value: namePrice * lifespan}(
            black,
            pill,
            lifespan
        );
        cation_ = _NAME_.newName{value: namePrice * lifespan}(
            white,
            will,
            lifespan
        );
        roothash = HELIX2_.getRoothash()[1];
        // expected hash of registered bond
        bytes32 _bondhash = keccak256(
            abi.encodePacked(
                _cation,
                roothash,
                keccak256(abi.encodePacked(label))
            )
        );
        // register test bond linking two names
        bondhash = _BOND_.newBond{value: bondPrice * lifespan}(
            label,
            _cation,
            cation_,
            lifespan
        );
        assertEq(bondhash, _bondhash);
    }

    /*
    /// >>> TO DO
    /// Register a bond, let it expire, and verify records
    function testExpiration() public {
        // register test bond
        lifespan = 1;
        bondhash = _BOND_.newBond{value: namePrice * lifespan}(
            label,
            pill,
            lifespan
        );
        tokenID = uint256(bondhash);
    }

    /// Register a bond and verify records
    function testVerifyRecords() public {
        // register test bond
        bondhash = _BOND_.newBond{value: namePrice * lifespan}(
            label,
            pill,
            lifespan
        );
        roothash = HELIX2_.getRoothash()[0];
        bytes32 _bondhash = keccak256(
            abi.encodePacked(keccak256(abi.encodePacked(label)), roothash)
        );
        assertEq(bondhash, _bondhash);
        assertEq(BONDS.owner(bondhash), pill);
        assertEq(BONDS.controller(bondhash), pill);
        assertEq(BONDS.resolver(bondhash), defaultResolver);
        assertEq(BONDS.expiry(bondhash), block.timestamp + lifespan);
    }

    /// Register a bond and change Ownership record
    function testOwnerCanChangeOwner() public {
        // register test bond
        bondhash = _BOND_.newBond{value: namePrice * lifespan}(
            label,
            pill,
            lifespan
        );
        vm.prank(pill);
        BONDS.setOwner(bondhash, will);
        assertEq(BONDS.owner(bondhash), will);
        assertEq(_BOND_.ownerOf(uint256(bondhash)), will);
        assertEq(_BOND_.balanceOf(pill), 0);
        assertEq(_BOND_.balanceOf(will), 1);
    }

    /// Register a bond and change Controller record as Owner
    function testOwnerCanSetController() public {
        // register test bond
        bondhash = _BOND_.newBond{value: namePrice * lifespan}(
            label,
            pill,
            lifespan
        );
        vm.prank(pill);
        BONDS.setController(bondhash, will);
        assertEq(BONDS.controller(bondhash), will);
    }

    /// Register a bond and change Controller record as Controller
    function testControllerCanSetController() public {
        // register test bond
        bondhash = _BOND_.newBond{value: namePrice * lifespan}(
            label,
            pill,
            lifespan
        );
        vm.prank(pill);
        BONDS.setController(bondhash, will);
        assertEq(BONDS.controller(bondhash), will);
        vm.prank(will);
        BONDS.setController(bondhash, pill);
        assertEq(BONDS.controller(bondhash), pill);
    }

    /// Register a bond and transfer to new owner via ERC721 interface
    function testOwnerCanTransferERC721() public {
        // register test bond
        bondhash = _BOND_.newBond{value: namePrice * lifespan}(
            label,
            pill,
            lifespan
        );
        tokenID = uint256(bondhash);
        assertEq(_BOND_.ownerOf(tokenID), pill);
        assertEq(_BOND_.balanceOf(pill), 1);
        assertEq(_BOND_.balanceOf(will), 0);
        vm.prank(pill);
        _BOND_.safeTransferFrom(pill, will, tokenID);
        assertEq(_BOND_.ownerOf(tokenID), will);
        assertEq(BONDS.owner(bondhash), will);
        assertEq(_BOND_.balanceOf(pill), 0);
        assertEq(_BOND_.balanceOf(will), 1);
    }

    /// Register a bond and set another address as controller
    function testOwnerCanApproveERC721() public {
        // register test bond
        bondhash = _BOND_.newBond{value: namePrice * lifespan}(
            label,
            pill,
            lifespan
        );
        tokenID = uint256(bondhash);
        vm.prank(pill);
        _BOND_.approve(will, tokenID);
        assertEq(BONDS.controller(bondhash), will);
    }

    /// Register a bond and verify controller can set new controller
    function testControllerCanApproveERC721() public {
        // register test bond
        bondhash = _BOND_.newBond{value: namePrice * lifespan}(
            label,
            pill,
            lifespan
        );
        tokenID = uint256(bondhash);
        vm.prank(pill);
        BONDS.setController(bondhash, will);
        vm.prank(will);
        _BOND_.approve(pill, tokenID);
        assertEq(BONDS.controller(bondhash), pill);
    }

    /// Register a bond and attempt to make unauthorised calls
    function testCannotMakeUnauthorisedCalls() public {
        // register test bond
        bondhash = _BOND_.newBond{value: namePrice * lifespan}(
            label,
            pill,
            lifespan
        );
        tokenID = uint256(bondhash);
        vm.prank(will);
        vm.expectRevert(abi.encodePacked("NOT_OWNER"));
        BONDS.setOwner(bondhash, will);
        vm.prank(will);
        vm.expectRevert(abi.encodePacked("NOT_AUTHORISED"));
        BONDS.setController(bondhash, will);
        vm.prank(will);
        vm.expectRevert(abi.encodePacked("NOT_AUTHORISED"));
        BONDS.setRecord(bondhash, will);
        vm.prank(will);
        vm.expectRevert(abi.encodePacked("NOT_AUTHORISED"));
        BONDS.setExpiry(bondhash, block.timestamp + 100);
    }

    /// >>> TO DO
    /// Register a bond, let it expire, and attempt to renew it
    function testRenewalByOwner() public {
        // register test bond
        bondhash = _BOND_.newBond{value: namePrice * lifespan}(
            label,
            pill,
            lifespan
        );
        tokenID = uint256(bondhash);
        
    }

    /// >>> TO DO
    /// Attempt to register an expiwhite bond (accounted to someone else's balance)
    function testClaimExpiwhiteBond() public {
        // register test bond
        bondhash = _BOND_.newBond{value: namePrice * lifespan}(
            label,
            pill,
            lifespan
        );
        tokenID = uint256(bondhash);
    }
    */
}
