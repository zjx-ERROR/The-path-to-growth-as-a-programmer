// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.34;

contract IntToRoman {
    constructor() {}

    function intToRoman(uint256 input) public pure returns (string memory) {
        require(input > 0 && input <= 3999, "input must be 1..3999");

        bytes memory buffer = new bytes(15);
        uint256 pos = 0;

        uint16[13] memory values = [
            1000,
            900,
            500,
            400,
            100,
            90,
            50,
            40,
            10,
            9,
            5,
            4,
            1
        ];
        string[13] memory symbols = [
            "M",
            "CM",
            "D",
            "CD",
            "C",
            "XC",
            "L",
            "XL",
            "X",
            "IX",
            "V",
            "IV",
            "I"
        ];

        for (uint256 i = 0; i < values.length; i++) {
            while (input >= values[i]) {
                input -= values[i];
                bytes memory sym = bytes(symbols[i]);
                for (uint256 j = 0; j < sym.length; j++) {
                    buffer[pos++] = sym[j];
                }
            }
        }
        bytes memory result = new bytes(pos);
        for (uint256 i = 0; i < pos; i++) {
            result[i] = buffer[i];
        }
        return string(result);
    }

    function mergeSortedArray(uint256[] memory arrayA,uint256[] memory arrayB) public pure returns(uint256[] memory){
        uint256 x = 0;
        uint256 y = 0;
        uint256 k = 0;
        uint256 lengthA = arrayA.length;
        uint256 lengthB = arrayB.length;
        uint256[] memory output = new uint256[](lengthA+lengthB);

        while (x<lengthA && y<lengthB) 
        {
            if (arrayA[x] > arrayB[y]) {
                output[k++] = arrayB[y++];
            }else{
                output[k++] = arrayA[x++];
            }
        }
        while (x<lengthA) 
        {
            output[k++]=arrayA[x++];
        }
        while (y<lengthB) 
        {
            output[k++]=arrayB[y++];
        }
        return output;
    }

    function binarySearch(int256[] memory array,int256 target) public pure returns(uint256){
        
        uint256 length = array.length;
        if (length<=0){
            return type(uint256).max;
        }
        uint256 left = 0;
        uint256 right = length - 1;


        while (left<=right) 
        {
            uint256 idx = (left+right) / 2;
            if (array[idx]==target){
                return idx; 
            }else if (array[idx] > target){
                if (idx == 0) {
                    break;
                }
                right = idx - 1;
            }else{
                left = idx+1;
            }
        }
        return type(uint256).max;
        
    }
}
