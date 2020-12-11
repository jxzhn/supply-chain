const Configuration = require('./nodejs-sdk/packages/api').Configuration;
const Web3jService = require('./nodejs-sdk/packages/api').Web3jService;
const createContractClass = require('./nodejs-sdk/packages/api/compile/contractClass').createContractClass;

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
    let name = await input('which contract are you going to use? ');

    console.log('Loading contract from compiled file ...');
    let compiled = JSON.parse(fs.readFileSync(`compiled/${name}.json`))

    let contract = createContractClass(
        compiled.name, compiled.abi, compiled.bin, config.encryptType
    ).newInstance();

    console.log('Loading deployed contract address from deployed file ...');
    let contractAddr = JSON.parse(fs.readFileSync(`deployed/${name}.json`))['contractAddress'];
    contract.$load(web3j, contractAddr);

    console.log('Done.');

    while (1) {
        let instruction = (await input('> ')).split(/\s+/);

        let method = instruction[0];
        let parameters = instruction.splice(1);

        if (method == '.exit') { // 退出
            break;
        }

        if (!contract[method]) {
            console.log(`undefined method '${method}'`);
            continue;
        }
        try {
            // contract.$by('bob');
            let res = await contract[method](...parameters);
            console.log(res);
        } catch(err) {
            console.log('error occurred.');
            console.log(err);
        }
    }
}

main();
