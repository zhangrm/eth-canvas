pragma solidity ^0.4.21;

import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';
import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import 'openzeppelin-solidity/contracts/payment/PullPayment.sol';
import 'openzeppelin-solidity/contracts/lifecycle/Destructible.sol';
import 'openzeppelin-solidity/contracts/lifecycle/Pausable.sol';
import './NamespaceProxy.sol';
import './Map.sol';

contract BuyControler is Ownable, PullPayment, Pausable, Destructible {
    using SafeMath for uint256;

    NamespaceProxy npContract;
    //200 Szabo
    uint constant basePrice = 200000000000000;

    event BuyPointSucceed(uint indexed x, uint indexed y, uint8 color);

    constructor(address NpAddr) public {
        npContract = NamespaceProxy(NpAddr);
    }

    function getPointPrice(uint x, uint y) public view returns (uint price, uint payLast) {
        Map map = Map(address(npContract.getContract("Map")));
        //		uint cnt = map.cntMap(x, y);
        //price= cnt*2*basePrice+basePrice
        payLast = SafeMath.mul(SafeMath.mul(map.cntMap(x, y), 2), basePrice);
        price = SafeMath.add(payLast, basePrice);
    }



    modifier isAllow(uint x, uint y, uint8 color) {
        require(x < 50 && y < 50 && color > 0 && color < 255);
        _;
    }

    function paintPoint(uint x, uint y, uint8 color) internal returns (address last) {
        Map map = Map(address(npContract.getContract("Map")));
        last = map.ownerMap(x, y);
        map.setMap(x, y, color, msg.sender);
    }


    function sendBuyPayment(address lastOwner, uint payLast) internal {
        if (lastOwner != address(0) || payLast == 0) {
            asyncTransfer(lastOwner, payLast);
            asyncTransfer(address(0xAbF74C68A27057c5124f3880BE70563bb52879DA), basePrice);
        }
    }

    function buyPoint(uint x, uint y, uint8 color) public payable isAllow(x, y, color) whenNotPaused {
        uint price;
        uint payLast;
        (price, payLast) = this.getPointPrice(x, y);
        require(msg.value >= price);
        //set
        //		address lastOwner = paintPoint(x, y, color);
        //sendPay

        sendBuyPayment(paintPoint(x, y, color), payLast);
        emit BuyPointSucceed(x, y, color);
    }
}
