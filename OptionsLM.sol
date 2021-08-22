// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

library Strings {
    function toString(uint value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint temp = value;
        uint digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + (temp % 10)));
            temp /= 10;
        }
        return string(buffer);
    }
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint balance);
    function ownerOf(uint tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint tokenId) external;
    function transferFrom(address from, address to, uint tokenId) external;
    function approve(address to, uint tokenId) external;
    function getApproved(uint tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint tokenId, bytes calldata data) external;
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint tokenId) external view returns (string memory);
}

interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint);
    function tokenOfOwnerByIndex(address owner, uint index) external view returns (uint tokenId);
    function tokenByIndex(uint index) external view returns (uint);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint tokenId, bytes calldata data)
    external returns (bytes4);
}

contract ERC165 is IERC165 {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () {
        _registerInterface(_INTERFACE_ID_ERC165);
    }
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping (bytes32 => uint) _indexes;
    }
    
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }
    
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint toDeleteIndex = valueIndex - 1;
            uint lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }
    
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }
    
    function _length(Set storage set) private view returns (uint) {
        return set._values.length;
    }
    
    function _at(Set storage set, uint index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }
    
    struct AddressSet {
        Set _inner;
    }
    
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint(uint160(value))));
    }
    
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint(uint160(value))));
    }
    
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint(uint160(value))));
    }
    
    function length(AddressSet storage set) internal view returns (uint) {
        return _length(set._inner);
    }
    
    function at(AddressSet storage set, uint index) internal view returns (address) {
        return address(uint160(uint(_at(set._inner, index))));
    }
    
    struct UintSet {
        Set _inner;
    }
    
    function add(UintSet storage set, uint value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }
    
    function remove(UintSet storage set, uint value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }
    
    function contains(UintSet storage set, uint value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }
    
    function length(UintSet storage set) internal view returns (uint) {
        return _length(set._inner);
    }
    
    function at(UintSet storage set, uint index) internal view returns (uint) {
        return uint(_at(set._inner, index));
    }
}

library EnumerableMap {
    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        MapEntry[] _entries;
        mapping (bytes32 => uint) _indexes;
    }
    
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }
    
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint toDeleteIndex = keyIndex - 1;
            uint lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }
    
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }
    
    function _length(Map storage map) private view returns (uint) {
        return map._entries.length;
    }
    
    function _at(Map storage map, uint index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }
    
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        return _get(map, key, "EnumerableMap: nonexistent key");
    }
    
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }
    
    struct UintToAddressMap {
        Map _inner;
    }
    
    function set(UintToAddressMap storage map, uint key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint(uint160(value))));
    }
    
    function remove(UintToAddressMap storage map, uint key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }
    
    function contains(UintToAddressMap storage map, uint key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }
    
    function length(UintToAddressMap storage map) internal view returns (uint) {
        return _length(map._inner);
    }
    
    function at(UintToAddressMap storage map, uint index) internal view returns (uint, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint(key), address(uint160(uint(value))));
    }
    
    function get(UintToAddressMap storage map, uint key) internal view returns (address) {
        return address(uint160(uint(_get(map._inner, bytes32(key)))));
    }
    
    function get(UintToAddressMap storage map, uint key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint(_get(map._inner, bytes32(key), errorMessage))));
    }
}

