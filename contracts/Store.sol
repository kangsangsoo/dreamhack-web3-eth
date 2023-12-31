pragma solidity ^0.8.0;

contract Store {

    struct DiscountInfo {
        uint256 blockNumber;
        uint[] discountedItems;
        uint[] discountedPrices;
        bytes32 discountCoupon;
    }

    struct Buy {
        uint256[] ids;
        uint256[] prices;
        uint256[] amounts;
    }

    uint256 public constant REGULAR_PRICE = 0.1 ether;
    uint256 public constant PER_N_ITEM = 5;
    bytes public constant  ALPHABETS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

    // blockNumber -> discountInfo
    mapping (uint256 => DiscountInfo) public discountInfos;
    // coupon -> bool
    mapping (bytes32 => bool) public used; 
    // nonce -> bool
    mapping(uint256 => bool) public nonces;
    // owner => alphabet => amount
    mapping(address => mapping(bytes1 => uint256)) public totalBalances;

    error InvalidRange();
    error AlreadyUsed();
    error NotIssued();
    error NotMatched();
    error LowLevelFailed();

    constructor() {
    }

    // [_lowerBound, _upperBound]
    function randRangeWithNonce(uint256 _blockNumber, uint256 _lowerBound, uint256 _upperBound, uint256 _nonce) internal returns (uint256) {
        if (_lowerBound > _upperBound) revert InvalidRange();
        if (nonces[_nonce]) revert AlreadyUsed();
        nonces[_nonce] = true;
        bytes memory _seeds = (abi.encode(msg.sender, _blockNumber, _lowerBound + _upperBound, _nonce));
        return (uint256(keccak256(_seeds)) % (_upperBound - _lowerBound + 1)) + _lowerBound;
    }

    // allow duplicates
    function randSample(uint256 _blockNumber, uint256[] memory _nonces) internal returns (uint[] memory) {
        uint len = PER_N_ITEM;
        uint[] memory _samples = new uint[](len); 
        for(uint i = 0; i < len; i++) {
            _samples[i] = randRangeWithNonce(_blockNumber, uint8(ALPHABETS[0]), uint8(ALPHABETS[0]) + ALPHABETS.length - 1, _nonces[i]);
        }
        return _samples;
    }

    function getDiscountInfo(uint256 blockNumber) public view returns(uint[] memory, uint[] memory, bytes32) {
        return (discountInfos[blockNumber].discountedItems, discountInfos[blockNumber].discountedPrices, discountInfos[blockNumber].discountCoupon);
    }
    
    function issueDiscountCoupon(uint256 _blockNumber, uint256[] memory _nonce) public returns(uint, uint256[] memory, uint256[] memory, bytes32) {

        DiscountInfo storage _discountInfo = discountInfos[_blockNumber];

        uint256[] memory _prices = new uint256[](PER_N_ITEM);
        uint256[] memory _ids = randSample(_blockNumber, _nonce);

        for(uint256 i = 0; i < PER_N_ITEM; i++) {
            uint256 _price = randRangeWithNonce(_blockNumber, 0.0714285714285 ether, 0.09 ether, _nonce[PER_N_ITEM+i]);
            _prices[i] = _price;
        }

        bytes memory _input = abi.encodePacked(_blockNumber);

        for(uint256 i = 0; i < PER_N_ITEM; i++) {
            _input = abi.encodePacked(_input, _ids[i]);
        }

        for(uint256 id = 0; id < PER_N_ITEM; id++) {
            _input = abi.encodePacked(_input, _prices[id]);
        }

        bytes32 hash = keccak256(_input);

        _discountInfo.blockNumber = _blockNumber;
        _discountInfo.discountedItems = _ids;
        _discountInfo.discountedPrices = _prices;
        _discountInfo.discountCoupon = hash;

        return (_blockNumber, _ids, _prices, hash);
    }

    function buyWithCoupon(bytes32 _coupon, uint256[] memory _ids, uint256[] memory _prices, uint256[] memory _amounts) public payable {
        if (discountInfos[block.number].discountCoupon != _coupon || discountInfos[block.number].discountCoupon == 0) revert NotIssued();
        if (used[_coupon]) revert AlreadyUsed();
        bytes memory _input = abi.encodePacked(block.number);

        for(uint256 i = 0; i < _ids.length; i++) {
            _input = abi.encodePacked(_input, _ids[i]);
        }

        for(uint256 i = 0; i < _prices.length; i++) {
            _input = abi.encodePacked(_input, _prices[i]);
        }

        bytes32 _hash = keccak256(_input);
        if (_hash != _coupon) revert NotMatched();
        used[_coupon] = true;

        uint256 _totalAmount = 0;
        for(uint256 i = 0; i < _ids.length; i++) {
            uint256 _amount = _amounts[i];
            _totalAmount += _prices[i] * _amount;
            totalBalances[msg.sender][bytes1(uint8(_ids[i]))] += _amount;
        }

        require(_totalAmount <= msg.value);

        uint256 left = (msg.value - _totalAmount);
        if (left > 0) {
            (bool success, bytes memory data) = msg.sender.call{value: left}("");
            if(!success) revert LowLevelFailed();
        }

    }

    function buy(uint256[] memory _ids, uint256[] memory _amounts) public payable {

        uint256 _totalAmount = 0;
        for(uint256 i = 0; i < _ids.length; i++) {
            uint256 _amount = _amounts[i];
            _totalAmount += REGULAR_PRICE * _amount;
            totalBalances[msg.sender][bytes1(uint8(_ids[i]))] += _amount;
        }

        require(_totalAmount <= msg.value);

        uint256 left = (msg.value - _totalAmount);
        if (left > 0) {
            (bool success, bytes memory data) = msg.sender.call{value: left}("");
            if(!success) revert LowLevelFailed();
        }
    }

    function resell(uint256 _id, uint256 _amount) public {
        if (totalBalances[msg.sender][bytes1(uint8(_id))] < _amount) _amount = totalBalances[msg.sender][bytes1(uint8(_id))];
        totalBalances[msg.sender][bytes1(uint8(_id))] -= _amount;
        uint256 _amt = _amount * REGULAR_PRICE / 2;
        (bool success, bytes memory data) = msg.sender.call{value: _amt}("");
        if(!success) revert LowLevelFailed();
    }

    function give(uint256 _id, uint256 _amount, address _to) public {       
        if (totalBalances[msg.sender][bytes1(uint8(_id))] < _amount) _amount = totalBalances[msg.sender][bytes1(uint8(_id))];
        totalBalances[msg.sender][bytes1(uint8(_id))] -= _amount;
        totalBalances[_to][bytes1(uint8(_id))] += _amount;
    }

    receive() payable external {}
}