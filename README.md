# supply-chain

基于 FISCO-BCOS 区块链的供应链金融平台。《区块链原理》课程大作业。

<table border="1">
    <tr>
        <td colspan="4">小组成员及分工</td>
    </tr>
    <tr>
        <td width="25%"><b>姓名</b></td>
        <td width="25%"><b>学号</b></td>
        <td width="25%"><b>班级</b></td>
        <td width="25%"><b>分工</b></td>
    </tr>
    <tr>
        <td width="25%">甘家振</td>
    	<td width="25%">18340043</td>
        <td width="25%">计科2班</td>
        <td width="25%">前端/后端/链端</td>
    </tr>
    <tr>
        <td width="25%">胡邱诗雨</td>
    	<td width="25%">18340056</td>
        <td width="25%">计科3班</td>
        <td width="25%">前端/链端</td>
    </tr>
    <tr>
        <td width="25%">谢善睿</td>
    	<td width="25%">18340184</td>
        <td width="25%">计科7班</td>
        <td width="25%">前端/链端</td>
    </tr>
</table>


实验报告见 [report.pdf](report.pdf)。

演示视频见 [demo.mp4](demo.mp4)。

目录文件说明：

* accounts: 区块链账户的公钥和私钥。
* authentications: FISCO-BCOS 区块链链授权文件。
* compiled: 存放合约编译结果文件，这些文件应由 compile.js产生。
* contracts: 待编译的 Solidity 合约代码。
* deployed: 存放合约部署结果文件，这些文件应由 deploy.js产生。
* nodejs-sdk: FISCO-BCOS Node.js SDK。
* web: 前端网页代码。
* app.js: 提供 web 前端 HTTP 站点及后端的 HTTP 合约调用服务。
* compile.js: 用于编译 Solidity 合约。
* config.json: FISCO-BCOS Node.js SDK 配置文件。
* main.js: 使用 Node.js SDK 实现的命令行合约调用工具。

