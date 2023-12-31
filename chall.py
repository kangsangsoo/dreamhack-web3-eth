from flask import Flask, Response, redirect, request
import json
import os
import time
from dataclasses import dataclass
from typing import Callable, Dict, List, Optional
import os
import subprocess
import signal
import json
import time
from dataclasses import dataclass
from threading import Lock, Thread
from typing import Any, Dict, Tuple
from uuid import uuid4
from flask import Flask, request, jsonify
import requests
from eth_account.hdaccount import generate_mnemonic
from flask import Flask, Response, redirect, request
import requests
from eth_account import Account
from web3 import Web3
from web3.exceptions import TransactionNotFound
from web3.types import TxReceipt
from pathlib import Path

port = 31337
user_prikey = "0xdba103874bd715cb05989d00d55f53743dbca7c13c77b2b901c4b6ae90232b5e"
deployer_prikey = "?"
user_addr = "0x377CFaD82A885Ef59C9243f715F33752804B1126"
deployer_addr = "0x628a5f752D0d2f7a3a5E3a326041a46bc59f1A33"
deployed_cont = "0x3e8C8ec7F7a5A51a7B4509d2f4d534BB3bA040b1"
FLAG = "DH{fake_flag}"
cur_node = {}

app = Flask(__name__)



def deploy_cont(web3: Web3):
    tx = {
        "from": deployer_addr,
        "value": 0,
        "data": json.loads(Path("compiled/Setup.sol/Setup.json").read_text())["bytecode"]["object"],
        "gas": 10**7,
        "nonce": 0,
        "gasPrice": web3.eth.gas_price,
    }
    stx = web3.eth.account.sign_transaction(tx, private_key=deployer_prikey)
    transaction_hash = web3.eth.send_raw_transaction(stx.rawTransaction)
    # Wait for the transaction to be mined, and get the transaction receipt
    transaction_receipt = web3.eth.wait_for_transaction_receipt(transaction_hash)


def launch_node() -> Dict:
    mnemonic = 'flush vote quit stone sugar wrist slam ankle embrace urban gossip vast'

    proc = subprocess.Popen(
        args=[
            "/root/.foundry/bin/anvil",
            # "/home/kang/.foundry/bin/anvil",
            "--accounts",
            "2",  # first account is the deployer, second account is for the user
            "--balance",
            "1", # 1 ether
            "--mnemonic",
            mnemonic,
            "--port",
            str(port),
            # "--fork-url",
            # ETH_RPC_URL,
            "--block-base-fee-per-gas",
            "0",
        ],
    )

    web3 = Web3(Web3.HTTPProvider(f"http://127.0.0.1:{port}"))
    while True:
        if proc.poll() is not None:
            return None
        if web3.is_connected():
            break
        time.sleep(0.1)

    node_info = {
        "port": port,
        "pid": proc.pid,
    }

    deploy_cont(web3)
    return node_info

@app.route("/flag", methods=["GET"])
def check_flag():
    web3 = Web3(Web3.HTTPProvider(f"http://127.0.0.1:{port}"))
    result = web3.eth.call(
        {
            "to": deployed_cont,
            "data": "0x64d98f6e",
        }
    )
    result = int(result.hex(), 16) == 1

    if result == False:
        return {
            "ok": False,   
            "text": "really did you solve this?" 
        }

    return {
        "ok": True,
        "flag": FLAG,
    }

RPC_SERVER_URL = f"http://127.0.0.1:{port}"

@app.route('/rpc', methods=['GET', 'POST', 'PUT', 'DELETE'])
def proxy():
    if request.method == 'GET':
        response = requests.get(f"{RPC_SERVER_URL}", params=request.args)
    elif request.method == 'POST':
        response = requests.post(f"{RPC_SERVER_URL}", json=request.json)
    elif request.method == 'PUT':
        response = requests.put(f"{RPC_SERVER_URL}", json=request.json)
    elif request.method == 'DELETE':
        response = requests.delete(f"{RPC_SERVER_URL}", params=request.args)
    
    return jsonify(response.json()), response.status_code

if __name__ == "__main__":
    launch_node()
    app.run(host="0.0.0.0", port=10089)