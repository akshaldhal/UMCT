// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract UMCT is ReentrancyGuard{
    /**
 * @title UMCT
 */
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;
    string[] private MarketPlaceTokens;

//add option to alter item properties
//fix the approval thing to enable nft resales
//add function to check wallet network
//"Unified Marketplace Contract Token", "UMCT"
//add emit thing wherever needed
//total items sold by person
//total items sold by network
//setup moralis for user data management
//add feature for liking an nft (if possible)
//nft metadata to blockchain thing
//add features to support multiple marketplaces
//add option for tags on nft collections and feature to search by tags
//function to return nfts of whose a person is the original owner
//fix the absence of erc721
//if not universally managed, the nft should not be visible outside the network
//add transfer token to another person function

//add receive and transfer token to erc721 option

///////////////////CREATE ADMIN APP///////////////////




    address payable owner;
    uint256 private contractComission = 2;
    bool private nonRestrictedMarkets = true;
    address private networkAdd = 0x2E6102cA1e020bfD044A3CB54540F84Dcb4eAF02;
    
    
    function setNonRestrictedMarkets(bool val) public {
        require(msg.sender == networkAdd, "Only networkAdd can run this function");
        nonRestrictedMarkets = val;
    }

    function getNonRestrictedMarkets() public view returns (bool) {
        return nonRestrictedMarkets;
    }

    function setNetworkAdd(address payable add) public {
        require(msg.sender == networkAdd, "Only networkAdd can run this function");
        networkAdd = add;
    }

    function getNetworkAdd() public view returns (address) {
        return networkAdd;
    }

    function getContractComission() public view returns (uint256) {
            return contractComission;
    }

    function setContractComission(uint256 _contractComission) public {
        require(msg.sender == networkAdd, "Only networkAdd can run this function");
        require(_contractComission <= 10, "Invalid comission value");
        contractComission = _contractComission;
    }
/////////////////////////////////////////////////////////////////////////////
    function getTokenOriginalOwnerComission(uint itemId) public view returns (uint256) {
        return idToMarketItem[itemId].original_owner_comission;
    }

    function setTokenOriginalOwnerComission(uint itemId, uint256 _original_owner_comission) public {
        require(msg.sender == idToMarketItem[itemId].original_owner, "Only owner can run this function");
        require(_original_owner_comission <= 10, "Invalid comission value");
        idToMarketItem[itemId].original_owner_comission = _original_owner_comission;
    }