contract ERC721 is ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint;
    
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    mapping (address => EnumerableSet.UintSet) private _holderTokens;
    EnumerableMap.UintToAddressMap private _tokenOwners;
    mapping (uint => address) private _tokenApprovals;
    mapping (address => mapping (address => bool)) private _operatorApprovals;
    string private _name;
    string private _symbol;
    mapping (uint => string) private _tokenURIs;
    string private _baseURI;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
    
    constructor (string memory __name, string memory __symbol) {
        _name = __name;
        _symbol = __symbol;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }
    
    function balanceOf(address owner) public view override returns (uint) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _holderTokens[owner].length();
    }
    
    function ownerOf(uint tokenId) public view override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }
    
    function name() public view override returns (string memory) {
        return _name;
    }
    
    function symbol() public view override returns (string memory) {
        return _symbol;
    }
    
    function tokenURI(uint tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        // If there is no base URI, return the token URI.
        if (bytes(_baseURI).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(_baseURI, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }
    
    function baseURI() public view returns (string memory) {
        return _baseURI;
    }
    
    function tokenOfOwnerByIndex(address owner, uint index) public view override returns (uint) {
        return _holderTokens[owner].at(index);
    }
    
    function totalSupply() public view override returns (uint) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }
    
    function tokenByIndex(uint index) public view override returns (uint) {
        (uint tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }
    
    function approve(address to, uint tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }
    
    function getApproved(uint tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }
    
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    
    function transferFrom(address from, address to, uint tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }
    
    function safeTransferFrom(address from, address to, uint tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }
    
    function safeTransferFrom(address from, address to, uint tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }
    
    function _safeTransfer(address from, address to, uint tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    
    function _exists(uint tokenId) internal view returns (bool) {
        return _tokenOwners.contains(tokenId);
    }
    
    function _isApprovedOrOwner(address spender, uint tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }
    
    function _safeMint(address to, uint tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }
    
    function _safeMint(address to, uint tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    
    function _mint(address to, uint tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }
    
    function _burn(uint tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }
    
    function _transfer(address from, address to, uint tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }
    
    function _setTokenURI(uint tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
    
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }
    
    function _checkOnERC721Received(address from, address to, uint tokenId, bytes memory _data)
        private returns (bool)
    {
        (bool success, bytes memory returndata) = to.call{value:0}(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            msg.sender,
            from,
            tokenId,
            _data
        ));
        require(success, "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    function _approve(address to, uint tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }
    
    function _beforeTokenTransfer(address from, address to, uint tokenId) internal virtual {}
}

interface erc20 {
    function transfer(address recipient, uint amount) external returns (bool);
    function balanceOf(address) external view returns (uint);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}

interface v3oracle {
    function assetToAsset(address from, uint amount, address to, uint twap_duration) external view returns (uint);
}

contract OptionsLM is ERC721 {
    address immutable public reward;
    address immutable public stake;
    address immutable public buyWith;
    address immutable public treasury;
    
    v3oracle constant oracle = v3oracle(0x0F1f5A87f99f0918e6C81F16E59F3518698221Ff);
    
    uint constant DURATION = 7 days;
    uint constant PRECISION = 10 ** 18;
    uint constant TWAP_PERIOD = 3600;
    uint constant OPTION_EXPIRY = 30 days;
    
    uint rewardRate;
    uint periodFinish;
    uint lastUpdateTime;
    uint rewardPerTokenStored;
    
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    
    struct option {
        uint amount;
        uint strike;
        uint expiry;
        bool exercised; 
    }
    
    option[] public options;
    uint public nextIndex;
    
    uint _totalSupply;
    mapping(address => uint) public _balanceOf;
    
    event Deposit(address indexed from, uint amount);
    event Withdraw(address indexed to, uint amount);
    event Created(address indexed owner, uint amount, uint strike, uint expiry, uint id);
    event Redeem(address indexed from, address indexed owner, uint amount, uint strike, uint id);
    
    constructor(
        address _reward, 
        address _stake, 
        address _buyWith, 
        address _treasury,
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        reward = _reward;
        stake = _stake;
        buyWith = _buyWith;
        treasury = _treasury;
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function rewardPerToken() public view returns (uint) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored + ((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * PRECISION / _totalSupply);
    }

    function earned(address account) public view returns (uint) {
        return (_balanceOf[account] * (rewardPerToken() - userRewardPerTokenPaid[account]) / PRECISION) + rewards[account];
    }

    function getRewardForDuration() external view returns (uint) {
        return rewardRate * DURATION;
    }

    function deposit(address recipient) external {
        _deposit(erc20(stake).balanceOf(msg.sender), recipient);
    }

    function deposit() external {
        _deposit(erc20(stake).balanceOf(msg.sender), msg.sender);
    }

    function deposit(uint amount) external {
        _deposit(amount, msg.sender);
    }

    function deposit(uint amount, address recipient) external {
        _deposit(amount, recipient);
    }

    function _deposit(uint amount, address to) internal update(msg.sender) {
        _totalSupply += amount;
        _balanceOf[to] += amount;
        _safeTransferFrom(stake, msg.sender, address(this), amount);
        emit Deposit(msg.sender, amount);
    }

    function withdraw() external {
        _withdraw(_balanceOf[msg.sender], msg.sender);
    }

    function withdraw(address recipient) external {
        _withdraw(_balanceOf[msg.sender], recipient);
    }

    function withdraw(uint amount, address recipient) external {
        _withdraw(amount, recipient);
    }

    function withdraw(uint amount) external {
        _withdraw(amount, msg.sender);
    }
    
    function _withdraw(uint amount, address to) internal update(msg.sender) {
        _totalSupply -= amount;
        _balanceOf[msg.sender] -= amount;
        _safeTransfer(stake, to, amount);
        emit Withdraw(msg.sender, amount);
    }
    
    function _claim(uint amount) internal returns (uint) {
        uint _strike = oracle.assetToAsset(reward, amount, buyWith, 3600);
        uint _expiry = block.timestamp + OPTION_EXPIRY;
        options.push(option(amount, _strike, _expiry, false));
        _safeMint(msg.sender, nextIndex);
        emit Created(msg.sender, amount, _strike, _expiry, nextIndex);
        return nextIndex++;
    }
    
    function redeem(uint id) external {
        require(_isApprovedOrOwner(msg.sender, id));
        option storage _opt = options[id];
        require(_opt.expiry >= block.timestamp && !_opt.exercised);
        _safeTransferFrom(buyWith, msg.sender, treasury, _opt.strike);
        _safeTransfer(reward, msg.sender, _opt.amount);
        _opt.exercised = true;
        options[id] = _opt;
        emit Redeem(msg.sender, msg.sender, _opt.amount, _opt.strike, id);
    }

    function getReward() public update(msg.sender) returns (uint id) {
        uint _reward = rewards[msg.sender];
        if (_reward > 0) {
            rewards[msg.sender] = 0;
            id = _claim(_reward);
        }
    }

    function exit() external {
        _withdraw(_balanceOf[msg.sender], msg.sender);
        getReward();
    }
    
    function notify(uint amount) external update(address(0)) {
        _safeTransferFrom(reward, msg.sender, address(this), amount);
        if (block.timestamp >= periodFinish) {
            rewardRate = amount / DURATION;
        } else {
            uint _remaining = periodFinish - block.timestamp;
            uint _leftover = _remaining * rewardRate;
            rewardRate = (amount + _leftover) / DURATION;
        }
        
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + DURATION;
    }

    modifier update(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }
    
    function _safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
    
    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}