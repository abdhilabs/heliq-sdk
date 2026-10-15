#
# generate_perps_signing_fixtures.py
# HeliqSDK tests
# Created by Abdhilabs on 15/10/26.
#
# Run with the official Python SDK at revision 2fdb18f9517675ea03695a0962bd19eece9c83f0.
# This fixed, publicly known test key must never be funded or used for live trading.
import base64
import copy
import json
from pathlib import Path

import msgpack
from eth_account import Account
from hyperliquid.utils import signing

wallet = Account.from_key('1' * 64)
nonce = 1700000000123
address = '0x1234567890123456789012345678901234567890'
token = 'USDC:0x00000000000000000000000000000001'
order = {'a': 0, 'b': True, 'p': '50000', 's': '0.001', 'r': False, 't': {'limit': {'tif': 'Gtc'}}}
l1 = {}
for tif in ['Gtc', 'Ioc', 'Alo']:
    item = copy.deepcopy(order)
    item['t']['limit']['tif'] = tif
    l1['order-' + tif] = {'type': 'order', 'orders': [item], 'grouping': 'na'}
for market in [True, False]:
    item = copy.deepcopy(order)
    item['t'] = {'trigger': {'isMarket': market, 'triggerPx': '49000', 'tpsl': 'sl'}}
    l1['trigger-' + str(market).lower()] = {'type': 'order', 'orders': [item], 'grouping': 'na'}
l1.update({
    'grouped': {'type': 'order', 'orders': [order], 'grouping': 'normalTpsl', 'builder': {'b': address, 'f': 0}},
    'modify': {'type': 'modify', 'oid': 42, 'order': order, 'a': True},
    'batchModify': {'type': 'batchModify', 'modifies': [{'oid': 42, 'order': order}]},
    'cancel': {'type': 'cancel', 'cancels': [{'a': 0, 'o': 42}]},
    'cancel-fast': {'type': 'cancel', 'cancels': [{'a': 0, 'o': 42}], 'f': True},
    'cancelByCloid': {'type': 'cancelByCloid', 'cancels': [{'asset': 0, 'cloid': '0x' + '1' * 32}]},
    'schedule-set': {'type': 'scheduleCancel', 'time': 1700000000123},
    'schedule-clear': {'type': 'scheduleCancel'},
    'leverage': {'type': 'updateLeverage', 'asset': 0, 'isCross': True, 'leverage': 2},
    'margin-add': {'type': 'updateIsolatedMargin', 'asset': 0, 'isBuy': True, 'ntli': 1000001},
    'margin-remove': {'type': 'updateIsolatedMargin', 'asset': 0, 'isBuy': True, 'ntli': -1000001},
    'isolated-leverage': {'type': 'topUpIsolatedOnlyMargin', 'asset': 0, 'leverage': '2'},
    'twap': {'type': 'twapOrder', 'twap': {'a': 0, 'b': True, 's': '0.001', 'r': False, 'm': 5, 't': False}},
    'twapCancel': {'type': 'twapCancel', 'a': 0, 't': 42},
    'trailing-percent': {'type': 'trailingStop', 'asset': 0, 'isBuy': True, 'sz': '0.001', 'reduceOnly': False, 'retracement': {'pct': '1%'}, 'activationPx': None},
    'trailing-price': {'type': 'trailingStop', 'asset': 0, 'isBuy': True, 'sz': '0.001', 'reduceOnly': False, 'retracement': {'px': '100'}, 'activationPx': '50000'},
    'agent-mode': {'type': 'agentSetAbstraction', 'abstraction': 'u'},
    'legacy-agent-mode': {'type': 'agentEnableDexAbstraction'},
    'subaccount-create': {'type': 'createSubAccount', 'name': 'fixture'},
    'subaccount-transfer': {'type': 'subAccountTransfer', 'subAccountUser': address, 'isDeposit': True, 'usd': 1000001},
    'subaccount-spot': {'type': 'subAccountSpotTransfer', 'subAccountUser': address, 'isDeposit': True, 'token': token, 'amount': '1.000001'},
    'reserve': {'type': 'reserveRequestWeight', 'weight': 1, 'destination': address},
    'noop': {'type': 'noop'},
    'vault': {'type': 'vaultTransfer', 'vaultAddress': address, 'isDeposit': True, 'usd': 1000001},
    'referrer': {'type': 'setReferrer', 'code': 'FIXTURE'},
    'agent-send': {'type': 'agentSendAsset', 'destination': address, 'sourceDex': 'spot', 'destinationDex': '', 'token': token, 'amount': '1.000001', 'fromSubAccount': '', 'nonce': nonce},
})
# Typed deployment schema variants; protocol tuple lists are sorted before hashing.
dep = {
    'registerAsset2': {'assetRequest': {'coin': 'xyz:ABC', 'szDecimals': 3, 'oraclePx': '100', 'marginTableId': 50, 'marginMode': 'normal'}, 'dex': 'xyz'},
    'registerAsset': {'assetRequest': {'coin': 'xyz:ABC', 'szDecimals': 3, 'oraclePx': '100', 'marginTableId': 50, 'onlyIsolated': False}, 'dex': 'xyz'},
    'setOracle': {'dex': 'xyz', 'oraclePxs': [['xyz:A', '100'], ['xyz:Z', '101']], 'markPxs': [[['xyz:A', '100']]], 'externalPerpPxs': [['xyz:A', '100']]},
    'setFundingMultipliers': [['xyz:A', '1']],
    'setFundingInterestRates': [['xyz:A', '-0.001']],
    'setFundingClamps': [['xyz:A', '0.0003']],
    'haltTrading': {'coin': 'xyz:ABC', 'isHalted': True},
    'insertMarginTable': {'dex': 'xyz', 'marginTable': {'description': '', 'marginTiers': [{'lowerBound': 0, 'maxLeverage': 50}, {'lowerBound': 1000000, 'maxLeverage': 10}]}},
    'setMarginTableIds': [['xyz:A', 50]],
    'setFeeRecipient': {'dex': 'xyz', 'feeRecipient': address},
    'setOpenInterestCaps': [['xyz:A', 1000000], ['xyz:Z', None]],
    'setSubDeployers': {'dex': 'xyz', 'subDeployers': [{'variant': 'setOracle', 'user': address, 'allowed': True}]},
    'setMarginModes': [['xyz:A', 'strictIsolated']],
    'setDeployerFees': [['xyz:A', {'scale': '1', 'growthMode': True}]],
    'setPerpAnnotation': {'coin': 'xyz:ABC', 'category': 'other', 'description': 'fixture', 'displayName': None, 'keywords': []},
    'disableDex': 'xyz',
}
for variant, payload in dep.items():
    l1['deploy-' + variant] = {'type': 'perpDeploy', variant: payload}

