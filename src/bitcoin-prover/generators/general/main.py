import json
import requests
import sys
import subprocess

from typing import Dict
from generators.utils.tx import Transaction
from enum import Enum


class SpendType(Enum):
    P2PK = 0
    P2PKH = 1  # And p2wpkh
    P2MS = 2
    P2SH = 3  # And p2wsh
    P2SH_P2WPKH = 4
    P2SH_P2WSH = 5
    P2TR_KEY = 6
    P2TR_SCRIPT = 7


def get_config(path: str = "./generators/general/config.json") -> Dict:
    with open(path, "r") as f:
        return json.load(f)


def main():
    config = get_config()

    currentTx = Transaction(config["tx"])
    input_to_sign = config["input_to_sign"]

    prevTxid = currentTx.inputs[input_to_sign].txid[::-1].hex()
    vout = currentTx.inputs[input_to_sign].vout

    response = requests.get(f"https://blockstream.info/api/tx/{prevTxid}/hex")

    if response.status_code == 200:
        prevTx = Transaction(response.text)
    else:
        print(f"Error: {response.status_code}")
        sys.exit()

    script_pub_key = prevTx.outputs[vout].script_pub_key

    # Define spending type
    if len(script_pub_key) in (35, 67) and script_pub_key[-1] == 172:
        spend_type = SpendType.P2PK
    elif (len(script_pub_key) == 25 and script_pub_key[-1] == 172) or (len(script_pub_key) == 22 and script_pub_key[0] == 0):
        spend_type = SpendType.P2PKH
    elif script_pub_key[-1] == 174:
        spend_type = SpendType.P2MS
    elif len(script_pub_key) == 23 and script_pub_key[-1] == 135:
        script_sig = currentTx.inputs[input_to_sign].script_sig
        if currentTx.witness is None:
            spend_type = SpendType.P2SH
        elif len(script_sig) == 23 and script_sig[1] == 0:
            spend_type = SpendType.P2SH_P2WPKH
        elif len(script_sig) == 35 and script_sig[1] == 0:
            spend_type = SpendType.P2SH_P2WSH
        else:
            print(f"Error: spending type looks like p2sh but something is wrong!")
            sys.exit()
    elif len(script_pub_key) == 34 and script_pub_key[0] == 0:
        spend_type = SpendType.P2SH
    elif len(script_pub_key) == 34 and script_pub_key[0] == 81:
        if len(currentTx.witness[input_to_sign].stack_items) == 1:
            spend_type = SpendType.P2TR_KEY
        else:
            spend_type = SpendType.P2TR_SCRIPT
    else:
        print("Error: unknown spending type!")
        sys.exit()

    # Determine if json has all the necessary data
    match spend_type:
        case SpendType.P2PK:
            json_name = "np2tr.template"
            path = "p2pk"
        case SpendType.P2PKH:
            json_name = "np2tr.template"
            path = "p2pkh"
        case SpendType.P2MS:
            json_name = "np2tr.template"
            path = "p2ms"
        case SpendType.P2SH | SpendType.P2SH_P2WPKH | SpendType.P2SH_P2WSH:
            json_name = "np2tr.template"
            match spend_type:
                case SpendType.P2SH:
                    path = "p2sh"
                case SpendType.P2SH_P2WPKH:
                    path = "p2sh_p2wpkh"
                case SpendType.P2SH_P2WSH:
                    path = "p2sh_p2wsh"
        case SpendType.P2TR_KEY | SpendType.P2TR_SCRIPT:
            json_name = "p2tr.template"
            match spend_type:
                case SpendType.P2TR_KEY:
                    path = "p2tr"
                case SpendType.P2TR_SCRIPT:
                    path = "p2tr_script"

    with open("generators/general/jsons_templates/" + json_name, "r") as file:
        templateJson = file.read()

    jsonFile = templateJson.format(
        type=path,
        scriptSig=config["script_sig"],
        currentTx=config["tx"],
        prevTx=response.text,
        inputToSign=input_to_sign,
    )

    with open("generators/" + path + "/config.json", "w") as file:
        file.write(jsonFile)

    subprocess.run(["bash", "scripts/" + path + ".sh"])


if __name__ == "__main__":
    main()
