// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/console2.sol";
import "./utils/TestStates.sol";
import {LibDiamond} from "../src/Core/libraries/LibDiamond.sol";

error CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(
    bytes4 _selector
);

// test proper deployment of diamond
contract TestDeployDiamond is StateDeployDiamond {
    // TEST CASES

    function test1HasThreeFacets() public {
        assertEq(facetAddressList.length, 3);
    }

    function writeFacetsHaveCorrectSelectors() public {
        for (uint i = 0; i < facetAddressList.length; i++) {
            bytes4[] memory fromLoupeFacet = iLoupe.facetFunctionSelectors(
                facetAddressList[i]
            );
            bytes4[] memory fromGenSelectors = generateSelectors(facetNames[i]);
            assertTrue(sameMembers(fromLoupeFacet, fromGenSelectors));
        }
    }

    function test3SelectorsAssociatedWithCorrectFacet() public {
        for (uint i = 0; i < facetAddressList.length; i++) {
            bytes4[] memory fromGenSelectors = generateSelectors(facetNames[i]);
            for (uint j = 0; j < fromGenSelectors.length; j++) {
                assertEq(
                    facetAddressList[i],
                    iLoupe.facetAddress(fromGenSelectors[j])
                );
            }
        }
    }
}

contract TestAddViewFacet is StateAddViewFacet {
    function test4AddViewFacetFunctions() public {
        // check if functions added to diamond
        bytes4[] memory fromLoupeFacet = iLoupe.facetFunctionSelectors(
            address(viewFacet)
        );
        bytes4[] memory fromGenSelectors = generateSelectors("ViewFacet");
        assertTrue(sameMembers(fromLoupeFacet, fromGenSelectors));
    }

    function test5CanCallViewFacetFunction() public view {
        // try to call function on new Facet
        ViewFacet(address(diamond)).getSizes();
    }

    function test6ReplaceSupportsInterfaceFunction() public {
        // get supportsInterface selector from positon 0
        bytes4[] memory fromGenSelectors = new bytes4[](1);
        fromGenSelectors[0] = generateSelectors("ViewFacet")[0];

        // struct to replace function
        FacetCut[] memory cutView = new FacetCut[](1);
        cutView[0] = FacetCut({
            facetAddress: address(viewFacet),
            action: FacetCutAction.Replace,
            functionSelectors: fromGenSelectors
        });
        vm.expectRevert(
            abi.encodeWithSelector(
                CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet
                    .selector,
                bytes4(fromGenSelectors[0])
            )
        );
        // replace function by function on View facet
        iCut.diamondCut(cutView, address(0x0), "");

        // check supportsInterface method connected to viewFacet
        assertEq(address(viewFacet), iLoupe.facetAddress(fromGenSelectors[0]));
    }
}