/////////////////////////////////////////////////////////////////////////////


    constructor(){
        owner = payable(msg.sender);
    }
    struct MarketItem {
        uint256 tokenId;
        address payable owner;
        uint256 price;
        bool sold;
        address payable original_owner;
        uint256 original_owner_comission;
        }
    mapping(uint256 => MarketItem) private idToMarketItem;

    event MarketItemCreated (
        uint256 indexed tokenId,
        address owner,
        uint price,
        bool sold,
        address original_owner,
        uint256 original_owner_comission
    );

    struct MarketPlaceProperties {
        string TokenSymbol;
        string TokenName;
        uint256 MarketComission;
        address payable MarketOwner;
        address[] ApprovedManagers;
        bool universally_manageable;
    }
    mapping(string => MarketPlaceProperties) private marketTokenNameToMarketPlaceProperties;

    event MarketPlacePropertiesEdited (
        string indexed TokenSymbol,
        string TokenName,
        uint256 MarketComission,
        address payable MarketOwner,
        address[] ApprovedManagers,
        bool universally_manageable
    );
    //////function burn(uint256 tokenID) public {
        //////require(msg.sender == idToMarketItem[tokenID].owner, "you are not the owner");
        //////_burn(tokenID);
        //Delete market entry of the item too IMPORTANT
    //////}


    function ExistsInList(string memory str, string[] memory list) public pure returns (bool){
        for (uint i = 0; i < list.length; i++) {
            if (keccak256(abi.encodePacked((str))) == keccak256(abi.encodePacked((list[i])))){
                return true;
            }
        }
        return false;
    }

    function ExistsInListAdd(address str, address[] memory list) public pure returns (bool){
        for (uint i = 0; i < list.length; i++) {
            if (str == list[i]){
                return true;
            }
        }
        return false;
    }

    function RemoveFromListAdd(address[] memory list, address str) public pure returns (address[] memory){
        for (uint i = 0; i < list.length; i++) {
            if (str == list[i]){
                delete list[i];
            }
        }
        return list;
    }

    function isValidTokenSymbol(string memory str) public pure returns (bool){
        bytes memory b = bytes(str);
        if(b.length > 6) return false;
        for(uint i = 0; i < b.length; i++) {
            bytes1 char = b[i];
            if(!(char >= 0x41 && char <= 0x5A)){
                return false;
            }
        }
        return true;
    }


    function createMarketPlace(string memory _TokenSymbol, string memory _TokenName, address _owner, uint256 _MarketComission, bool _universally_manageable) public payable nonReentrant{
        require(nonRestrictedMarkets || msg.sender == networkAdd, "Permission to create market denied");
        require(isValidTokenSymbol(_TokenSymbol), "Token symbol can only comprise of A-Z capital alhabets without spaces with total length less than 6");
        require(!(ExistsInList(_TokenSymbol, MarketPlaceTokens)), "Token already exists");
        MarketPlaceTokens.push(_TokenSymbol);
        MarketPlaceProperties memory mpp;
        marketTokenNameToMarketPlaceProperties[_TokenSymbol] = mpp;
        marketTokenNameToMarketPlaceProperties[_TokenSymbol].TokenSymbol = _TokenSymbol;
        marketTokenNameToMarketPlaceProperties[_TokenSymbol].TokenName = _TokenName;
        marketTokenNameToMarketPlaceProperties[_TokenSymbol].MarketComission = _MarketComission;
        marketTokenNameToMarketPlaceProperties[_TokenSymbol].MarketOwner = payable(_owner);
        marketTokenNameToMarketPlaceProperties[_TokenSymbol].ApprovedManagers.push(payable(_owner));
        marketTokenNameToMarketPlaceProperties[_TokenSymbol].universally_manageable = _universally_manageable;
    }

    function addManagers(string memory _TokenSymbol, address payable toAdd) public payable nonReentrant{
        require(ExistsInList(_TokenSymbol, MarketPlaceTokens), "Marketplace does not exist, create one first");
        require(payable(msg.sender) == marketTokenNameToMarketPlaceProperties[_TokenSymbol].MarketOwner, "You're not authorized");
        marketTokenNameToMarketPlaceProperties[_TokenSymbol].ApprovedManagers.push(payable(toAdd));
    }

    function removeManagers(string memory _TokenSymbol, address payable toRemove) public payable nonReentrant{
        require(ExistsInList(_TokenSymbol, MarketPlaceTokens), "Marketplace does not exist, create one first");
        require(payable(msg.sender) == marketTokenNameToMarketPlaceProperties[_TokenSymbol].MarketOwner, "You're not authorized");
        marketTokenNameToMarketPlaceProperties[_TokenSymbol].ApprovedManagers = RemoveFromListAdd(marketTokenNameToMarketPlaceProperties[_TokenSymbol].ApprovedManagers, toRemove);
    }

    function getManagers(string memory _TokenSymbol) public view returns(address[] memory){
        require(ExistsInList(_TokenSymbol, MarketPlaceTokens), "Marketplace does not exist, create one first");
        return marketTokenNameToMarketPlaceProperties[_TokenSymbol].ApprovedManagers;
    }

    function setMarketOwner(string memory _TokenSymbol, address payable newOwner) public payable nonReentrant{
        require(ExistsInList(_TokenSymbol, MarketPlaceTokens), "Marketplace does not exist, create one first");
        require(payable(msg.sender) == marketTokenNameToMarketPlaceProperties[_TokenSymbol].MarketOwner, "You're not authorized");
        marketTokenNameToMarketPlaceProperties[_TokenSymbol].MarketOwner = payable(newOwner);
    }

    function getMarketOwner(string memory _TokenSymbol) public view returns(address){
        require(ExistsInList(_TokenSymbol, MarketPlaceTokens), "Marketplace does not exist, create one first");
        return marketTokenNameToMarketPlaceProperties[_TokenSymbol].MarketOwner;
    }

    function setMarketComission(string memory _TokenSymbol, uint256 _comission) public payable nonReentrant{
        require(ExistsInList(_TokenSymbol, MarketPlaceTokens), "Marketplace does not exist, create one first");
        require(payable(msg.sender) == marketTokenNameToMarketPlaceProperties[_TokenSymbol].MarketOwner, "You're not authorized");
        marketTokenNameToMarketPlaceProperties[_TokenSymbol].MarketComission = _comission;
    }

    function getMarketComission(string memory _TokenSymbol) public view returns(uint256){
        require(ExistsInList(_TokenSymbol, MarketPlaceTokens), "Marketplace does not exist, create one first");
        return marketTokenNameToMarketPlaceProperties[_TokenSymbol].MarketComission;
    }
