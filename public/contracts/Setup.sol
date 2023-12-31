pragma solidity ^0.8.0;

import "./Store.sol";
import "./House.sol";

contract Setup {
    Store public immutable store;
    House public immutable house;
    bool public isStarted;

    constructor() payable {
        store = new Store();
        house = new House();
    }

    function isSolved() external view returns (bool) {
        return 
        store.totalBalances(address(house), "A") >= 1
        && store.totalBalances(address(house), "C") >= 1
        && store.totalBalances(address(house), "E") >= 1
        && store.totalBalances(address(house), "H") >= 1
        && store.totalBalances(address(house), "I") >= 1
        && store.totalBalances(address(house), "M") >= 2
        && store.totalBalances(address(house), "R") >= 3
        && store.totalBalances(address(house), "S") >= 2
        && store.totalBalances(address(house), "T") >= 1
        && store.totalBalances(address(house), "Y") >= 1;
    }
}