contract TestAddWriteFacet is StateAddWriteFacet {
    function test7AddWriteFacetFunctions() public {
        // check if functions added to diamond
        bytes4[] memory fromLoupeFacet = iLoupe.facetFunctionSelectors(
            address(writeFacet)
        );
        bytes4[] memory fromGenSelectors = generateSelectors("WriteFacet");
        assertTrue(sameMembers(fromLoupeFacet, fromGenSelectors));
    }

    function test8RemoveSomeWriteFacetFunctions() public {
        bytes4[] memory functionsToKeep = new bytes4[](5);
        functionsToKeep[0] = writeFacet.setLives.selector;
        functionsToKeep[1] = writeFacet.setLife.selector;
        functionsToKeep[2] = writeFacet.setRegistrar.selector;
        functionsToKeep[3] = writeFacet.setRegistrars.selector;
        functionsToKeep[4] = writeFacet.setENSRegistry.selector;

        bytes4[] memory selectors = iLoupe.facetFunctionSelectors(
            address(writeFacet)
        );
        for (uint i = 0; i < functionsToKeep.length; i++) {
            selectors = removeElement(functionsToKeep[i], selectors);
        }

        // array of functions to remove
        FacetCut[] memory facetCut = new FacetCut[](1);
        facetCut[0] = FacetCut({
            facetAddress: address(0x0),
            action: FacetCutAction.Remove,
            functionSelectors: selectors
        });

        // add functions to diamond
        iCut.diamondCut(facetCut, address(0x0), "");

        bytes4[] memory fromLoupeFacet = iLoupe.facetFunctionSelectors(
            address(writeFacet)
        );
        assertTrue(sameMembers(fromLoupeFacet, functionsToKeep));
    }

    function test9RemoveSomeViewFacetFunctions() public {
        bytes4[] memory functionsToKeep = new bytes4[](3);
        functionsToKeep[0] = viewFacet.getSizes.selector;
        functionsToKeep[1] = viewFacet.getLifespans.selector;
        functionsToKeep[2] = viewFacet.getRegistry.selector;

        bytes4[] memory selectors = iLoupe.facetFunctionSelectors(
            address(viewFacet)
        );
        for (uint i = 0; i < functionsToKeep.length; i++) {
            selectors = removeElement(functionsToKeep[i], selectors);
        }

        // array of functions to remove
        FacetCut[] memory facetCut = new FacetCut[](1);
        facetCut[0] = FacetCut({
            facetAddress: address(0x0),
            action: FacetCutAction.Remove,
            functionSelectors: selectors
        });

        // add functions to diamond
        iCut.diamondCut(facetCut, address(0x0), "");

        bytes4[] memory fromLoupeFacet = iLoupe.facetFunctionSelectors(
            address(viewFacet)
        );
        assertTrue(sameMembers(fromLoupeFacet, functionsToKeep));
    }

    function test10RemoveAllExceptDiamondCutAndFacetFunction() public {
        bytes4[] memory selectors = getAllSelectors(address(diamond));

        bytes4[] memory functionsToKeep = new bytes4[](2);
        functionsToKeep[0] = DiamondCutFacet.diamondCut.selector;
        functionsToKeep[1] = DiamondLoupeFacet.facets.selector;

        selectors = removeElement(functionsToKeep[0], selectors);
        selectors = removeElement(functionsToKeep[1], selectors);

        // array of functions to remove
        FacetCut[] memory facetCut = new FacetCut[](1);
        facetCut[0] = FacetCut({
            facetAddress: address(0x0),
            action: FacetCutAction.Remove,
            functionSelectors: selectors
        });

        // remove functions from diamond
        iCut.diamondCut(facetCut, address(0x0), "");

        Facet[] memory facets = iLoupe.facets();
        bytes4[] memory testselector = new bytes4[](1);

        assertEq(facets.length, 2);

        assertEq(facets[0].facetAddress, address(dCutFacet));

        testselector[0] = functionsToKeep[0];
        assertTrue(sameMembers(facets[0].functionSelectors, testselector));

        assertEq(facets[1].facetAddress, address(dLoupe));
        testselector[0] = functionsToKeep[1];
        assertTrue(sameMembers(facets[1].functionSelectors, testselector));
    }
}

contract TestCacheBug is StateCacheBug {
    function testNoCacheBug() public {
        bytes4[] memory fromLoupeSelectors = iLoupe.facetFunctionSelectors(
            address(viewFacet)
        );

        assertTrue(containsElement(fromLoupeSelectors, selectors[0]));
        assertTrue(containsElement(fromLoupeSelectors, selectors[1]));
        assertTrue(containsElement(fromLoupeSelectors, selectors[2]));
        assertTrue(containsElement(fromLoupeSelectors, selectors[3]));
        assertTrue(containsElement(fromLoupeSelectors, selectors[4]));
        assertTrue(containsElement(fromLoupeSelectors, selectors[6]));
        assertTrue(containsElement(fromLoupeSelectors, selectors[7]));
        assertTrue(containsElement(fromLoupeSelectors, selectors[8]));
        assertTrue(containsElement(fromLoupeSelectors, selectors[9]));

        assertFalse(containsElement(fromLoupeSelectors, ownerSel));
        assertFalse(containsElement(fromLoupeSelectors, selectors[10]));
        assertFalse(containsElement(fromLoupeSelectors, selectors[5]));
    }
}
