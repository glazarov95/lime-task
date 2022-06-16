// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

contract Ownable {
    address public owner;
    
    modifier onlyOwner() {
        require(owner == msg.sender, "Not invoked by the owner!");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
}

contract StoreBase is Ownable{
    struct BuyersInfo{
        address clientAddr;
        uint boughtBlockNumber;
    }

    struct Product{
        uint id;
        string name;
        uint quantity;
    }

    uint refundPolicyNumber = 100;

    Product[] products;
    
    mapping(string => Product)  productNameMap;
    mapping(uint => BuyersInfo[]) buyers;

    event ProductAdded(uint id,string name,uint quantity);
    event ProductUpdated(uint id, string name, uint quantity);
    event ProductBought(uint id,address buyer);
    event ProductRefund(uint id);

    function internalAddProduct(string memory name, uint quantity) internal {
        uint id = products.length;
        Product memory newProduct =  Product({
            id : id,
            name : name,
            quantity:quantity
        });
        products.push(newProduct);
        productNameMap[name] = newProduct;
    }

    function internalUpdateProduct(uint id,uint quantity) internal {
        products[id].quantity = quantity;
    }

    function internalCheckBuyers(BuyersInfo[] memory clients,address client) internal pure returns(bool) {
        uint selectedProductBuyersLength = clients.length;
        if(selectedProductBuyersLength > 0){
            for(uint i= 0; i<selectedProductBuyersLength; i++){
                if(client == clients[i].clientAddr){
                    return true;
                }
            }
        }
        return false;
    }

    function internalAddBuyer(uint id, address client) internal{
        BuyersInfo[] storage selectedProductBuyers = buyers[id];
        uint blockNumber = block.number;
        selectedProductBuyers.push(BuyersInfo(client,blockNumber));
    }

    function refundEligable(uint boughtBlockNumber) internal view returns(bool){
        if(boughtBlockNumber + refundPolicyNumber > block.number){
            return true;
        }
        return false;
    }

    function internalRefund(uint id,address client) internal{
        BuyersInfo[] storage selectedProductBuyers = buyers[id];
        uint selectedProductBuyersLength = selectedProductBuyers.length;
        bool clientFound = false;
        for(uint i= 0; i<selectedProductBuyersLength;i++){
            if(client == selectedProductBuyers[i].clientAddr){
                clientFound = true;
                bool eligble = refundEligable(selectedProductBuyers[i].boughtBlockNumber);
                require(eligble,"Sorry, your request for refund has been denied.");
                BuyersInfo memory buyer = selectedProductBuyers[i];
                selectedProductBuyers[i] = selectedProductBuyers[selectedProductBuyersLength-1];
                selectedProductBuyers[selectedProductBuyersLength-1] = buyer;
                selectedProductBuyers.pop();
                break;
            }
        }
        require(clientFound,"You've already returned your product or didn't even bought it.");
    }
}   

contract Store is StoreBase{
    function addProduct(string memory name, uint quantity) public onlyOwner{
        bool productExist = bytes(productNameMap[name].name).length>0;

        require(bytes(name).length != 0, "You have to enter a name!");
        require(quantity > 0, "You have to enter quantity!");

        if(productExist){
            uint selectedProductId = productNameMap[name].id;
            Product storage selectedProduct = products[selectedProductId];

            internalUpdateProduct(selectedProductId,quantity);
            emit ProductUpdated(selectedProduct.id,selectedProduct.name,selectedProduct.quantity);
        }else{
            internalAddProduct(name,quantity);
            emit ProductAdded(products.length,name,quantity);
        }
    }

    function updateProductQuantity(uint id,uint quantity) public onlyOwner{
        require(id < products.length,"Product does not exist!");
        require(quantity > 0, "You have to enter quantity!");

        internalUpdateProduct(id,quantity);

        Product storage selectedProduct = products[id];
        emit ProductUpdated(selectedProduct.id,selectedProduct.name,selectedProduct.quantity);
    }

    function buyProduct(uint id) public{
        address client = msg.sender;
        Product storage selectedProduct = products[id];

        require(id < products.length,"Product does not exist!");
        require(selectedProduct.quantity > 0,"Product is out of stock!");

        BuyersInfo[] storage selectedProductBuyers = buyers[id];
        bool alreadyBoughtByClient = internalCheckBuyers(selectedProductBuyers,client);
        require(!alreadyBoughtByClient, "You cannot buy the same product more than once!");
        internalAddBuyer(id,client);
        selectedProduct.quantity--;

        emit ProductBought(selectedProduct.id,client);
    }

    function refundProduct(uint id) public{
        require(id < products.length,"Product does not exist!");
        address client = msg.sender;

        internalRefund(id,client);
        Product storage selectedProduct = products[id];
        selectedProduct.quantity++;
        emit ProductRefund(id);
    }

    function setRefundPolicyNumber(uint blockNumber)public onlyOwner{
        refundPolicyNumber = blockNumber;
    }

    function getProductByName(string memory name) public view returns(Product memory){
        require(bytes(name).length != 0, "You have to enter a name!");

        uint selectedProductId = productNameMap[name].id;
        Product storage selectedProduct = products[selectedProductId];

        bool productExist = bytes(selectedProduct.name).length>0;
        require(productExist,"This product does not exist!");

        return selectedProduct;
    }

    function getProductById(uint id) public view returns(Product memory){
        require(id < products.length,"Product does not exist!");
        Product storage selectedProduct = products[id];

        return selectedProduct;
    }

    function getProductBuyersById(uint id) public view returns(BuyersInfo[] memory){
        require(id < products.length,"Product does not exist!");
        BuyersInfo[] storage selectedProductBuyers = buyers[id];

        return selectedProductBuyers;
    }

    function getAllProducts() public view returns(Product[] memory){
        return products;
    }

    function getRefundPolicyNumber() public view returns(uint){
        return refundPolicyNumber;
    }
}
