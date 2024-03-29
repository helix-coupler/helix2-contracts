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
import "src/Molecules/MoleculeRegistrar.sol";
// Registry
import "src/Names/NameRegistry.sol";
import "src/Molecules/MoleculeRegistry.sol";
// Storage
import "src/Names/NameStorage.sol";
import "src/Molecules/MoleculeStorage.sol";
// Resolver
import "src/Names/NameResolver.sol";
import "src/Molecules/MoleculeResolver.sol";
// Interface
import "src/Names/iName.sol";
import "src/Molecules/iMolecule.sol";
import "src/Names/iERC721.sol";
import "src/Names/iNameResolver.sol";
import "src/Molecules/iMoleculeResolver.sol";
import "src/Interface/iHelix2.sol";
import "src/Interface/iENS.sol";
import "src/Oracle/iPriceOracle.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Registrar and Registry Tests
 * @notice Tests functions of Helix2 Molecule Registrar and Molecule Registry
 */
contract Helix2MoleculesTest is Test {
    using GenAddr for address;

    HELIX2 public HELIX2_;
    NameResolver public NameResolver_;
    MoleculeResolver public MoleculeResolver_;
    // Registry
    Helix2NameRegistry public NAMES;
    Helix2MoleculeRegistry public MOLECULES;
    // Storage
    Helix2NameStorage public NAMESTORE;
    Helix2MoleculeStorage public MOLYSTORE;
    // Registrar
    Helix2NameRegistrar public _NAME_;
    Helix2MoleculeRegistrar public _MOLY_;
    // Price Oracle
    Helix2PriceOracle public PriceOracle;

    /// Constants
    address public deployer;
    uint256 public theEnd = 250_000_000_000_000_000; // roughly 80,000,000,000 years in the future
    uint256 public namePrice;
    uint256 public molyprice;
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
    string public label = "virgin";
    uint256 public lifespan = 50;
    uint8[2] public rules = [uint8(uint256(404)), uint8(uint256(400))];
    address[2] public config = [
        address(0x0101010101010),
        address(0x0101010101011)
    ];
    bytes32 public cation;
    bytes32[] public anions;
    bytes32[] public _anions_;
    bytes32 public molyhash;
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

        // MOLECULES -------------------------------------------------
        // deploy MoleculeRegistry
        MOLECULES = new Helix2MoleculeRegistry(
            _NAMES,
            address(HELIX2_),
            address(PriceOracle)
        );
        address _MOLECULES = address(MOLECULES);
        // deploy MoleculeStorage
        MOLYSTORE = new Helix2MoleculeStorage(_MOLECULES);
        // deploy MoleculeRegistrar
        _MOLY_ = new Helix2MoleculeRegistrar(
            _MOLECULES,
            _NAMES,
            address(HELIX2_),
            address(PriceOracle)
        );

        // RESOLVERS ---------------------------------------------
        // deploy Name Resolver
        NameResolver_ = new NameResolver(address(HELIX2_));
        // deploy Molecule Resolver
        MoleculeResolver_ = new MoleculeResolver(address(HELIX2_));

        // remaining values
        namePrice = PriceOracle.getPrices()[0];
        molyprice = PriceOracle.getPrices()[2];
        HELIX2_.setRegistrar(0, address(_NAME_));
        HELIX2_.setRegistry(0, _NAMES);
        NAMES.setConfig(
            address(HELIX2_),
            address(PriceOracle),
            address(NAMESTORE)
        );
        HELIX2_.setRegistrar(2, address(_MOLY_));
        HELIX2_.setRegistry(2, _MOLECULES);
        MOLECULES.setConfig(
            address(HELIX2_),
            address(PriceOracle),
            address(MOLYSTORE)
        );
    }

    /// forge setup
    function setUp() public {}

    /// Register a molecule
    function testRegisterMolecule() public {
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
        roothash = HELIX2_.getRoothash()[2];
        // expected hash of registered molecule
        bytes32 _molyhash = keccak256(
            abi.encodePacked(
                cation,
                roothash,
                keccak256(abi.encodePacked(label))
            )
        );
        // register test molecule linking (1 + n) names
        molyhash = _MOLY_.newMolecule{value: molyprice * lifespan}(
            label,
            cation,
            anions,
            lifespan
        );
        assertEq(molyhash, _molyhash);
        bytes32[] memory taker_ = MOLECULES.anions(molyhash);
        assertEq(taker.length, anions.length);
        assertEq(taker.length, taker_.length);
    }

    /// Register a molecule, let it expire, and verify records
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
        // register test molecule linking (1 + n) names
        molyhash = _MOLY_.newMolecule{value: molyprice * lifespan}(
            label,
            cation,
            anions,
            lifespan
        );
        vm.warp(block.timestamp + 10);
        assertEq(MOLECULES.recordExists(molyhash), true);
        uint256 _expiry = MOLECULES.expiry(molyhash);
        vm.prank(pill);
        vm.deal(pill, molyprice * 10);
        vm.expectRevert(abi.encodePacked("BAD_EXPIRY"));
        MOLECULES.renew{value: molyprice * 10}(molyhash, 10);
        vm.prank(pill);
        vm.deal(pill, molyprice * 100);
        MOLECULES.renew{value: molyprice * 100}(molyhash, _expiry + 100);
        vm.prank(pill);
        MOLECULES.setController(molyhash, faker);
        vm.prank(pill);
        MOLECULES.setResolver(molyhash, faker);
        vm.warp(block.timestamp + 200);
        assertEq(MOLECULES.recordExists(molyhash), false);
    }

    /// Register a molecule and verify records
    function testVerifyResolvers() public {
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
        // register test molecule linking (1 + n) names
        molyhash = _MOLY_.newMolecule{value: molyprice * lifespan}(
            label,
            cation,
            anions,
            lifespan
        );
        assertEq(NAMES.owner(MOLECULES.cation(molyhash)), pill);
        bytes32[] memory taker_ = MOLECULES.anions(molyhash);
        assertEq(taker.length, anions.length);
        assertEq(taker.length, taker_.length);
        for (uint i = 0; i < crook.length; i++) {
            assertEq(NAMES.owner(taker_[i]), taker[i]);
        }
        assertEq(MOLECULES.cation(molyhash), cation);
        for (uint i = 0; i < crook.length; i++) {
            assertEq(taker_[i], anions[i]);
        }
        assertEq(MOLECULES.controller(molyhash), pill);
        assertEq(MOLECULES.resolver(molyhash), defaultResolver);
        assertEq(MOLECULES.expiry(molyhash), block.timestamp + lifespan);
        (uint8[] memory rules_, address[] memory hooks_) = MOLECULES
            .hooksWithRules(molyhash);
        assertEq(hooks_.length, 0);
        assertEq(rules_.length, 0);
    }

    /// Register a molecule and change cation
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
        // register test molecule linking (1 + n) names
        molyhash = _MOLY_.newMolecule{value: molyprice * lifespan}(
            label,
            cation,
            anions,
            lifespan
        );
        // register name to transfer to
        fakehash = _NAME_.newName{value: namePrice * (lifespan + 1)}(
            brown,
            faker,
            lifespan + 1
        );
        vm.prank(pill);
        MOLECULES.setCation(molyhash, fakehash);
        assertEq(NAMES.owner(MOLECULES.cation(molyhash)), faker);
    }

    /// Register a molecule and set new controller, and test controller's permissions
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
        // register test molecule linking (1 + n) names
        molyhash = _MOLY_.newMolecule{value: molyprice * lifespan}(
            label,
            cation,
            anions,
            lifespan
        );
        // register name to transfer to
        fakehash = _NAME_.newName{value: namePrice * (lifespan + 1)}(
            brown,
            faker,
            lifespan + 1
        );
        vm.prank(pill);
        MOLECULES.setResolver(molyhash, address(0));
        vm.prank(pill);
        MOLECULES.setCovalence(molyhash, false);
        vm.prank(pill);
        MOLECULES.setController(molyhash, faker);
        assertEq(MOLECULES.controller(molyhash), faker);
        vm.prank(faker);
        MOLECULES.setResolver(molyhash, address(0));
        assertEq(MOLECULES.resolver(molyhash), address(0));
        vm.prank(faker);
        vm.expectRevert(abi.encodePacked("NOT_OWNER"));
        MOLECULES.setCation(molyhash, fakehash);
    }

    /// Register a molecule and attempt to make unauthorised calls
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
        // register test molecule linking (1 + n) names
        molyhash = _MOLY_.newMolecule{value: molyprice * lifespan}(
            label,
            cation,
            anions,
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
        MOLECULES.setCation(molyhash, fakehash);
        vm.expectRevert(abi.encodePacked("NOT_AUTHORISED"));
        MOLECULES.setResolver(molyhash, address(0));
        vm.expectRevert(abi.encodePacked("NOT_AUTHORISED"));
        MOLECULES.setController(molyhash, faker);
    }

    /// Register a molecule, let it expire, and then re-register it
    function testRegisterExpiredMolecule() public {
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
        // register test molecule linking (1 + n) names
        molyhash = _MOLY_.newMolecule{value: molyprice * lifespan}(
            label,
            cation,
            anions,
            lifespan
        );
        assertEq(MOLECULES.recordExists(molyhash), true);
        vm.warp(block.timestamp + 60);
        assertEq(MOLECULES.recordExists(molyhash), false);
        // register test molecule linking (1 + n) names
        molyhash = _MOLY_.newMolecule{value: molyprice * lifespan}(
            label,
            cation,
            anions,
            lifespan
        );
        assertEq(MOLECULES.recordExists(molyhash), true);
    }

    /// Register a molecule and attempt to renew it
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
        // register test molecule linking (1 + n) names
        molyhash = _MOLY_.newMolecule{value: molyprice * lifespan}(
            label,
            cation,
            anions,
            lifespan
        );
        assertEq(MOLECULES.recordExists(molyhash), true);
        uint256 _expiry = MOLECULES.expiry(molyhash);
        vm.prank(pill);
        vm.deal(pill, molyprice * lifespan);
        MOLECULES.renew{value: molyprice * lifespan}(
            molyhash,
            _expiry + lifespan
        );
        assertEq(MOLECULES.expiry(molyhash), _expiry + lifespan);
        vm.prank(pill);
        MOLECULES.setController(molyhash, faker);
        assertEq(MOLECULES.controller(molyhash), faker);
        _expiry = MOLECULES.expiry(molyhash);
        vm.prank(faker);
        vm.deal(faker, molyprice * lifespan);
        MOLECULES.renew{value: molyprice * lifespan}(
            molyhash,
            _expiry + lifespan
        );
        vm.warp(block.timestamp + 200);
        assertEq(MOLECULES.recordExists(molyhash), false);
        _expiry = MOLECULES.expiry(molyhash);
        vm.prank(faker);
        vm.deal(faker, molyprice * lifespan);
        vm.expectRevert(abi.encodePacked("MOLECULE_EXPIRED"));
        MOLECULES.renew{value: molyprice * lifespan}(
            molyhash,
            _expiry + lifespan
        );
    }

    /// Register a molecule and attempt to add & pop anions
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
        // register test molecule linking (1 + n) names
        molyhash = _MOLY_.newMolecule{value: molyprice * lifespan}(
            label,
            cation,
            anions,
            lifespan
        );
        // register name to transfer to
        fakehash = _NAME_.newName{value: namePrice * (lifespan + 1)}(
            brown,
            faker,
            lifespan + 1
        );
        assertEq(MOLECULES.recordExists(molyhash), true);
        vm.prank(faker);
        vm.expectRevert(abi.encodePacked("NOT_OWNER_OR_CONTROLLER"));
        MOLECULES.addAnion(molyhash, _anions_[0]);
        vm.prank(pill);
        MOLECULES.addAnion(molyhash, _anions_[0]);
        assertEq(MOLECULES.anions(molyhash).length, anions.length + 1);
        vm.prank(pill);
        MOLECULES.popAnion(molyhash, _anions_[0]);
        assertEq(MOLECULES.anions(molyhash).length, anions.length + 1);
        vm.prank(pill);
        MOLECULES.setAnions(molyhash, _anions_);
        assertEq(
            MOLECULES.anions(molyhash).length,
            anions.length + _anions_.length + 1
        );
    }

    /// Register a molecule and attempt to add a hook
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
        // register test molecule linking (1 + n) names
        molyhash = _MOLY_.newMolecule{value: molyprice * lifespan}(
            label,
            cation,
            anions,
            lifespan
        );
        // register name to transfer to
        fakehash = _NAME_.newName{value: namePrice * (lifespan + 1)}(
            brown,
            faker,
            lifespan + 1
        );
        assertEq(MOLECULES.recordExists(molyhash), true);
        vm.prank(pill);
        MOLECULES.hook(molyhash, config[0], rules[0]);
        (uint8[] memory rules_, address[] memory hooks_) = MOLECULES
            .hooksWithRules(molyhash);
        assertEq(config[0], hooks_[0]);
        assertEq(rules[0], rules_[0]);
        vm.prank(pill);
        MOLECULES.setController(molyhash, faker);
        vm.prank(faker);
        vm.expectRevert(abi.encodePacked("RULE_EXISTS"));
        MOLECULES.hook(molyhash, config[0], rules[0]);
        vm.prank(faker);
        vm.expectRevert(abi.encodePacked("RULE_EXISTS"));
        MOLECULES.hook(molyhash, config[1], rules[0]);
        vm.prank(faker);
        MOLECULES.hook(molyhash, config[1], rules[1]);
        (uint8[] memory rules__, address[] memory hooks__) = MOLECULES
            .hooksWithRules(molyhash);
        assertEq(config[1], hooks__[1]);
        assertEq(rules[1], rules__[1]);
    }

    /// Register a molecule and attempt to rehook a hook to new config[0]
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
        // register test molecule linking (1 + n) names
        molyhash = _MOLY_.newMolecule{value: molyprice * lifespan}(
            label,
            cation,
            anions,
            lifespan
        );
        // register name to transfer to
        fakehash = _NAME_.newName{value: namePrice * (lifespan + 1)}(
            brown,
            faker,
            lifespan + 1
        );
        assertEq(MOLECULES.recordExists(molyhash), true);
        vm.prank(pill);
        MOLECULES.hook(molyhash, config[0], rules[0]);
        vm.prank(pill);
        MOLECULES.rehook(molyhash, config[1], rules[0]);
        (uint8[] memory rules_, address[] memory hooks_) = MOLECULES
            .hooksWithRules(molyhash);
        assertEq(config[1], hooks_[0]);
        assertEq(rules[0], rules_[0]);
        vm.prank(pill);
        MOLECULES.setController(molyhash, faker);
        vm.prank(faker);
        vm.expectRevert(abi.encodePacked("RULE_EXISTS"));
        MOLECULES.hook(molyhash, config[0], rules[0]);
        vm.prank(faker);
        vm.expectRevert(abi.encodePacked("RULE_EXISTS"));
        MOLECULES.hook(molyhash, config[1], rules[0]);
        vm.prank(faker);
        MOLECULES.hook(molyhash, config[1], rules[1]);
        vm.prank(faker);
        MOLECULES.rehook(molyhash, config[0], rules[1]);
        (uint8[] memory rules__, address[] memory hooks__) = MOLECULES
            .hooksWithRules(molyhash);
        assertEq(config[0], hooks__[1]);
        assertEq(rules[1], rules__[1]);
    }

    /// Register a molecule and attempt to unhook a hook
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
        // register test molecule linking (1 + n) names
        molyhash = _MOLY_.newMolecule{value: molyprice * lifespan}(
            label,
            cation,
            anions,
            lifespan
        );
        // register name to transfer to
        fakehash = _NAME_.newName{value: namePrice * (lifespan + 1)}(
            brown,
            faker,
            lifespan + 1
        );
        assertEq(MOLECULES.recordExists(molyhash), true);
        vm.prank(pill);
        MOLECULES.hook(molyhash, config[0], rules[0]);
        vm.prank(pill);
        MOLECULES.unhook(molyhash, rules[0]);
        (uint8[] memory rules_, address[] memory hooks_) = MOLECULES
            .hooksWithRules(molyhash);
        assertEq(hooks_.length, 1);
        assertEq(rules_.length, 1);
        vm.prank(pill);
        MOLECULES.setController(molyhash, faker);
        vm.prank(faker);
        vm.expectRevert(
            abi.encodeWithSelector(Helix2MoleculeRegistry.BAD_HOOK.selector)
        );
        MOLECULES.unhook(molyhash, rules[0]);
        vm.prank(faker);
        MOLECULES.hook(molyhash, config[1], rules[1]);
        (uint8[] memory rules__, address[] memory hooks__) = MOLECULES
            .hooksWithRules(molyhash);
        assertEq(config[1], hooks__[1]);
        assertEq(rules[1], rules__[1]);
        assertEq(rules__.length, uint(2));
        assertEq(hooks__.length, uint(2));
    }
}
