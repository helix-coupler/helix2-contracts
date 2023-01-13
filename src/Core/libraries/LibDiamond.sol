// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {iDiamond} from "../interfaces/iDiamond.sol";
import {iDiamondCut} from "../interfaces/iDiamondCut.sol";

// Revert events
error NoSelectorsGivenToAdd();
error NotContractOwner(address _user, address _contractOwner);
error NoSelectorsProvidedForFacetForCut(address _facetAddress);
error CannotAddSelectorsToZeroAddress(bytes4[] _selectors);
error NoBytecodeAtAddress(address _contractAddress, string _message);
error IncorrectFacetCutAction(uint8 _action);
error CannotAddFunctionToDiamondThatAlreadyExists(bytes4 _selector);
error CannotReplaceFunctionsFromFacetWithZeroAddress(bytes4[] _selectors);
error CannotReplaceImmutableFunction(bytes4 _selector);
error CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(
    bytes4 _selector
);
error CannotReplaceFunctionThatDoesNotExists(bytes4 _selector);
error RemoveFacetAddressMustBeZeroAddress(address _facetAddress);
error CannotRemoveFunctionThatDoesNotExist(bytes4 _selector);
error CannotRemoveImmutableFunction(bytes4 _selector);
error InitializationFunctionReverted(
    address _initializationContractAddress,
    bytes _calldata
);

/**
 * @dev EIP-2535 Diamond Cut Facet
 */
