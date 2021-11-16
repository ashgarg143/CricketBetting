from os import cpu_count
from web3 import Web3
import time

import json
ganache_url = "http://127.0.0.1:7545"
web3 = Web3(Web3.HTTPProvider(ganache_url))
web3.eth.defaultAccount = web3.eth.accounts[0]
networkId = web3.net.version


with open("./betting/build/contracts/BettingContract.json") as f:
    info_json = json.load(f)
abi = info_json["abi"]
byteCode = info_json['bytecode']

with open("./oracle/build/contracts/BettingOracle.json") as f:
    oracle_json = json.load(f)
oracle_abi = oracle_json["abi"]

account_1 = web3.eth.accounts[0];
account_2 = web3.eth.accounts[1];
account_3 = web3.eth.accounts[2];

# print(account_1)
# print(account_2)
# print(account_3)

contract_address = info_json['networks'][networkId]['address']
oracleAddress = oracle_json['networks'][networkId]['address']

# print(contract_address)

address = web3.toChecksumAddress(contract_address)
contract = web3.eth.contract(address=address, abi=abi)
oracle = web3.eth.contract(address=web3.toChecksumAddress(oracleAddress), abi=oracle_abi)

contract.functions.setOracleInstanceAddress(oracleAddress)

balance = web3.eth.get_balance(account_1)
def get_balance(i):
    account = web3.eth.accounts[i-1];
    balance = web3.eth.get_balance(account)
    print('Account {} balance {}'.format(i, web3.fromWei(balance, 'ether')))

get_balance(1)

get_balance(2)

get_balance(3)

def place_bet(account, amount, bet):
    nonce = web3.eth.getTransactionCount(account)
    tx = {
        'from': account,
        'to': contract_address,
        'nonce': nonce,
        'value': web3.toWei(amount, 'ether'),
        'gas': 2000000,
        'gasPrice': web3.toWei('50', 'gwei'),
    }
    place_bet = contract.functions.placeBet(bet)
    tx_hash = place_bet.transact(tx)
    print ('Transaction hash {}'.format(web3.toHex(tx_hash)))
    web3.eth.waitForTransactionReceipt(tx_hash)
    
place_bet(account_2, 10, 1)   # User 1 Bet
place_bet(account_3, 10, 0)   # User 2 Bet

tx = {
    'from': account_3,
}
def handle_event(event):
    receipt = web3.eth.waitForTransactionReceipt(event['transactionHash'])
    result = contract.events.greeting.processReceipt(receipt)
    print(result[0]['args'])
    
def log_loop(event_filter, poll_interval):
    while True:
        for event in event_filter.get_new_entries():
            handle_event(event)
            time.sleep(poll_interval)

all_bets = contract.functions.getAllBets().call()
print('All bets {}'.format(all_bets))

user_bet = contract.functions.getBetForUser().call(tx)
print('User has placed bet on : {}'.format(user_bet))

bet_result = contract.functions.checkResult().call({})
print('Betting Result is : {}'.format(bet_result))

# event_filter = contract.events.ReceivedCheckResultEvent.createFilter(fromBlock=1)
# event_filter_2 = oracle.events.GetBetResultEvent.createFilter(fromBlock=1)

# while True:
#     print(event_filter.get_all_entries())
#     print(event_filter_2.get_all_entries())
#     time.sleep(2)



get_balance(1)

get_balance(2)

get_balance(3)