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
    let name = await input('Which contract are you gonna deploy? ');

    console.log('Loading contract from compiled file ...');
    let compiled = JSON.parse(fs.readFileSync(`compiled/${name}.json`))

    let account = await input('Which account are you gonna use? ');
    let parameters = (await input('Parameters of constructor (split by space): ')).split(
        /\s+/).filter(item => Boolean(item)); // 去除空串

    console.log(`Trying to deploy contract ${name} ...`);
    try {
        let res = await web3j.deploy(compiled.abi, compiled.bin, parameters, account);
        console.log(res);
    
        fs.writeFile(`deployed/${name}.json`, JSON.stringify(res), (err) => {
            if (err) {
                console.log('Contract deployed, but failed to write deployed file.');
                console.log(err);
            } else {
                console.log('Deployed file saved.');
            }
        });
    } catch(err) {
        console.log('Failed.');
        console.log(err);
    }
}

main();