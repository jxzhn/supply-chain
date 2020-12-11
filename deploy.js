const Configuration = require('./nodejs-sdk/packages/api').Configuration;
const Web3jService = require('./nodejs-sdk/packages/api').Web3jService;

let config = new Configuration('config.json');
let web3j = new Web3jService(config);

const readline = require('readline');
const fs = require('fs');

async function input(query) {
    let rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout
    });
    return new Promise((resolve, reject) => {
        rl.question(query, (res) => {
            rl.close();
            resolve(res);
        });
    });
}

async function main() {
    let name = await input('contract name: ');

    console.log('Loading contract from compiled file ...');
    let compiled = JSON.parse(fs.readFileSync(`compiled/${name}.json`))

    console.log(`Trying to deploy contract ${name} ...`);
    // 实际上还应该指定who参数来明确不同account的职能，先不管
    let res = await web3j.deploy(compiled.abi, compiled.bin, []); // 默认构造函数没有参数
    console.log(res);

    fs.writeFile(`deployed/${name}.json`, JSON.stringify(res), (err) => {
        if (err) {
            console.log('Failed to write deployed file.');
            console.log(err);
        } else {
            console.log('Deployed file saved.');
        }
    });
}

main();