library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndSelectorPosition {
        address facetAddress;
        uint16 selectorPosition;
    }

    /// @notice Diamond Storage
    struct DiamondStorage {
        /// @dev : function selector => facet address and selector position in selectors array
        mapping(bytes4 => FacetAddressAndSelectorPosition) facetAddressAndSelectorPosition;
        bytes4[] selectors;
        mapping(bytes4 => bool) supportedInterfaces;
        address Dev;
        /// @dev : set custom variables here
        // Helix2 Core Variables
        string[4] illegalBlocks; // forbidden characters
        uint256[2][4] sizes; // label sizes for each struct in order [<name>, <bond>, <molecule>, <polycule>]
        uint256[4] lifespans; // default lifespans in seconds for each struct in order [<name>, <bond>, <molecule>, <polycule>]
        bytes32[4] roothash; // Root identifier
        address ensRegistry; // ENS Registry
        address[4] helix2Registry; // Helix2 Registries
        address[4] helix2Registrar; // Helix2 Registrars
        bool active; // pause/resume contract
    }

    /// @dev : Storage access function
    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @dev : Events
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event NewLives(uint256[4] newLives);
    event NewLife(uint256 index, uint256 newLife);
    event NewRegisteries(address[4] newReg);
    event NewRegistry(uint256 index, address newReg);
    event NewRegistrars(address[4] newReg);
    event NewRegistrar(uint256 index, address newReg);
    event NewENSRegistry(address newReg);

    /// @notice Diamond External Functions
    /// @dev : Modifier to allow only dev
    function onlyDev() internal view {
        require(msg.sender == diamondStorage().Dev, "NOT_DEV");
    }

    /**
     * @dev transfer contract ownership to new Dev
     * @param _newDev : new Dev
     */
    function setDev(address _newDev) internal {
        address previousOwner = diamondStorage().Dev;
        diamondStorage().Dev = _newDev;
        emit OwnershipTransferred(previousOwner, _newDev);
    }

    /**
     * @dev sets new list of lifespans
     * @param _newLives : list of new lifespans
     */
    function setLives(uint256[4] calldata _newLives) internal {
        diamondStorage().lifespans = _newLives;
        emit NewLives(_newLives);
    }

    /**
     * @dev replace single lifespan value
     * @param index : index to replace (starts from 0)
     * @param _newLife : new lifespan for index
     */
    function setLife(uint256 index, uint256 _newLife) internal {
        diamondStorage().lifespans[index] = _newLife;
        emit NewLife(index, _newLife);
    }

    /**
     * @dev migrate all Helix2 Registeries
     * @param newReg : new Registry array
     */
    function setRegisteries(address[4] calldata newReg) internal {
        diamondStorage().helix2Registry = newReg;
        emit NewRegisteries(newReg);
    }

    /**
     * @dev replace one index of Helix2 Register
     * @param index : index to replace (starts from 0)
     * @param newReg : new Register for index
     */
    function setRegistry(uint256 index, address newReg) internal {
        diamondStorage().helix2Registry[index] = newReg;
        emit NewRegistry(index, newReg);
    }

    /**
     * @dev migrate all Helix2 Registrars
     * @param newReg : new Registrar array
     */
    function setRegistrars(address[4] calldata newReg) internal {
        diamondStorage().helix2Registrar = newReg;
        emit NewRegistrars(newReg);
    }

    /**
     * @dev replace one index of Helix2 Registrar
     * @param index : index to replace (starts from 0)
     * @param newReg : new Registrar for index
     */
    function setRegistrar(uint256 index, address newReg) internal {
        diamondStorage().helix2Registrar[index] = newReg;
        emit NewRegistrar(index, newReg);
    }

    /**
     * @dev sets ENS Registry if it migrates
     * @param newReg : new Register for index
     */
    function setENSRegistry(address newReg) internal {
        diamondStorage().ensRegistry = newReg;
        emit NewENSRegistry(newReg);
    }

    /// @dev returns owner of contract
    function Dev() internal view returns (address) {
        return diamondStorage().Dev;
    }

    /// @dev checks if an interface is supported
    function checkInterface(bytes4 sig) internal view returns (bool) {
        return diamondStorage().supportedInterfaces[sig];
    }

    /// @dev checks if an interface is supported
    function _setInterface(bytes4 sig, bool value) internal {
        diamondStorage().supportedInterfaces[sig] = value;
    }

    /// @dev returns illegal blocks list
    function illegalBlocks() internal view returns (string[4] memory) {
        return diamondStorage().illegalBlocks;
    }

    /// @dev returns illegal sizes list
    function sizes() internal view returns (uint256[2][4] memory) {
        return diamondStorage().sizes;
    }

    /// @dev returns lifespans array
    function lifespans() internal view returns (uint256[4] memory) {
        return diamondStorage().lifespans;
    }

    /// @dev returns Registeries
    function registries() internal view returns (address[4] memory) {
        return diamondStorage().helix2Registry;
    }

    /// @dev returns Registrars
    function registrars() internal view returns (address[4] memory) {
        return diamondStorage().helix2Registrar;
    }

    /// @dev returns hashes of root labels
    function roothash() internal view returns (bytes32[4] memory) {
        return diamondStorage().roothash;
    }

    /// @dev returns ENS Registry address
    function ensRegistry() internal view returns (address) {
        return diamondStorage().ensRegistry;
    }

    /// @notice Diamond Section
    event DiamondCut(
        iDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    /// @dev : Internal function version of diamondCut
    function diamondCut(
        iDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (
            uint256 facetIndex;
            facetIndex < _diamondCut.length;
            facetIndex++
        ) {
            bytes4[] memory functionSelectors = _diamondCut[facetIndex]
                .functionSelectors;
            address facetAddress = _diamondCut[facetIndex].facetAddress;
            if (functionSelectors.length == 0) {
                revert NoSelectorsProvidedForFacetForCut(facetAddress);
            }
            iDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == iDiamond.FacetCutAction.Add) {
                addFunctions(facetAddress, functionSelectors);
            } else if (action == iDiamond.FacetCutAction.Replace) {
                replaceFunctions(facetAddress, functionSelectors);
            } else if (action == iDiamond.FacetCutAction.Remove) {
                removeFunctions(facetAddress, functionSelectors);
            } else {
                revert IncorrectFacetCutAction(uint8(action));
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        if (_facetAddress == address(0)) {
            revert CannotAddSelectorsToZeroAddress(_functionSelectors);
        }
        DiamondStorage storage ds = diamondStorage();
        uint16 selectorCount = uint16(ds.selectors.length);
        enforceHasContractCode(_facetAddress, "EMPTY_FACET");
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .facetAddressAndSelectorPosition[selector]
                .facetAddress;
            if (oldFacetAddress != address(0)) {
                revert CannotAddFunctionToDiamondThatAlreadyExists(selector);
            }
            ds.facetAddressAndSelectorPosition[
                selector
            ] = FacetAddressAndSelectorPosition(_facetAddress, selectorCount);
            ds.selectors.push(selector);
            selectorCount++;
        }
    }

    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        DiamondStorage storage ds = diamondStorage();
        if (_facetAddress == address(0)) {
            revert CannotReplaceFunctionsFromFacetWithZeroAddress(
                _functionSelectors
            );
        }
        enforceHasContractCode(_facetAddress, "EMPTY_FACET");
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .facetAddressAndSelectorPosition[selector]
                .facetAddress;
            // can't replace immutable functions -- functions defined directly in the diamond in this case
            if (oldFacetAddress == address(this)) {
                revert CannotReplaceImmutableFunction(selector);
            }
            if (oldFacetAddress == _facetAddress) {
                revert CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(
                    selector
                );
            }
            if (oldFacetAddress == address(0)) {
                revert CannotReplaceFunctionThatDoesNotExists(selector);
            }
            // replace old facet address
            ds
                .facetAddressAndSelectorPosition[selector]
                .facetAddress = _facetAddress;
        }
    }

    function removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        if (_facetAddress != address(0)) {
            revert RemoveFacetAddressMustBeZeroAddress(_facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            FacetAddressAndSelectorPosition
                memory oldFacetAddressAndSelectorPosition = ds
                    .facetAddressAndSelectorPosition[selector];
            if (oldFacetAddressAndSelectorPosition.facetAddress == address(0)) {
                revert CannotRemoveFunctionThatDoesNotExist(selector);
            }

            // can't remove immutable functions -- functions defined directly in the diamond
            if (
                oldFacetAddressAndSelectorPosition.facetAddress == address(this)
            ) {
                revert CannotRemoveImmutableFunction(selector);
            }
            // replace selector with last selector
            selectorCount--;
            if (
                oldFacetAddressAndSelectorPosition.selectorPosition !=
                selectorCount
            ) {
                bytes4 lastSelector = ds.selectors[selectorCount];
                ds.selectors[
                    oldFacetAddressAndSelectorPosition.selectorPosition
                ] = lastSelector;
                ds
                    .facetAddressAndSelectorPosition[lastSelector]
                    .selectorPosition = oldFacetAddressAndSelectorPosition
                    .selectorPosition;
            }
            // delete last selector
            ds.selectors.pop();
            delete ds.facetAddressAndSelectorPosition[selector];
        }
    }

    function initializeDiamondCut(
        address _init,
        bytes memory _calldata
    ) internal {
        if (_init == address(0)) {
            return;
        }
        enforceHasContractCode(_init, "EMPTY_INIT");
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }
    }

    function enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        if (contractSize == 0) {
            revert NoBytecodeAtAddress(_contract, _errorMessage);
        }
    }
}
