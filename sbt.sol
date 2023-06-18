// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = address(msg.sender);
        emit OwnershipTransferred(address(0), address(msg.sender));
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == address(msg.sender), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "Not minted");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "Not minted");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

/// @title ERC721 Soulbound Token
/// @author 0xArbiter
/// @author Andreas Bigger <https://github.com/abigger87>
/// @dev ERC721 Token that can be burned and minted but not transferred.
abstract contract Soulbound is ERC721 {

    // Custom SBT error for if users try to transfer
    error TokenIsSoulbound();

    /// @dev Put your NFT's name and symbol here
    constructor(string memory name, string memory symbol) ERC721(name, symbol){}

    /// @notice Prevent Non-soulbound transfers
    function onlySoulbound(address from, address to) internal pure {
        // Revert if transfers are not from the 0 address and not to the 0 address
        if (from != address(0) && to != address(0)) {
            revert TokenIsSoulbound();
        }
    }

    /// @notice Override token transfers to prevent sending tokens
    function transferFrom(address from, address to, uint256 id) public override {
        onlySoulbound(from, to);
        super.transferFrom(from, to, id);
    }
}

pragma solidity ^0.8.0;

contract SignatureVerification {
    function verifySignature(
        bytes32 message,
        bytes memory signature,
        address signer
    ) public pure returns (bool) {
        bytes32 hash = getMessageHash(message);
        address recoveredSigner = recoverSigner(hash, signature);
        
        return recoveredSigner == signer;
    }

    function getMessageHash(bytes32 message) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message));
    }

    function recoverSigner(bytes32 hash, bytes memory signature) internal pure returns (address) {
        require(signature.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        return ecrecover(hash, v, r, s);
    }
}

contract SBT is Soulbound, Ownable {

    string private _baseURI;
    uint256 private _totalSupply;

    struct Skill {
        string skillName;
    }

    Skill[] private _skills;
    mapping(uint256 => mapping(uint256 => uint256)) _skillValues;

    constructor(string memory _newBaseURI) Soulbound("Sai SBT", "SAISBT")
    {
        _baseURI = _newBaseURI;
        _mint(address(msg.sender), 0);
        _totalSupply = _totalSupply + 1;
    }

    function mint(address _to, uint256[] memory skills, uint256[] memory skillValues, uint8 _v, bytes32 _r, bytes32 _s) external
    {
        require(balanceOf(_to) == 0, "Already exists");
        require(skills.length == skillValues.length, "Invalid input skill");
        bytes32 message = keccak256(abi.encodePacked(_to, skills, skillValues));
        require(verify(getMessageHash(message), _v, _r, _s, owner()), "Invalid signature");

        // mint
        _mint(_to, _totalSupply);

        // edit skill value
        for(uint256 i = 0; i < skills.length; i ++) {
            _skillValues[_totalSupply][skills[i]] = skillValues[i];   
        }

        _totalSupply = _totalSupply + 1;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory)
    {
        return string(abi.encodePacked(_baseURI, toString(_tokenId)));
    }

    function toString(uint256 _value) internal pure returns (string memory)
    {
        if (_value == 0) {
            return "0";
        }
        uint256 temp = _value;
        uint256 digits;
        while (temp != 0) {
            unchecked {
                digits++;
                temp /= 10;
            }
        }
        bytes memory buffer = new bytes(digits);
        while (_value != 0) {
            unchecked {
                digits -= 1;
                buffer[digits] = bytes1(uint8(48 + uint256(_value % 10)));
                _value /= 10;
            }
        }
        return string(buffer);
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner
    {
        _baseURI = _newBaseURI;
    }

    function totalSupply() public view returns (uint256)
    {
        return _totalSupply;
    }
    
    function addSkill(string memory _skillName) external onlyOwner
    {
        _skills.push(Skill({skillName: _skillName}));
    }
    function addSkills(string[] memory _skillNames) external onlyOwner
    {
        for(uint256 i = 0; i < _skillNames.length; i ++) {
            _skills.push(Skill({skillName: _skillNames[i]})); 
        }
    }
    function editSkill(uint256 _skillId, string memory _skillName) external onlyOwner
    {
        _skills[_skillId].skillName = _skillName;
    }

    function skill(uint256 _skillId) external view returns (Skill memory)
    {
        return _skills[_skillId];
    }
    function skillLength() external view returns (uint256)
    {
        return _skills.length;
    }

    function editSkillValue(uint256 _sbtId, uint256 _skillId, uint256 _value) external onlyOwner
    {
        require(ownerOf(_sbtId) != address(0), "Not minted");
        _skillValues[_sbtId][_skillId] = _value;   
    }

    function skillValue(uint256 _sbtId, uint256 _skillId) external view returns (uint256)
    {
        return _skillValues[_sbtId][_skillId];
    }

    function getMessageHash(bytes32 message) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message));
    }

    function verify(bytes32 messageHash, uint8 v, bytes32 r, bytes32 s, address signer) pure public returns(bool) {
        return ecrecover(messageHash, v, r, s) == signer;
    }

}