vectors = []
for name, action in l1.items():
    for mainnet in [False, True]:
        signature = signing.sign_l1_action(wallet, action, None, nonce, None, mainnet)
        vectors.append({'name': name, 'kind': 'l1', 'mainnet': mainnet,
                        'msgpack': base64.b64encode(msgpack.packb(action)).decode(),
                        'hash': signing.action_hash(action, None, nonce, None).hex(), **signature})
# Include contextual hashing and the array payload used by multisig signers.
for name, action, vault, expiry in [
    ('context', l1['order-Gtc'], address, nonce + 60000),
    ('multisig-l1', [address, wallet.address.lower(), l1['order-Gtc']], None, None),
]:
    signature = signing.sign_l1_action(wallet, action, vault, nonce, expiry, False)
    vectors.append({'name': name, 'kind': 'l1', 'mainnet': False,
                    'msgpack': base64.b64encode(msgpack.packb(action)).decode(),
                    'hash': signing.action_hash(action, vault, nonce, expiry).hex(), **signature})

users = [
    ('class-transfer', {'type': 'usdClassTransfer', 'amount': '1.000001', 'toPerp': True, 'nonce': nonce}, signing.USD_CLASS_TRANSFER_SIGN_TYPES, 'UsdClassTransfer'),
    ('send-asset', {'type': 'sendAsset', 'destination': address, 'sourceDex': 'spot', 'destinationDex': '', 'token': token, 'amount': '1.000001', 'fromSubAccount': '', 'nonce': nonce}, signing.SEND_ASSET_SIGN_TYPES, 'SendAsset'),
    ('user-mode', {'type': 'userSetAbstraction', 'user': address, 'abstraction': 'disabled', 'nonce': nonce}, signing.USER_SET_ABSTRACTION_SIGN_TYPES, 'UserSetAbstraction'),
    ('legacy-user-mode', {'type': 'userDexAbstraction', 'user': address, 'enabled': True, 'nonce': nonce}, signing.USER_DEX_ABSTRACTION_SIGN_TYPES, 'UserDexAbstraction'),
    ('withdraw', {'type': 'withdraw3', 'destination': address, 'amount': '1.000001', 'time': nonce}, signing.WITHDRAW_SIGN_TYPES, 'Withdraw'),
    ('convert', {'type': 'convertToMultiSigUser', 'signers': json.dumps({'authorizedUsers': [address], 'threshold': 1}, sort_keys=True, separators=(',', ':')), 'nonce': nonce}, signing.CONVERT_TO_MULTI_SIG_USER_SIGN_TYPES, 'ConvertToMultiSigUser'),
    # Newer documented schema, encoded with the official generic EIP-712 signer.
    ('liquidator-transfer', {'type': 'hip3LiquidatorTransfer', 'dex': 'xyz', 'ntl': 1000000000, 'isDeposit': True, 'nonce': nonce}, [{'name': 'hyperliquidChain', 'type': 'string'}, {'name': 'dex', 'type': 'string'}, {'name': 'ntl', 'type': 'uint64'}, {'name': 'isDeposit', 'type': 'bool'}, {'name': 'nonce', 'type': 'uint64'}], 'Hip3LiquidatorTransfer'),
    ('restore', {'type': 'convertToMultiSigUser', 'signers': 'null', 'nonce': nonce}, signing.CONVERT_TO_MULTI_SIG_USER_SIGN_TYPES, 'ConvertToMultiSigUser'),
]
for name, action, fields, primary in users:
    for mainnet in [False, True]:
        signature = signing.sign_user_signed_action(wallet, copy.deepcopy(action), fields,
                                                   'HyperliquidTransaction:' + primary, mainnet)
        vectors.append({'name': name, 'kind': 'user', 'mainnet': mainnet, **signature})
# Official helpers own the schemas for these approvals.
for name, action, function in [
    ('agent-approval', {'type': 'approveAgent', 'agentAddress': address, 'agentName': 'fixture', 'nonce': nonce}, signing.sign_agent),
    ('builder-approval', {'type': 'approveBuilderFee', 'maxFeeRate': '0%', 'builder': address, 'nonce': nonce}, signing.sign_approve_builder_fee),
]:
    for mainnet in [False, True]:
        signature = function(wallet, copy.deepcopy(action), mainnet)
        vectors.append({'name': name, 'kind': 'user', 'mainnet': mainnet, **signature})
Path('Tests/HeliqSDKTests/Fixtures/Perps/signing-vectors.json').write_text(json.dumps(vectors, indent=2) + '\n')
print(f'Generated {len(vectors)} independent signing vectors')
