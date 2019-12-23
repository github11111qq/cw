contract CW {

  
    struct Beter {
        uint256 pId;
        address payable addr;
        uint256 affId;
        string  inviteCode;
        uint256 round;
        uint256 invites;
        bool isSuper;

        
    }
   
    struct Order {
        uint256 id;
        uint256 pId;
        uint256 eth;
        uint256 rate; 
        uint256 day;
        bool    isExpire;
        uint256 gen;
        uint256 aff;
        uint256 startDateTime;
        //uint256 lastReleaseTime;
        uint256 endDateTime;
        bool affStatus;
        bool outStatus;
        bool bjStatus;

        

    }
    
 

    struct levelReward {    
    uint256 genRate;   
    uint256 deepAff;   
    uint256 ratio;   

    }

 

    struct BetHistory{
    uint256 pid;
    uint256 datetime;
    uint256 eth;
    uint256 rate;
    uint256 roit;

    }


    struct TokenHistory{
        address addr;
        uint8   acTionType;
        uint256 nums;
        uint256 datetime;
    }


    uint256 ethWei = 1 ether;
    using SafeMath for *;

    uint256  genReleTime_ = 24 hours;
    uint256 public  orderHistoryId_ = 0;
    uint256 public timeRid_ = 1;
    uint256 public  gDay_ = 15 days;
    uint256  private minbeteth_ = ethWei; 
    uint256 public gBet_ =0;
    uint256 public gCc_ =0;
    uint256 public gConsumeTicket_ = 0;
    uint256 public gTokenBuy_ = 0;

    uint256 public gOrderId_ =0;
    uint256 public gBetId_ = 0;
    bool public activated_ = true; 
    uint256 public gAffMax_ = 20;
    uint256 public gcs_ = 1000;
 
  
    uint256 public superOther_  = 5000 * ethWei;
   
    mapping (address => uint256)    public pIDxAddr_;           
    mapping (string   => uint256)   public  pIDInviteCode_;
    mapping (uint256 => Beter)  public plyr_;              
    mapping (uint256 => mapping (uint256 => BeterBase))  public beterBase_;           
    mapping (uint256 => mapping (uint256 => Reward))     public reward_;            
 
    uint256 public insurancePool_ = 0; 
    uint256 public insuranceStartTime_ = 0; 
    uint256 public insuranceTime_ = 72 hours;
    
    uint256 public partnerPot_= 0;
    
     

function buyCore(uint256 _pID,uint256 _eth)
    private
{
    
   
     
     require (onLineorderOutStatus(_pID) && beterBase_[plyr_[_pID].round][_pID].lastBet<=_eth,"your addr  not Expire or less eth!");
     
     (bool ticketStatus,uint256 needTicket,uint8 _type) =  checkTicket(_pID,_eth);
   
     require(ticketStatus,"you cannot to bet now");
     
     bool tokenStatus = false;
     if(_type == 1){
         tokenStatus = token_.xiaohaoFromDapp(plyr_[_pID].addr,needTicket);
     }else{
         tokenStatus = token_.transferFromDapp(plyr_[_pID].addr,adminTicket,needTicket); 
     }
    
     
    require(tokenStatus,"you cannot to bet now");
    insertTokenHistory(plyr_[_pID].addr,2,needTicket);
   
 
    beterBase_[plyr_[_pID].round][_pID].consumeTicket = beterBase_[plyr_[_pID].round][_pID].consumeTicket + needTicket; 
    gConsumeTicket_ = gConsumeTicket_+ needTicket;
     

    gBet_ = gBet_.add(_eth);
    gCc_= gCc_ + 1; 
     
    
    
    beterBase_[plyr_[_pID].round][_pID].genStatus = true;
    beterBase_[plyr_[_pID].round][_pID].affStatus = true;
 
   
      if(_eth.mul(2)/100>0){
        op.transfer(_eth.mul(2)/100);
    }
    
    partner.transfer(_eth.mul(1)/100);
     if(partnerPot_ >= 999 * ethWei){
         
         partnerPot_ = 0;
         
     }else{
         partnerPot_ = partnerPot_.add(_eth.mul(1)/100);
     }
     
    if( _eth.mul(5)/100>0){
        
        ipool.transfer( _eth.mul(5)/100);

        if(now > insuranceStartTime_.add(insuranceTime_)){

            insurancePool_ = 0;
        
       
        }else{
            insurancePool_ = insurancePool_.add( _eth.mul(5)/100);

        }
        
        insuranceStartTime_ = now;
    }
    checkOut(_pID);

    (uint8 genRate,uint8 ratio) = getOrderMsg(_eth); 
    reward_[plyr_[_pID].round][_pID].reward = _eth.mul(ratio);
    reward_[plyr_[_pID].round][_pID].curGen = 0;
    reward_[plyr_[_pID].round][_pID].curAff = 0;

 
    beterBase_[plyr_[_pID].round][_pID].baseGen = beterBase_[plyr_[_pID].round][_pID].baseGen.add(_eth.mul(genRate) /gcs_);
    uint256 _orderId = saveOrderHistory (_pID, _eth, genRate,gDay_,_eth.mul(genRate) /gcs_);

   
    affUpdate(_pID,plyr_[_pID].affId, _eth.mul(genRate) /gcs_,1,1,_eth,_orderId);
    
    
    calPerformance(_pID,_eth);

   
    beterBase_[plyr_[_pID].round][_pID].lastBet = _eth;
    beterBase_[plyr_[_pID].round][_pID].capitalTime = now + gDay_;
    beterBase_[plyr_[_pID].round][_pID].totalBet += _eth;
   
    beterBase_[plyr_[_pID].round][_pID].level = getUserLevel(_eth);
    
    
    (,uint256 otherPer,) = calDirectUserPer(_pID);

    if(otherPer >= superOther_ && !plyr_[_pID].isSuper){

        superUser_.push(_pID);
        plyr_[_pID].isSuper = true;

    }
}



 

function saveOrderHistory (uint256 _pID,uint256 _eth,uint256 _ratio,uint256 _day,uint256 _curBaseGen)  private returns(uint256 orderId) {
    
    uint256 curRoundId = plyr_[_pID].round;
    orderId = gOrderId_;
    orderHistroy_[orderId].id = orderId;
    orderHistroy_[orderId].pId =  _pID;
    orderHistroy_[orderId].eth = _eth;
    orderHistroy_[orderId].gen = _curBaseGen;
    orderHistroy_[orderId].startDateTime = now;
    
    orderHistroy_[orderId].endDateTime = now + _day;
    
    orderHistroy_[orderId].rate = _ratio;
    orderHistroy_[orderId].isExpire = false;
    orderHistroy_[orderId].affStatus = true;
    orderHistroy_[orderId].outStatus = true;
    orderHistroy_[orderId].bjStatus = true;
    orderHistroy_[orderId].day = _day;
    
    reward_[curRoundId][_pID].lastReleaseTime = now;
    reward_[curRoundId][_pID].orders.push(orderId);

    gOrderId_++; 

    
}
function getTokenPrice() view public returns(uint256 price){
        price = token_.getBuyPrice();
    }
    
 
function getUserToken(address addr) view public returns(uint256){
         
         uint256 balance = token_.balanceOfFromDapp(addr);
         return balance;
     }


function getOrderMsg (uint256 _eth) 
public
view
returns(uint8 rate,uint8 ratio) 
{
    
     if(_eth>=31 * ethWei){
        rate = 10;
        ratio = 5;

    }else if(_eth>=21 * ethWei){
        rate = 8;
        ratio = 4;

    }else if(_eth>=11 * ethWei){
        rate = 6;
        ratio = 3;

    }else if(_eth>=1 * ethWei){
        rate = 5;
        ratio = 2;

    }
}


 
function getUserLevel (uint256 _eth) 
public
view
returns(uint8 level) 
{
    
     if(_eth>=31 * ethWei){
        
        level = 4;

    }else if(_eth>=21 * ethWei){
       
        level = 3;

    }else if(_eth>=11 * ethWei){
        
        level = 2;

    }else if(_eth>=1 * ethWei){
       
        level = 1;

    }
}
function getAffRate (uint8 _level,uint8 _cctime) pure public returns(uint256 rate)  {

    rate = 0;
    if(_level == 1 && _cctime ==1){

        rate = 100;

    }else if(_level == 2){

        if(_cctime == 1){
            rate = 150;
        }else if(_cctime == 2){
            rate = 70;
        }

    }else if(_level == 3){

        if(_cctime == 1){
            rate = 200;
        }else if(_cctime == 2){
            rate = 100;
        }else if(_cctime == 3){
            rate = 50;
        }else if(_cctime >= 4 && _cctime <= 10){
            rate = 10;
        }
    }else if(_level == 4){

        if(_cctime == 1){
            rate = 300;
        }else if(_cctime == 2){
            rate = 150;
        }else if(_cctime == 3){
            rate = 70;
        }else if(_cctime >= 4 && _cctime <= 10){
            rate = 30;
        }else{
            rate = 3;
        }
    }
    
} 

 

function usersOrderId(uint256 _pid,uint256 cc)
public
view
returns(uint256 orderId)
{
    if(cc > reward_[plyr_[_pid].round][_pid].orders.length){
        
        return 0;
    }
    orderId = reward_[plyr_[_pid].round][_pid].orders[cc];
}

function getggreward(uint256 _pid)
public
view
returns(uint256 _reward){
    uint256 round = plyr_[_pid].round;
   
     (uint256 lessGen, uint256 lessAff ,) = getUserRewardByBase(_pid);
     uint256 _release =  reward_[round][_pid].curGen.add(reward_[round][_pid].curAff).add(lessGen).add(lessAff);
     _reward = reward_[round][_pid].reward>_release?reward_[round][_pid].reward.sub(_release):0;
}

function getsystemMsg()
public
view
returns(uint256 _gbet,uint256 _gTokenBuy,uint256 _tokenPrice,uint256 _consumeTicket,uint256 _inPool,uint256 _endTime,uint256 _totalSupply,uint256 _totalDestroy,uint256 _partnerPot)
{
    
    _gbet = gBet_;
    _gTokenBuy = gTokenBuy_;
    _tokenPrice = token_.getBuyPrice();
    _consumeTicket = gConsumeTicket_;
    _inPool = insurancePool_;
    _endTime = insuranceStartTime_+ insuranceTime_;
    _totalSupply = token_.balanceOfContact();
    _totalDestroy = token_.totalDestroyOfContact();
    _partnerPot = partnerPot_;

}




function insertTokenHistory (address addr,uint8 acTionType,uint256 nums) private   {
    
    TokenHistory memory t;
    t.acTionType =  acTionType;
    t.nums = nums;
    t.datetime = now;
    t.addr = addr;
    tokenHistory_.push(t);
    
}

function getTokenHistory(uint256 cc) view public returns(address addr ,uint8 acTionType,uint256 nums,uint256 datetime){
    
    if(cc >= tokenHistory_.length ){
         addr = 0x0000000000000000000000000000000000000000;
         acTionType = 0;
         nums = 0;
         datetime = 0;
    }
    acTionType=tokenHistory_[cc].acTionType;
    nums=tokenHistory_[cc].nums;
    addr=tokenHistory_[cc].addr;
    datetime=tokenHistory_[cc].datetime;  
    
}
}

