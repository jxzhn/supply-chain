pragma solidity >=0.4.24 <0.6.11;

contract SupplyChain {

    struct Company {
        string name;
        uint amount;
        uint8 field; // 使用0表示公司为其他领域，1表示公司为金融机构
        bool kernel; // 是否为核心企业（只有核心企业可以发放账单）
        bool registered; // mapping里面判断是否已存在
    }

    struct Receipt {
        address from;
        address to;
        uint amount;
        uint8 status; // 使用0表示账单未清算，1表示已清算
    }

    address private ca; // 认证机构的地址，本合约由认证机构部署

    mapping(address => Company) private companies;

    Receipt[] private receipts;

    constructor() public {
        ca = msg.sender;
    }

    // 注册一个公司，只能由认证机构调用
    // 返回值：0表示成功，-1表示已存在
    //        -2表示该公司为金融机构无法为核心企业
    function registerCompany(address addr, string memory name, uint amount, uint8 field, bool kernel) public returns(int8) {
        require(msg.sender == ca, "Only CA can register company!");

        if (kernel && field == 1) {
            return -2;
        }

        Company storage company = companies[addr]; // 引用

        if (company.registered) {
            return -1;
        }

        company.name = name;
        company.amount = amount;
        company.field = field;
        company.kernel = kernel;
        company.registered = true;

        return 0;
    }

    // 功能一：实现采购商品—签发应收账款交易上链
    // 返回值：0表示成功，-1表示公司未注册，
    //        -2表示公司不是核心企业，无法发放账单
    function createReceipt(address to, uint amount) public returns(int8) {
        Company storage company = companies[msg.sender]; // 引用

        if (!company.registered) {
            return -1;
        }
        
        if (!company.kernel) {
            return -2;
        }

        receipts.push(Receipt({
            from: msg.sender,
            to: to,
            amount: amount,
            status: 0
        }));
        return 0;
    }
    
    // 功能二：实现应收账款的转让上链
    // 返回值：0表示成功，-1表示可转让账单金额不足
    function transferReceipt(address to, uint amount) public returns(int) {
        require(msg.sender != to, "You can not transfer receipt to yourself.");

        uint count = 0; // 统计可转让金额

        for (uint i = 0; i < receipts.length; ++i) {
            if (receipts[i].to != msg.sender || receipts[i].status == 1) {
                continue;
            }

            count += receipts[i].amount;
            if (count >= amount) {
                break;
            }
        }

        if (count < amount) {
            return -1;
        }

        for (uint i = 0; i < receipts.length; ++i) {
            if (receipts[i].to != msg.sender || receipts[i].status == 1) {
                continue;
            }

            if (amount > receipts[i].amount) { // 额度还不够，直接把to改了就行了
                receipts[i].to = to;
                amount -= receipts[i].amount;
            
            } else { // 减去对应金额，然后创建一个新账单
                receipts[i].amount -= amount;
                
                receipts.push(Receipt({
                    from: receipts[i].from,
                    to: to,
                    amount: amount,
                    status: 0
                }));
                break;
            }
        }

        return 0;
    }

    // 功能三：利用应收账款向银行融资上链
    // 返回值：0表示成功，-1表示to参数不是金融机构，
    //        -2表示金融机构账户额度不足，
    //        -3表示请求融资的机构账单额度不足
    function useReceipt(address to, uint amount) public returns(int8) {
        Company storage bank = companies[to]; // 引用
        Company storage company = companies[msg.sender]; // 引用

        if (bank.field != 1) {
            return -1;
        }

        if (bank.amount < amount) {
            return -2;
        }

        if (transferReceipt(to, amount) != 0) {
            return -3;
        }

        bank.amount -= amount;
        company.amount += amount;

        return 0;
    }

    // 功能四：应收账款支付结算上链
    // 返回值：0表示成功，-1表示企业不是核心企业，
    //        -2表示企业额度不足
    function settleReceipt() public returns(int8) {
        Company storage company = companies[msg.sender]; // 引用

        if (!company.kernel) {
            return -1;
        }

        uint debt = 0; // 统计欠款金额

        for (uint i = 0; i < receipts.length; ++i) {
            // 属于该公司的未清算账单
            if (receipts[i].from == msg.sender && receipts[i].status == 0) {
                debt += receipts[i].amount;
            } 
        }
       
        if (debt > company.amount){ // 公司还款金额不够，无法清算
            return -2;
        }

        for (uint i = 0; i < receipts.length; ++i) {
            // 属于该公司的未清算账单
            if (receipts[i].from == msg.sender && receipts[i].status == 0) {
                // 给拥有该账单的公司打钱
                companies[receipts[i].to].amount += receipts[i].amount;
                // 改为清算状态
                receipts[i].status = 1;
            } 
        }

        // 公司的账户扣款
        company.amount -= debt;

        return 0;
    }

    // 查询自己的余额
    // 返回值：第一个值：0表示成功，-1表示公司未注册
    //        第二个值：余额
    function getAmount() public view returns(int8, uint) {
        Company storage company = companies[msg.sender]; // 引用

        if (!company.registered) {
            return (-1, 0);
        }

        return (0, company.amount);
    }

    // 查询自己拥有的账单及账单总额
    // 返回值：第一个值：账单总额
    //        第二个值：账单索引数组
    // function getReceipts() public view returns(uint, uint[] memory) {
    //     uint amount;
    //     uint[] memory indice;
        
    //     for (uint i = 0; i < receipts.length; ++i) {
    //         if (receipts[i].to == msg.sender) {
    //             amount += receipts[i].amount;
    //             indice.push(i);
    //         }
    //     }

    //     return (amount, indice);
    // }

}