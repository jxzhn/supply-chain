const Configuration = require('./nodejs-sdk/packages/api').Configuration;
const CompileService = require('./nodejs-sdk/packages/api').CompileService;

let config = new Configuration('config.json');

const readline = require('readline');
const fs = require("fs");

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
    let compServ = new CompileService(config);

    let name = await input('contract name: ');

    console.log('Compiling ...');
    let contractClass = compServ.compile(`contracts/${name}.sol`);

    fs.writeFile(`compiled/${name}.json`, JSON.stringify(contractClass), (err) => {
        if (err) {
            console.log('Failed to wirte compiled file.');
            console.log(err);
        } else {
            console.log('Compiled file saved.');
        }
    });
}

main();