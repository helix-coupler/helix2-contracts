// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../src/Core/Diamond.sol";
import "../../src/Core/interfaces/iDiamondCut.sol";
import "../../src/Core/facets/DiamondCutFacet.sol";
import "../../src/Core/facets/DiamondLoupeFacet.sol";
import "../../src/Core/facets/ERCFacet.sol";
import "../../src/Core/facets/ViewFacet.sol";
import "../../src/Core/facets/WriteFacet.sol";
import "./HelperContract.sol";

abstract contract StateDeployDiamond is HelperContract {
    //contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    ERCFacet ercFacet;

    //interfaces with Facet ABI connected to diamond address
    iDiamondLoupe iLoupe;
    iDiamondCut iCut;

    string[] facetNames;
    address[] facetAddressList;

    // deploys diamond and connects facets
    function setUp() public virtual {
        //deploy facets
        dCutFacet = new DiamondCutFacet();
        dLoupe = new DiamondLoupeFacet();
        ercFacet = new ERCFacet();
        facetNames = ["DiamondCutFacet", "DiamondLoupeFacet", "ERCFacet"];

        // diamod arguments
        Initialiser memory _args = Initialiser({
            Dev: address(this),
            init: address(0),
            initCalldata: " "
        });

        // FacetCut with CutFacet for initialisation
        FacetCut[] memory cut0 = new FacetCut[](1);
        cut0[0] = FacetCut({
            facetAddress: address(dCutFacet),
            action: iDiamond.FacetCutAction.Add,
            functionSelectors: generateSelectors("DiamondCutFacet")
        });

        // deploy diamond
        diamond = new Diamond(cut0, _args);

        //upgrade diamond with facets

        //build cut struct
        FacetCut[] memory cut = new FacetCut[](2);

        cut[0] = (
            FacetCut({
                facetAddress: address(dLoupe),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("DiamondLoupeFacet")
            })
        );

        cut[1] = (
            FacetCut({
                facetAddress: address(ercFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("ERCFacet")
            })
        );

        // initialise interfaces
        iLoupe = iDiamondLoupe(address(diamond));
        iCut = iDiamondCut(address(diamond));

        //upgrade diamond
        iCut.diamondCut(cut, address(0x0), "");

        // get all addresses
        facetAddressList = iLoupe.facetAddresses();
    }
}

// tests proper upgrade of diamond when adding a facet
abstract contract StateAddViewFacet is StateDeployDiamond {
    ViewFacet viewFacet;

    function setUp() public virtual override {
        super.setUp();
        //deploy ViewFacet
        viewFacet = new ViewFacet();

        // get functions selectors but remove first element (supportsInterface)
        bytes4[] memory fromGenSelectors = generateSelectors("ViewFacet");

        // array of functions to add
        FacetCut[] memory facetCut = new FacetCut[](1);
        facetCut[0] = FacetCut({
            facetAddress: address(viewFacet),
            action: FacetCutAction.Add,
            functionSelectors: fromGenSelectors
        });

        // add functions to diamond
        iCut.diamondCut(facetCut, address(0x0), "");
    }
}

abstract contract StateAddWriteFacet is StateAddViewFacet {
    WriteFacet writeFacet;

    function setUp() public virtual override {
        super.setUp();
        //deploy ViewFacet
        writeFacet = new WriteFacet();

        // get functions selectors
        bytes4[] memory fromGenSelectors = generateSelectors("WriteFacet");

        // array of functions to add
        FacetCut[] memory facetCut = new FacetCut[](1);
        facetCut[0] = FacetCut({
            facetAddress: address(writeFacet),
            action: FacetCutAction.Add,
            functionSelectors: fromGenSelectors
        });

        // add functions to diamond
        iCut.diamondCut(facetCut, address(0x0), "");
    }
}

abstract contract StateCacheBug is StateDeployDiamond {
    ViewFacet viewFacet;

    bytes4 ercSelector = hex"8da5cb5b";
    bytes4[] selectors;

    function setUp() public virtual override {
        super.setUp();
        viewFacet = new ViewFacet();

        selectors.push(hex"19e3b533");
        selectors.push(hex"0716c2ae");
        selectors.push(hex"11046047");
        selectors.push(hex"cf3bbe18");
        selectors.push(hex"24c1d5a7");
        selectors.push(hex"cbb835f6");
        selectors.push(hex"cbb835f7");
        selectors.push(hex"cbb835f8");
        selectors.push(hex"cbb835f9");
        selectors.push(hex"cbb835fa");
        selectors.push(hex"cbb835fb");

        FacetCut[] memory cut = new FacetCut[](1);
        bytes4[] memory selectorsAdd = new bytes4[](11);

        for (uint i = 0; i < selectorsAdd.length; i++) {
            selectorsAdd[i] = selectors[i];
        }

        cut[0] = FacetCut({
            facetAddress: address(viewFacet),
            action: FacetCutAction.Add,
            functionSelectors: selectorsAdd
        });

        // add viewFacet to diamond
        iCut.diamondCut(cut, address(0x0), "");

        // Remove selectors from diamond
        bytes4[] memory newSelectors = new bytes4[](3);
        newSelectors[0] = ercSelector;
        newSelectors[1] = selectors[5];
        newSelectors[2] = selectors[10];

        cut[0] = FacetCut({
            facetAddress: address(0x0),
            action: FacetCutAction.Remove,
            functionSelectors: newSelectors
        });

        iCut.diamondCut(cut, address(0x0), "");
    }
}
