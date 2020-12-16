pragma solidity >=0.4.24 <0.6.11;
pragma experimental ABIEncoderV2; // 返回结构体

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
    // 返回值：0表示成功，-1表示公司未注册，
    //        -2表示可转让账单金额不足
    function transferReceipt(address to, uint amount) public returns(int) {
        require(msg.sender != to, "You can not transfer receipt to yourself.");

        Company storage company = companies[msg.sender]; // 引用
        if (!company.registered) {
            return -1;
        }

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
            return -2;
        }

        for (uint i = 0; i < receipts.length; ++i) {
            if (receipts[i].to != msg.sender || receipts[i].status == 1) {
                continue;
            }

            if (amount >= receipts[i].amount) { // 这张账单需要全部使用，直接把to改了就行了
                receipts[i].to = to;
                amount -= receipts[i].amount;

                if (amount == 0) break;
            
            } else { // 只需使用账单的一部分就能抵扣完毕，减去对应金额，然后创建一个新账单
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
    // 返回值：0表示成功，-1表示公司未注册，
    //        -2表示to参数对应公司未注册或不是金融机构，
    //        -3表示金融机构账户额度不足，
    //        -4表示请求融资的机构账单额度不足
    function useReceipt(address to, uint amount) public returns(int8) {
        Company storage bank = companies[to]; // 引用
        Company storage company = companies[msg.sender]; // 引用

        if (!company.registered) {
            return -1;
        }

        if (!bank.registered || bank.field != 1) {
            return -2;
        }

        if (bank.amount < amount) {
            return -3;
        }

        if (transferReceipt(to, amount) != 0) {
            return -4;
        }

        bank.amount -= amount;
        company.amount += amount;

        return 0;
    }

    // 功能四：应收账款支付结算上链
    // 返回值：0表示成功，-1表示企业未注册或不是核心企业，
    //        -2表示企业额度不足
    function settleReceipt() public returns(int8) {
        Company storage company = companies[msg.sender]; // 引用

        if (!company.registered || !company.kernel) {
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
    function getReceipts() public view returns(uint, uint[] memory) {
        uint amount = 0;
        uint counter = 0;
        
        for (uint i = 0; i < receipts.length; ++i) {
            if (receipts[i].to == msg.sender && receipts[i].status == 0) {
                amount += receipts[i].amount;
                ++counter;
            }
        }

        uint[] memory indice = new uint[](counter); // memory数组只能定长，没办法
        counter = 0;
        for (uint i = 0; i < receipts.length; ++i) {
            if (receipts[i].to == msg.sender && receipts[i].status == 0) {
                indice[counter++] = i;
            }
        }

        return (amount, indice);
    }

    // 查询自己负债的账单及账单总额
    // 返回值：第一个值：账单总额
    //        第二个值：账单索引数组
    function getDebts() public view returns(uint, uint[] memory) {
        uint amount = 0;
        uint counter = 0;
        
        for (uint i = 0; i < receipts.length; ++i) {
            if (receipts[i].from == msg.sender && receipts[i].status == 0) {
                amount += receipts[i].amount;
                ++counter;
            }
        }

        uint[] memory indice = new uint[](counter); // memory数组只能定长，没办法
        counter = 0;
        for (uint i = 0; i < receipts.length; ++i) {
            if (receipts[i].from == msg.sender && receipts[i].status == 0) {
                indice[counter++] = i;
            }
        }

        return (amount, indice);
    }

    // 根据账单下标查询账单明细
    // 返回值：Receipt结构体
    function getReceiptDetail(uint index) public view returns (Receipt memory) {
        require(index < receipts.length, "Receipt ID is not legal!");
        
        Receipt memory rcpt = receipts[index];
        require(msg.sender == rcpt.to || msg.sender == rcpt.from, "You don't have access to this receipt.");

        return rcpt;
    }

}