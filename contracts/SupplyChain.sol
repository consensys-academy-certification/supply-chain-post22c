// Implement the smart contract SupplyChain following the provided instructions.
// Look at the tests in SupplyChain.test.js and run 'truffle test' to be sure that your contract is working properly.
// Only this file (SupplyChain.sol) should be modified, otherwise your assignment submission may be disqualified.

pragma solidity ^0.5.0;

contract SupplyChain {

  address payable owner  = msg.sender; //owner address
  uint myfee = 1 finney; //fee

  // Create a variable named 'itemIdCount' to store the number of items and also be used as reference for the next itemId.
  uint itemIdCount;

  // Create an enumerated type variable named 'State' to list the possible states of an item (in this order): 'ForSale', 'Sold', 'Shipped' and 'Received'.
  enum State {
    ForSale,
    Sold,
    Shipped,
    Received
  }

  // Create a struct named 'Item' containing the following members (in this order): 'name', 'price', 'state', 'seller' and 'buyer'.
  struct Item {
    string name;
    uint price;
    State state;
    address payable seller;
    address payable buyer;
  }

  // Create a variable named 'items' to map itemIds to Items.
  mapping(uint => Item) items;

  // Create an event to log all state changes for each item.
  event StateChangeLog (
    uint indexed itemid,
    string name,
    uint price,
    State state,
    address payable seller,
    address payable buyer
  );

  // Create a modifier named 'onlyOwner' where only the contract owner can proceed with the execution.
  modifier onlyOwner() {
    require(owner == msg.sender);
    _;
  }

  // Create a modifier named 'checkState' where the execution can only proceed if the respective Item of a given itemId is in a specific state.
  modifier checkState(uint _itemId, State _state) {
    require(items[_itemId].state == _state);
    _;
  }

  // Create a modifier named 'checkCaller' where only the buyer or the seller (depends on the function) of an Item can proceed with the execution.
  modifier checkCaller(uint _itemId, State _state) {
    require((items[_itemId].seller == msg.sender && _state == State.Sold) || (items[_itemId].buyer == msg.sender && _state == State.Shipped));
    _;
  }

  // Create a modifier named 'checkValue' where the execution can only proceed if the caller sent enough Ether to pay for a specific Item or fee.
  modifier checkValue(uint _itemId) {
    require(items[_itemId].price <= msg.value || myfee <= msg.value);
    _;
  }

  // Create a function named 'addItem' that allows anyone to add a new Item by paying a fee of 1 finney. Any overpayment amount should be returned to the caller. All struct members should be mandatory except the buyer.
  function addItem(string calldata _name, uint _price) checkValue(0) external payable {
    Item memory additem;
    additem.name = _name;
    additem.price = _price;
    additem.seller = msg.sender;
    additem.buyer = address(0);
    additem.state = State.ForSale;

    items[itemIdCount] = additem;
    itemIdCount++;
    msg.sender.transfer(msg.value - myfee); //return overpayment

    emit StateChangeLog(itemIdCount-1, additem.name, additem.price, additem.state, additem.seller, additem.buyer);
  }

  // Create a function named 'buyItem' that allows anyone to buy a specific Item by paying its price. The price amount should be transferred to the seller and any overpayment amount should be returned to the buyer.
  function buyItem(uint _itemId) checkValue(_itemId) checkState(_itemId, State.ForSale) external payable {
    items[_itemId].state = State.Sold;
    items[_itemId].buyer = msg.sender;

    uint itemprice = items[_itemId].price;
    items[_itemId].seller.transfer(itemprice);
    msg.sender.transfer(msg.value - itemprice); //return overpayment

    emit StateChangeLog(_itemId, items[_itemId].name, items[_itemId].price, items[_itemId].state, items[_itemId].seller, items[_itemId].buyer);
  }

  // Create a function named 'shipItem' that allows the seller of a specific Item to record that it has been shipped.
  function shipItem(uint _itemId) checkCaller(_itemId, State.Sold) checkState(_itemId, State.Sold) external {
    items[_itemId].state = State.Shipped;

    emit StateChangeLog(_itemId, items[_itemId].name, items[_itemId].price, items[_itemId].state, items[_itemId].seller, items[_itemId].buyer);
  }

  // Create a function named 'receiveItem' that allows the buyer of a specific Item to record that it has been received.
  function receiveItem(uint _itemId) checkCaller(_itemId, State.Shipped) checkState(_itemId, State.Shipped)  external payable {
    items[_itemId].state = State.Received;

    emit StateChangeLog(_itemId, items[_itemId].name, items[_itemId].price, items[_itemId].state, items[_itemId].seller, items[_itemId].buyer);
  }

  // Create a function named 'getItem' that allows anyone to get all the information of a specific Item in the same order of the struct Item.
  function getItem(uint _itemId) view public returns(string memory, uint, State, address payable, address payable) {
    return (items[_itemId].name, items[_itemId].price, items[_itemId].state, items[_itemId].seller, items[_itemId].buyer);
  }

  // Create a function named 'withdrawFunds' that allows the contract owner to withdraw all the available funds.
  function withdrawFunds() onlyOwner() external payable {
    owner.transfer(address(this).balance);
  }
}
