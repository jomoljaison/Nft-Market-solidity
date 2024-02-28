// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol";
//import "node_modules/@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";
//import "node_modules/@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/utils/ERC721Holder.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/Math.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol";

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/common/ERC2981.sol";

library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

contract NFT_MARKETPLACE {
    using Counters for Counters.Counter;

    IERC20 public _token = IERC20(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
    Counters.Counter private orders;
    Counters.Counter private nftSold;
uint public Platformfee =2;
    enum NFTstatus {
        Active,
        sold,
        fixed_deleted,
        auction_deleted,
        not_Active
    }

    struct makeOffer {
        address bidder;
        uint256 amount;
        uint256 timestamp;
        IERC20 token;
    }

    struct NFTmarket {
        NFTstatus status;
        address ScAdress;
        uint256 tokenid;
        uint256 orderid;
        address seller;
        address buyer;
        uint256 duration;
        uint256 quantity;
        bool isFixedBysell;
        bool isERC721;
        uint256 endingPrice;
        address token;
        uint256 finalAmt;
    }
    struct UserFee {
        uint256[] value;
        address payable[] member;
    }

    mapping(uint256 => makeOffer[]) private BidlistArray;

    mapping(uint256 => NFTmarket[]) private NFTs;

    mapping(uint256 => UserFee[])  UserFeeList;

    mapping(address => NFTmarket[]) public  onsaleUnder_user;


    function addUser(uint256[] memory amt,address payable[] memory ads,uint256 ordrid ) public {
        UserFee memory user = UserFee({value: amt, member: ads});
        UserFeeList[ordrid].push(user);
    }

    function updateplatformfee(uint256 platformfee)public 
    {
    Platformfee=platformfee;
    }
  
    function showUSERs(uint256 ordrid)
        external
        view
        returns (UserFee[] memory)
    {
        return UserFeeList[ordrid];
    }


    
      function fixedBysell(
        address nftAddress,
        uint256 tokenId,
        uint256 orderid,
        uint256 duration,
        address token,
        uint256 qty,
        bool isERC721,uint256[] memory amt,address payable[] memory ads ,uint256 finalamt) public {
        address seller = msg.sender;
        uint256 times = duration + block.timestamp;
        require(
            ERC1155(nftAddress).balanceOf(seller, tokenId) > 0,
            "user dont have nfts"
        );

            NFTmarket memory FixedNFTmarket = NFTmarket({
            status:NFTstatus.Active,
            ScAdress: nftAddress,
            tokenid:  tokenId,
            orderid:  orderid ,
            seller:seller,
            buyer:address(0),
            duration:times,
            quantity:qty,
            isFixedBysell:true,
            isERC721:isERC721,
            endingPrice:0,
            token:token,
            finalAmt:finalamt

        });
        onsaleUnder_user[seller].push(FixedNFTmarket);

        UserFee memory user = UserFee({value: amt, member: ads});
        UserFeeList[orderid].push(user);

        NFTs[orderid].push(FixedNFTmarket);
        
        orders.increment();

    }




    function cancelFixedByOwner(uint256 orderid) external {

           require(
        NFTs[orderid][0].status == NFTstatus.Active,
        "Product is not active"
    );

        address seller =   NFTs[orderid][0].seller;
        require(msg.sender == seller, "caller must be owner");

         NFTs[orderid][0].status = NFTstatus.fixed_deleted;
        delete NFTs[orderid];
    }






    function buyNft1155(
        uint256 orderid,
        address seller,
        address buyer,
        address nftAddress,
        uint256 tokenid,
        uint256 qty,
        uint256 price
    ) public payable {
                require(
        NFTs[orderid][0].status == NFTstatus.Active,
        "Product is not active"
    );
        require(
            msg.sender !=  NFTs[orderid][0].seller,
            "owner cannot call this this function"
        );
        require( NFTs[orderid][0].isERC721 == false);

        NFTmarket storage soldDetail = NFTs[orderid][0];
        buyer = soldDetail.buyer;
        ERC1155(nftAddress).safeTransferFrom(seller, buyer, tokenid, qty, "");

            require(msg.value == price, "prices are not matching");
            payable(seller).transfer(price);
       
        NFTs[orderid][0].status == NFTstatus.not_Active;

        NFTs[orderid][0].buyer = buyer;
    }

    function makeOfferFixed(
        uint256 orderid,
        uint256 price,
        uint256 duration,
        address token
    ) public {
        // NFTmarket storage soldDetail=NFTs[orderid];
        address buyer = msg.sender;
        require(
            NFTs[orderid][0].status == NFTstatus.Active,
            "product is not active"
        );

        makeOffer memory FixedOffer = makeOffer({
            bidder: buyer,
            amount: price,
            timestamp: duration,
            token: IERC20(token)
        });
        BidlistArray[orderid].push(FixedOffer);
    }



    function acceptOfferFixed(
        uint256 orderid,
        uint256 bidamount,
        address bidder
    ) external payable {
        require(msg.sender == NFTs[orderid][0].seller, "caller must be owner");
        NFTmarket storage soldDetail = NFTs[orderid][0];
        address nftAddress = soldDetail.ScAdress;
        address seller = soldDetail.seller;
        uint256 tokenid = soldDetail.tokenid;
        uint256 qty = soldDetail.quantity;
        address token = soldDetail.token;



        address[] memory creators = new address[](UserFeeList[tokenid].length);
        uint256[] memory amount = new uint256[](UserFeeList[tokenid].length);
        uint256[] memory percentage = new uint256[](
            UserFeeList[tokenid].length
        );
        uint256 balce;


        if (token == address(0)) {
            payable(seller).transfer(bidamount);
        } else {

        for (uint256 i = 0; i < UserFeeList[tokenid].length; i++) {
            percentage[i] = (bidamount * amount[i]) / 10000;
            balce = percentage[i] - bidamount;
            _token.transfer(creators[i], percentage[i]);
        }
            IERC20(token).transferFrom(bidder, seller, balce);
        }
        ERC1155(nftAddress).safeTransferFrom(seller, bidder, tokenid, qty, "");
        NFTs[orderid][0].status == NFTstatus.not_Active;
    }




    function updateListing(uint256 orderid, uint256 newprice) external {
        address seller = NFTs[orderid][0].seller;
        require(msg.sender == seller, "caller must be owner");
        // NFTs[orderid][0].price = newprice;
    }

    function viewlistbyseller() external view returns (NFTmarket[] memory) {
        uint256 totalitemcount = orders.current();
        uint56 itemCOunt = 0;
        uint256 currentindex = 0;
        for (uint256 i = 0; i < totalitemcount; i++) {
            if (NFTs[i + 1][0].seller >= msg.sender) {
                itemCOunt += 1;
            }
        }
        NFTmarket[] memory items = new NFTmarket[](itemCOunt);
        for (uint256 i = 0; i < totalitemcount; i++) {
            if (NFTs[i + 1][0].seller >= msg.sender) {
                uint256 currentId = i + 1;
                NFTmarket storage currentitem = NFTs[currentId][0];
                items[currentindex] = currentitem;
                currentindex += 1;
            }
        }
        return items;
    }

    function viewlistbybuyer() external view returns (NFTmarket[] memory) {
        uint256 totalitemcount = orders.current();
        uint256 itemcount = 0;
        uint256 currentindex = 0;
        for (uint256 i = 0; i < totalitemcount; i++) {
            if (NFTs[i + 1][0].buyer >= msg.sender) {
                itemcount += 1;
            }
        }
        NFTmarket[] memory items = new NFTmarket[](itemcount);
        for (uint256 i = 0; i < totalitemcount; i++) {
            if (NFTs[i + 1][0].buyer >= msg.sender) {
                uint256 currentid = i + 1;
                NFTmarket storage currentitem = NFTs[currentid][0];
                items[currentindex] = currentitem;
                currentindex += 1;
            }
        }
        return items;
    }

    function showoffers(uint256 orderid)
        external
        view
        returns (makeOffer[] memory)
    {
        return BidlistArray[orderid];
    }
}