//function to get other market info

    function createToken(//string memory _tokenURI,
    uint256 price, uint256 _original_owner_comission) public payable nonReentrant {
        require(price > 0 ether, "Sellign price must be greater than 0 eth");
        require(_original_owner_comission <= 10, "Invalid comission value");
        _itemIds.increment();
        uint256 newItemId = _itemIds.current();
        idToMarketItem[newItemId] =  MarketItem(
            newItemId,
            payable(msg.sender),
            (price),
            false,
            payable(msg.sender),
            _original_owner_comission);

            emit MarketItemCreated(
                newItemId,
                msg.sender,
                (price),
                false,
                msg.sender,
                _original_owner_comission);
    }


    function createMarketSale(
    uint256 itemId
    ) public payable nonReentrant {
        uint price = idToMarketItem[itemId].price;
        uint _original_owner_comission_ = idToMarketItem[itemId].original_owner_comission;
        address payable original_owner = idToMarketItem[itemId].original_owner;
        require(idToMarketItem[itemId].sold == false, "Item not for sale");
        require(msg.value >= price, "Submit equal to or greater than asking price in order to complete the purchase");
        uint256 tmp = msg.value;
        uint256 price_percent = msg.value/100;
        uint256 contract_comission = price_percent*contractComission;
        uint256 _original_owner_comission = price_percent*_original_owner_comission_;
        tmp = tmp - contract_comission;
        tmp = tmp - _original_owner_comission;
        idToMarketItem[itemId].owner.transfer(tmp);
        //should work now; untested block
        //////transferFrom(current_owner, msg.sender, itemId);
        //untested block
        idToMarketItem[itemId].owner = payable(msg.sender);
        idToMarketItem[itemId].sold = true;
        _itemsSold.increment();
        payable(networkAdd).transfer(contract_comission);
        payable(original_owner).transfer(_original_owner_comission);
  }

  /* Returns all unsold market items */
  function fetchMarketItems() public view returns (MarketItem[] memory) {
    uint itemCount = _itemIds.current();
    uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
    uint currentIndex = 0;

    MarketItem[] memory items = new MarketItem[](unsoldItemCount);
    for (uint i = 0; i < itemCount; i++) {
      if (idToMarketItem[i + 1].sold == false) {
        uint currentId = i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }

  /* Returns only items that a user has purchased */
  function fetchMyNFTs() public view returns (MarketItem[] memory) {
    uint totalItemCount = _itemIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;

    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].owner == msg.sender) {
        itemCount += 1;
      }
    }

    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].owner == msg.sender) {
        uint currentId = i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }

  /* Returns only items a user has created */
  function fetchItemsCreated() public view returns (MarketItem[] memory) {
    uint totalItemCount = _itemIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;

    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].owner == msg.sender) {
        itemCount += 1;
      }
    }

    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].owner == msg.sender) {
        uint currentId = i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }
}