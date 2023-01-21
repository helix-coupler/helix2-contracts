// SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

library LibString {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint256 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev returns the length of a given string
     * @param _string string to measure the length of
     * @return length of the input string
     */
    function strlen(string memory _string) internal pure returns (uint256) {
        uint256 _length;
        uint256 i = 0;
        uint256 bytelength = bytes(_string).length;
        for (_length = 0; i < bytelength; _length++) {
            bytes1 _byte = bytes(_string)[i];
            if (_byte < 0x80) {
                i += 1;
            } else if (_byte < 0xE0) {
                i += 2;
            } else if (_byte < 0xF0) {
                i += 3;
            } else if (_byte < 0xF8) {
                i += 4;
            } else if (_byte < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return _length;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     * @notice openzeppelin-contracts/contracts/utils/Strings.sol
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(
        uint256 value,
        uint256 length
    ) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     * From openzeppelin-contracts/contracts/utils/math/Math.sol
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            uint i = 128;
            while (i > 1) {
                i /= 2;
                if (value >= 10 ** i) {
                    value /= 10 ** i;
                    result += i;
                }
            }
            //(uint i =64; i >=0))
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     * From openzeppelin-contracts/contracts/utils/math/Math.sol
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev check if a value exists in a calldata array of size 4
     * @param array : array to search in
     * @param value : value to search
     * @return true or false
     */
    function existsIn(
        string memory value,
        string[4] memory array
    ) internal pure returns (bool) {
        for (uint i = 0; i < array.length; i++) {
            if (
                keccak256(abi.encodePacked(array[i])) ==
                keccak256(abi.encodePacked(value))
            ) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev check if a value exists in a dynamic memory array of addresses
     * @param array : array of addresses to search in
     * @param value : value to search
     * @return true or false
     */
    function existsIn(
        address value,
        address[] memory array
    ) internal pure returns (bool) {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev find an element in a dynamic memory array of addresses
     * @param array : array of addresses to search in
     * @param value : value to search
     * @return index
     */
    function findIn(
        address value,
        address[] memory array
    ) internal pure returns (uint) {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return i;
            }
        }
        return uint(0);
    }

    /**
     * @dev check if a value exists in a dynamic memory array of bytes32
     * @param array : array of bytes32 to search in
     * @param value : value to search
     * @return true or false
     */
    function existsIn(
        bytes32 value,
        bytes32[] memory array
    ) internal pure returns (bool) {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev check if a value exists in a dynamic memory array of uint256
     * @param array : array of uint256 to search in
     * @param value : value to search
     * @return true or false
     */
    function existsIn(
        uint256 value,
        uint256[] memory array
    ) internal pure returns (bool) {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev find an element in a dynamic memory array of bytes32
     * @param array : array of bytes32 to search in
     * @param value : value to search
     * @return index
     */
    function findIn(
        bytes32 value,
        bytes32[] memory array
    ) internal pure returns (uint) {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return i;
            }
        }
        return uint(0);
    }

    /**
     * @dev find an element in a dynamic memory array of uint256
     * @param array : array of uint256 to search in
     * @param value : value to search
     * @return index
     */
    function findIn(
        uint256 value,
        uint256[] memory array
    ) internal pure returns (uint) {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return i;
            }
        }
        return uint(0);
    }
}
