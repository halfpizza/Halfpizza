pragma solidity ^0.5.8;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.8;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function mint(address account, uint amount) external;

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function burn(uint256 amount) external;

    event Transfer(address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
pragma solidity ^0.5.8;

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly {codehash := extcodehash(account)}
        return (codehash != 0x0 && codehash != accountHash);
    }

    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success,) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}
pragma solidity ^0.5.8;

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {

        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract TokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    IERC20 private pizza = IERC20(address(0xFC646D0B564bf191B3d3adF2B620a792E485e6Da));//pizza代币0xFC646D0B564bf191B3d3adF2B620a792E485e6Da
    IERC20 private candy = IERC20(address(0x4bfd87AC580Eda0A724745F0DbA4A615fed9ca4e));//swet代币
    function transCandy(address _to, uint256 amount) internal {
        candy.transfer(_to, amount);
    }

    function transPizza(address _to, uint256 amount) internal {
        pizza.transfer(_to, amount);
    }

    function transCandyFrom(address _from, address _to, uint256 amount) public {
        candy.transferFrom(_from, _to, amount);
    }

    function transPizzaFrom(address _from, address _to, uint256 amount) public {
        pizza.safeTransferFrom(_from, _to, amount);
    }
}
// 1.质押，每次至少1000个，并且游戏开始才能投注。
// 2.每天0点开始，0点10分质押结束。由发币帐户设置开关。
// 3.0点42分开奖。由发币帐户调用接口，传入比赛结果。
// 4.输赢分配：赢的一方，按比例分配输家的90%,4%分给链上持有pizza大于1万枚的地址，
// 先放入奖金池，当奖金池大于1000万的时候，自动发放。3%转入流动性奖金池。2%燃烧，1%
// 奖励给引荐者。如果没有引荐者，则归入到奖金池。
// 5.推荐关系要保留。
// 6.保存看涨资金多少，人数，看跌资金，人数。游戏记录，地址，输多少，赢多少。
// 7.外卖部奖金池分红。当大于1000万时候，10%给外卖社区 ，90%按持有的pizz分红。
//保存看涨奖金，人数，看跌奖金，人数。



