// SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "test/GenAddr.sol";
// Helix2 Manager Contract
import "src/Helix2.sol";
// Registrar
import "src/Names/NameRegistrar.sol";
// Registry
import "src/Names/NameRegistry.sol";
// Resolver
import "src/Names/NameResolver.sol";
// Interface
import "src/Names/iName.sol";
import "src/Names/iERC721.sol";
import "src/Names/iNameResolver.sol";
import "src/Interface/iHelix2.sol";
import "src/Interface/iENS.sol";

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
    // Registrar
    Helix2NameRegistrar public _NAME_;

    /// Constants
    address public deployer;
    uint256 public theEnd = 250_000_000_000_000_000; // roughly 80,000,000,000 years in the future
    uint256 public basePrice;
    bytes32 public roothash;
    address public defaultResolver;

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

        // RESOLVERS ---------------------------------------------
        // deploy Name Resolver
        NameResolver_ = new NameResolver(_HELIX2);

        // remaining values
        basePrice = HELIX2_.getPrices()[0];
        HELIX2_.setRegistrar(0, address(_NAME_));
        HELIX2_.setRegistry(0, _NAMES);
    }

    /// forge setup
    function setUp() public {}

    /// Register a name
    function testRegisterName() public {
        address pill = address(0xc0de4c0ca19e);
        string memory label = "vitalik";
        uint256 _lifespan = 500;
        _NAME_.newName{value: basePrice * _lifespan}(label, pill, _lifespan);
    }

    /// Register a name and verify records
    function testVerifyRecords() public {
        address pill = address(0xc0de4c0ca19e);
        string memory label = "vitalik";
        uint256 _lifespan = 500;
        uint256 _block = block.timestamp;
        bytes32 _namehash = _NAME_.newName{value: basePrice * _lifespan}(
            label,
            pill,
            _lifespan
        );
        roothash = HELIX2_.getRoothash()[0];
        bytes32 __namehash = keccak256(
            abi.encodePacked(keccak256(abi.encodePacked(label)), roothash)
        );
        assertEq(_namehash, __namehash);
        assertEq(NAMES.owner(_namehash), pill);
        assertEq(NAMES.controller(_namehash), pill);
        assertEq(NAMES.resolver(_namehash), defaultResolver);
        assertEq(NAMES.expiry(_namehash), _block + _lifespan);
    }

    /// Register a name and change Ownership record
    function testOwnerCanChangeOwner() public {
        address pill = address(0xc0de4c0ca19e);
        string memory label = "vitalik";
        uint256 _lifespan = 500;
        bytes32 _namehash = _NAME_.newName{value: basePrice * _lifespan}(
            label,
            pill,
            _lifespan
        );
        address taker = address(0xc0de4c0cac01a);
        vm.prank(pill);
        NAMES.setOwner(_namehash, taker);
        assertEq(NAMES.owner(_namehash), taker);
    }

    /// Register a name and change Controller record as Owner
    function testOwnerCanSetController() public {
        address pill = address(0xc0de4c0ca19e);
        string memory label = "vitalik";
        uint256 _lifespan = 500;
        bytes32 _namehash = _NAME_.newName{value: basePrice * _lifespan}(
            label,
            pill,
            _lifespan
        );
        address taker = address(0xc0de4c0cac01a);
        vm.prank(pill);
        NAMES.setController(_namehash, taker);
        assertEq(NAMES.controller(_namehash), taker);
    }

    /// Register a name and change Controller record as Controller
    function testControllerCanSetController() public {
        address pill = address(0xc0de4c0ca19e);
        string memory label = "vitalik";
        uint256 _lifespan = 500;
        bytes32 _namehash = _NAME_.newName{value: basePrice * _lifespan}(
            label,
            pill,
            _lifespan
        );
        address taker = address(0xc0de4c0cac01a);
        vm.prank(pill);
        NAMES.setController(_namehash, taker);
        assertEq(NAMES.controller(_namehash), taker);
        vm.prank(taker);
        NAMES.setController(_namehash, pill);
        assertEq(NAMES.controller(_namehash), pill);
    }

    /// Register a name and transfer to new owner via ERC721 interface
    function testOwnerCanTransferERC721() public {
        address pill = address(0xc0de4c0ca19e);
        string memory label = "vitalik";
        uint256 _lifespan = 500;
        bytes32 _namehash = _NAME_.newName{value: basePrice * _lifespan}(
            label,
            pill,
            _lifespan
        );
        uint256 tokenID = uint256(_namehash);
        address taker = address(0xc0de4c0cac01a);
        assertEq(_NAME_.ownerOf(tokenID), pill);
        vm.prank(pill);
        _NAME_.safeTransferFrom(pill, taker, tokenID);
        assertEq(_NAME_.ownerOf(tokenID), taker);
        assertEq(NAMES.owner(_namehash), taker);
    }

    /// Register a name and transfer to new owner via ERC721 interface
    function testOwnerCanApproveERC721() public {
        address pill = address(0xc0de4c0ca19e);
        string memory label = "vitalik";
        uint256 _lifespan = 500;
        bytes32 _namehash = _NAME_.newName{value: basePrice * _lifespan}(
            label,
            pill,
            _lifespan
        );
        uint256 tokenID = uint256(_namehash);
        address taker = address(0xc0de4c0cac01a);
        assertEq(_NAME_.ownerOf(tokenID), pill);
        vm.prank(pill);
        _NAME_.safeTransferFrom(pill, taker, tokenID);
        assertEq(_NAME_.ownerOf(tokenID), taker);
        assertEq(NAMES.owner(_namehash), taker);
    }
}
