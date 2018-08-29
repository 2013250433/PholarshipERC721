pragma solidity ^0.4.18;

interface ERC721 {
    
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) 
    /// is reset to none.
    event Transfer(address indexed _from, address indexed _to,
    uint256 _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved,
    uint256 _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, 
    bool _approved);
    
    
    //change public to external due to interface
    
    function balanceOf(address _owner) external view returns (uint256 _balance);
    function ownerOf(uint256 _tokenId) external view returns (address _owner);
    function approve(address _to, uint256 _tokenId) external;
    function getApproved(uint256 _tokenId)
    external view returns (address _operator);

    function setApprovalForAll(address _operator, bool _approved) external;
    function isApprovedForAll(address _owner, address _operator)
    external view returns (bool);

    function transferFrom(address _from, address _to, uint256 _tokenId) 
    external;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId)
    external;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes _data
    )
    public;
}

/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface ERC165 {

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceId The interface identifier, as specified in ERC-165
   * @dev Interface identification is specified in ERC-165. This function
   * uses less than 30,000 gas.
   */
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

/**
 * from 721 tutorial
 */


contract CheckERC165 is ERC165 {
    mapping (bytes4 => bool) internal supportedInterfaces;

    constructor() public {
        supportedInterfaces[this.supportsInterface.selector] = true; 
        // ===0x01ffc9a7
    }
    
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool){
        return supportedInterfaces[interfaceID];
    }
}

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface ERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(address _operator, address _from, 
    uint256 _tokenId, bytes _data) external returns(bytes4);
}

/// @author Hojin Hwang <zxoihojin@gmail.com> (https://github.com/2013250433)
//  Of course except the basic ERC721 part... 
contract Polarship721 is ERC721, CheckERC165{
    using SafeMath for uint256;
    
    /** using internal visibility rather than private 
     * in order that Metadata & ENumerable 
     * can have access to them
     **/
     
    address internal creator;
    uint256 internal maxId;
    mapping(address => uint256) internal balances;
    mapping(uint256 => address) internal owners;
    mapping(uint256 => address) internal allowance;
    mapping(address => mapping(address => bool)) internal authorised;
    //mapping(uint256 => bool) internal burned;
    
    
    uint256 internal oneEther;
    address internal donatee;
    uint256 internal incentive;
    uint256 internal lockedBalance;
    // if public, no need for getters
    
    constructor(address _donatee, uint256 _incentive) CheckERC165() public payable {
        /* if donor(donator) sends more ether than the donatee 'needs',
           it goes to incentive which is proceeded at front-end
           msg.value(payable) - 'needs' = _incentive
        */ 
        require(_incentive>=0);
        
        creator = msg.sender;
        balances[msg.sender] = 1; //initalSupply->1
        maxId = 1; //initialSupply->1
        
        //chang unit wei to ether
        oneEther = 1 ether;
        incentive = _incentive.mul(oneEther);
        
        donatee = _donatee;
        //send actual donation fee
        donatee.transfer((msg.value).sub(incentive)); 
        
        lockedBalance = incentive;
        address(this).transfer(incentive);
        
        
        //erc165 check
        supportedInterfaces[
            this.balanceOf.selector ^ 
            this.ownerOf.selector ^
            bytes4(keccak256("safeTransferFrom(address,address,uint256"))^
            bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes"))^
            this.transferFrom.selector ^
            this.approve.selector ^
            this.setApprovalForAll.selector ^
            this.getApproved.selector ^
            this.isApprovedForAll.selector
        ] = true;
        // ===0x80ac58cd 
    }
    
    function getDonatee() external view returns(address){
        return donatee;
    }
    
    function getLockedBalance() external view returns(uint256){
        return lockedBalance;
    }
    
    // owner's reward and retreive functions
    function rewardIncentive() external returns(string) {
        address owner = ownerOf(1);
        require(owner == msg.sender);
        
        if(lockedBalance>0){
            donatee.transfer(lockedBalance);
            lockedBalance=0;
            return "incentive rewarded";
        }
        else{
            return "no incentive left";
        }
    }
    
    function withdrawIncentive() external returns(string) {
        address owner = ownerOf(1);
        require(owner == msg.sender);
        
        if(lockedBalance>0){
            owner.transfer(lockedBalance); //instead of owners(1)
            lockedBalance=0;
            return "incentive retrieved";
        }
        else{
            return "no incentive left";
        }
    }
    
    function isValidToken(uint256 _tokenId) internal view returns(bool){
        return _tokenId != 0 && _tokenId <= maxId; 
        // && !burned[_tokenId] 
        // if burning is implemented
    }
    
    function balanceOf(address _owner) external view returns(uint256){
        return balances[_owner];
    }
    
    function ownerOf(uint256 _tokenId) public view returns(address){
        require(isValidToken(_tokenId));
        if(owners[_tokenId] !=0x0){
            return owners[_tokenId];
        } else {
            return creator;
        }
    }
    
    function isApprovedForAll(address _owner, address _operator) external view
    returns (bool){
        return authorised[_owner][_operator];
    }
    
    function setApprovalForAll(address _operator, bool _approved) external {
        emit ApprovalForAll(msg.sender,_operator,_approved);
        authorised[msg.sender][_operator] = _approved;
    }
    
    function getApproved(uint256 _tokenId) external view returns (address){
        require(isValidToken(_tokenId));
        return allowance[_tokenId];
    }
    
    function approve(address _approved, uint256 _tokenId)  external{
        address owner = ownerOf(_tokenId);
        require( owner == msg.sender    //Require Sender Owns Token
            || authorised[owner][msg.sender]    //  save gas then isApproved4R
        );
        emit Approval(owner, _approved, _tokenId);
        allowance[_tokenId] = _approved;
    }
    
     /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        //Check Transferable
        //There is a token validity check in ownerOf
        address owner = ownerOf(_tokenId);

        require ( owner == msg.sender             //Require sender owns token
            //Doing the two below manually instead of referring to the external methods saves gas
            || allowance[_tokenId] == msg.sender      //or is approved for this token
            || authorised[owner][msg.sender]          //or is approved for all
        );
        require(owner == _from);
        require(_to != 0x0);
        //require(isValidToken(_tokenId)); <-- done by ownerOf

        emit Transfer(_from, _to, _tokenId);

        owners[_tokenId] = _to;
        balances[_from]--;
        balances[_to]++;
        //Reset approved if there is one
        if(allowance[_tokenId] != 0x0){
            delete allowance[_tokenId];
        }
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) public {
        transferFrom(_from, _to, _tokenId);

        //Get size of "_to" address, if 0 it's a wallet
        uint32 size;
        assembly {
            size := extcodesize(_to)
        }
        if(size > 0){
            ERC721TokenReceiver receiver = ERC721TokenReceiver(_to);
            require(receiver.onERC721Received(msg.sender,_from,_tokenId,data) == bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")));
        }

    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to ""
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
        safeTransferFrom(_from,_to,_tokenId,"");
    }

}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, 
    // but the benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}