contract pizza is TokenWrapper {
    using SafeMath for uint256;
    uint256 decimal = 10 ** 18;
    uint256 constant public INVEST_MIN_AMOUNT = 1000 * 10 ** 18;// 最小质押数量
    uint256 constant private startTime = 1628503200;//时间戳常量
    uint256[] private REFERRAL_PERCENTS = [90, 4, 3, 2, 1];//90%分配给赢家，4%分配给持有pizz大于1万的地址。3%存入流动性,2%燃烧,1%推荐者

    address private governance;//所有者
    address public  sotorageAddress=address(0x7FcF748e599EC2F9CA4B38Fd03647E9C1Ff8F93b);//店铺地址奖金地址
    address public  lpAddress=address(0xee8C6C096ffE232Cd36439E2b74603CE1ACF7f76);//外卖部奖金地址

    uint256 private totalDiscount;//总燃烧值
    
    uint256 private totalPizzaPrize;//总店铺奖金值
    uint256 private totalPrizzaPrizeWithdraw; //记录店铺已提取额度
    
    uint256 private totalIpPrize;//总外卖部奖金

    uint256 private userTotalWithdraw;//用户总提取

    struct Record {
        uint256 winCount;//看涨的人数
        uint256 winSum;//看涨的资金
        uint256 loseCount;//看跌的人数
        uint256 loseSum;//看跌的资金
        bool flag;//是否开奖
        bool result;//结果
    }

    struct ResultDetail {
        uint256 userPrize;//用户奖金
        uint256 pizzaPrize;//店铺奖金值
        uint256 lpPrize;//外卖部奖金
        uint256 destructionPrize;//燃烧值
        uint256 referPrize;//推荐者奖金
    }

    struct Deposit {
        uint256 amount;//投注的数量
        bool results;//投注意向
        uint256 count;//投注期数;
    }
    modifier isOwner{
        require(msg.sender == governance, "!governance");
        _;
    }
    struct User {
        Deposit[] deposits;//投注信息
        address referrer; //推荐人
        uint256[] counts;//投资了期数
        uint256 withdrawBalance;
        uint256 withdrawReferrer;
        uint256 withdrawTotal;
        uint256 investTotal;
    }

    mapping(address => User) internal users;
    mapping(uint256 => Record) internal records;
    mapping(uint256 => ResultDetail) internal allResults;

    mapping(address => Deposit[]) addressRefer;
    Deposit[] private noReferDeposit;//记录没有推荐人的投注用于计算奖金
    constructor () public {
        governance = msg.sender;
    }
    //function changeOwner(address _owner) isOwner public {
    //    governance = _owner;
    //}

    //function getOwner() public view returns (address) {
    //    return governance;
    //}

    function startisok() public view returns (bool) {
        uint256 count =(block.timestamp - startTime) / 60;
        //期数
        //必须游戏开始才能投注,用时间戳除以60，个位数为几分钟，我们取个位数小于3即为03，13，23，33分以内的数据
        uint256 timeFlag = count - count / 10 * 10;
        if (timeFlag < 3) {
            return true;
        } else {
            return false;
        }
    }

    function invest(address referrer, uint256 result, uint256 amount) public payable {
        require(startisok() == true, 'game is not start');
        uint256 value = amount * decimal;
        require(value >= INVEST_MIN_AMOUNT, "value must grater 1000");
        uint256 count = getCount(block.timestamp);
        Record storage record = records[count];
        require(!record.flag, 'this count is end');
        User storage user = users[msg.sender];
        if (user.referrer == address(0) && referrer != msg.sender) {
            user.referrer = referrer;
        }


        bool tmp;
        if (result == 1) {
            record.winCount += 1;
            record.winSum += value;
            tmp = true;
        } else {
            record.loseCount += 1;
            record.loseSum += value;
            tmp = false;
        }
        Deposit memory userDeposit=Deposit(value, tmp, count);
        if (user.referrer != address(0)) {
            addressRefer[user.referrer].push(userDeposit);
        }else{
            noReferDeposit.push(userDeposit);
        }
        user.deposits.push(userDeposit);
        user.counts.push(count);
        user.investTotal = user.investTotal.add(amount);
        super.transPizzaFrom(msg.sender, address(this), value);
    }

    function getCount(uint256 times) public pure returns (uint256) {
        require(times >= startTime, 'error time');
        return (times - startTime) / 600;
    }

    function getinvestresult(uint256 times) public view returns (uint256, uint256, uint256, uint256, bool, bool){
        uint256 count = getCount(times);
        Record storage record = records[count];
        return (record.winSum, record.winCount, record.loseSum, record.loseCount, record.result, record.flag);
    }

    function setprize(uint256 times, uint256 flag) isOwner public {
        //开奖设置人，必须是合约发布者
        uint256 count = getCount(times);
        Record storage record = records[count];
        require(record.flag==false,"game is end");
        record.flag = true;
        bool result = (flag == 1) ? true : false;
        record.result = result;

        uint256 amount = record.winSum;
        uint256 userNum = record.winCount;
        if (result) {
            amount = record.loseSum;
            userNum = record.loseCount;
        }
        ResultDetail storage results = allResults[count];
        //每一期的结果数据
        if (amount > 0) {
            results.userPrize = amount * REFERRAL_PERCENTS[0] / 100;

            results.pizzaPrize = amount * REFERRAL_PERCENTS[1] / 100;
            totalPizzaPrize = totalPizzaPrize.add(amount * REFERRAL_PERCENTS[1] / 100);//累加店铺投注的奖金池

            results.lpPrize = amount * REFERRAL_PERCENTS[2] / 100;
            totalIpPrize = totalIpPrize.add(amount * REFERRAL_PERCENTS[2] / 100);

            results.destructionPrize = amount * REFERRAL_PERCENTS[3] / 100;
            totalDiscount = totalDiscount.add(amount * REFERRAL_PERCENTS[3] / 100);

            results.referPrize = amount * REFERRAL_PERCENTS[4] / 100;
        }
    }
    //获取当前平均值;
    function getaverage(uint256 times) public view returns (uint256){
        //查找次数
        uint256 count = getCount(times);
        Record storage record = records[count];
        if (record.flag == false) {
            return 0;
        }
        uint256 amount = record.loseSum;
        uint256 num = record.loseCount;
        if (record.result == true) {
            amount = record.winSum;
            num = record.winCount;
        }
        if (num > 0 && amount > 0) {
            return amount * REFERRAL_PERCENTS[0] / 100 / num / decimal;
        } else {
            return 0;
        }
    }
    //返回奖金池奖金
    function getpizzacount() public view returns (uint256) {
        uint256 noRefer=getNotRefer();
        uint balance=noRefer.add(totalPizzaPrize);//剩余总奖金=店铺奖金+没有推荐人的奖金-已提取奖金
        if((balance>0)&&(totalPrizzaPrizeWithdraw>0)){
            balance=balance.sub(totalPrizzaPrizeWithdraw);
        }
        return balance / decimal;
    }
    // 外卖部奖金池数量
    function getlpprize() public view returns (uint256){
        return totalIpPrize / decimal;
    }
    //用户投资了那几期
    function getmyicount(address ads) public view returns (uint256[] memory){
        User storage user = users[ads];
        return user.counts;
    }

    function getdiscount() public view returns (uint256) {
        return totalDiscount / decimal;
    }

    function getallWithdraw() public view returns (uint256){
        return userTotalWithdraw / decimal;
    }

    function getmydepotcount(address ads) public view returns (uint256){
        User storage user = users[ads];
        return user.deposits.length;
    }
    //我一共领了多少个
    function mywethdrawn(address ad) public view returns (uint256){
        User storage user = users[ad];
        return user.withdrawTotal/ decimal;
    }
    //转出candy
    function tranfercandy(address _to, uint256 amount) public isOwner payable {
        super.transCandy(_to, amount * decimal);
    }

    //我的投注（投注数量 ，是否中奖，盈亏，投注涨跌，是否开奖  ）
    function mydepots(address ads, uint256 iCount) public view returns (uint256, bool, uint256, bool, bool){
        User storage user = users[ads];
        uint256 count = user.deposits[iCount].count;
        Record  storage record = records[count];
        uint256 winLoseSum = 0;
        bool result = false;

        if (record.flag) {
            if (record.result == user.deposits[iCount].results) {
                ResultDetail storage detail = allResults[count];
                uint256 sum = record.result ? record.winSum : record.loseSum;
                if ((detail.userPrize > 0) && (sum > 0)) {
                    winLoseSum = detail.userPrize * user.deposits[iCount].amount / sum;
                }
                result = true;
            } else {
                winLoseSum = user.deposits[iCount].amount;
            }
        }
        return (user.deposits[iCount].amount / decimal, result, winLoseSum / decimal, user.deposits[iCount].results, record.flag);
    }

    //转pizza到店铺
    function tranferpizzatolp(address _to, uint256 amount) public {
        super.transPizzaFrom(msg.sender, address(this), amount * decimal);
        super.transPizza(_to, amount * decimal);
    }
    //向社区奖金池转帐pizza
    function transshequprize(uint256 amount) public {
        address _to = address(0xd41E4dA6cbe51a0B5602d9728B4833b9DdA0cE64);
        super.transPizzaFrom(msg.sender, _to, amount * decimal);
    }
    function getNotRefer() internal view returns(uint256) {
        uint256 totalRefer=0;
        for(uint256 i=0;i<noReferDeposit.length;i++){
            uint256 count=noReferDeposit[i].count;
            Record memory record=records[count];
            if(record.flag&&(record.result==noReferDeposit[i].results)){//开奖了并且中奖才计算 
                ResultDetail memory detail=allResults[count];
                uint256 sum=record.result?record.winSum:record.loseSum;
                if(detail.referPrize>0){
                    totalRefer=totalRefer.add(detail.referPrize*noReferDeposit[i].amount/sum);
                }
            }
        }
        return totalRefer;
    }
    //取出合约取出店铺奖金池 
    function withdrawPizzaPrice(uint256 amount) public   isOwner payable{
        require(amount>0,"low-level error");
        uint256 noRefer=getNotRefer();
        uint256 total=amount*decimal;
        uint balance=noRefer.add(totalPizzaPrize);//剩余总奖金=店铺奖金+没有推荐人的奖金-已提取奖金
        if((balance>0)&&(totalPrizzaPrizeWithdraw>0)){
            balance=balance.sub(totalPrizzaPrizeWithdraw);
        }
        require(total<=balance,"Insufficient Balance");
        totalPrizzaPrizeWithdraw=totalPrizzaPrizeWithdraw+total;
        super.transPizza(sotorageAddress,total);
    }
    
     //取出外卖部奖金池 
    function withdrawIpPrice(uint256 amount) public isOwner payable{
        uint total=amount*decimal;
        require(total<=totalIpPrize,"Insufficient Balance");
        super.transPizza(lpAddress,total);
        totalIpPrize=totalIpPrize-total;
    }

    //查询用户的资产
    function getinvestbalance(address ad) public view returns (uint256){
        return computeInvestBalance(ad);
    }
    function computeInvestBalance(address ad) internal view returns(uint256) {
        User storage user = users[ad];
        uint256 balance = 0;
        for (uint256 i = 0; i < user.deposits.length; i++) {
            Record storage record = records[user.deposits[i].count];
            if (record.flag && (user.deposits[i].results == record.result)) {
                ResultDetail storage detail = allResults[user.deposits[i].count];
                uint256 sum = record.result ? record.winSum : record.loseSum;
                if ((sum > 0) && (detail.userPrize > 0)) {
                    balance = balance.add(user.deposits[i].amount+user.deposits[i].amount * detail.userPrize / sum);
                } else {
                    balance = balance.add(user.deposits[i].amount);
                }
            }
        }
        if (balance > 0) {
            if (balance > user.withdrawBalance) {
                balance = balance.sub(user.withdrawBalance, "error balance");
            } else {
                balance = 0;
            }
        }
        return balance / decimal;
    }
    function userwithdraw() public payable {
        uint256 balance = computeInvestBalance(msg.sender);
        if (balance > 0) {
            balance=balance*decimal;
            User storage user = users[msg.sender];
            user.withdrawBalance = user.withdrawBalance.add(balance);
            user.withdrawTotal = user.withdrawTotal.add(balance);
            userTotalWithdraw = userTotalWithdraw.add(balance);

            super.transPizza(msg.sender, balance);
        }
    }

    function getreferprie(address ad) public view returns (uint256){
        return computeRefer(ad);
    }

    function computeRefer(address ad) internal view returns (uint256){
            Deposit[] storage refer = addressRefer[ad];
            User storage user = users[ad];
            uint256 balance = 0;
            for (uint256 i = 0; i < refer.length; i++) {
                Record storage record = records[refer[i].count];
                ResultDetail storage detail = allResults[refer[i].count];
                if (record.flag && (record.result == refer[i].results) && (detail.referPrize > 0)) {
                    uint256 sum = record.result ? record.winSum : record.loseSum;
                    if (sum > 0) {
                        balance = balance.add(detail.referPrize * refer[i].amount / sum);
                    }
                }
            }
            if (balance > 0) {
                if (balance > user.withdrawReferrer) {
                    balance = balance.sub(user.withdrawReferrer, "error refer");
                } else {
                    balance = 0;
                }
            }
            return balance / decimal;
    }


    function withdrawRefer() public  payable {
        uint256 balance = computeRefer(msg.sender);
        if (balance > 0) {
            balance=balance*decimal;
            User storage user = users[msg.sender];
            user.withdrawReferrer = user.withdrawReferrer.add(balance);
            user.withdrawTotal = user.withdrawTotal.add(balance);
            super.transPizza(msg.sender, balance);
            userTotalWithdraw = userTotalWithdraw.add(balance);
        }
    }

    function getuserbalance(address ad) public view returns (uint256){
        uint256 balance = getinvestbalance(ad);
        uint256 refer = getreferprie(ad);
        return balance.add(refer);
    }
} 
