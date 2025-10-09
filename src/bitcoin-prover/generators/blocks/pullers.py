import requests
from typing import Dict, List
import logging

class BlockHeaderPuller:
    """
    Pulls block headers from a Bitcoin Core RPC node in batches.
    """

    def __init__(self, rpc_config: Dict):
        self.url = f"{rpc_config['host']}:{rpc_config['port']}"
        self.auth = (rpc_config["user"], rpc_config["password"])
        self.session = requests.Session()
        logging.getLogger("urllib3").propagate = False

    def _rpc_batch(self, calls: List[Dict]) -> List:
        response = self.session.post(
            self.url,
            auth=self.auth,
            json=calls
        )
        response.raise_for_status()
        results = response.json()
        return [r["result"] for r in sorted(results, key=lambda x: x["id"])]

    def pull_block_headers(self, start: int, count: int, step: int = 2000) -> List[str]:
        logging.debug(f"Pulling {count} block headers starting from {start} with step {step}")
        headers = []

        for batch_start in range(start, start + count, step):
            batch_end = min(batch_start + step, start + count)
            heights = list(range(batch_start, batch_end))

            calls = [{"jsonrpc": "1.0", "id": i, "method": "getblockhash", "params": [h]}
                     for i, h in enumerate(heights)]
            block_hashes = self._rpc_batch(calls)

            calls = [{"jsonrpc": "1.0", "id": i, "method": "getblockheader", "params": [h, False]}
                     for i, h in enumerate(block_hashes)]
            batch_headers = self._rpc_batch(calls)

            headers.extend(batch_headers)
            logging.debug(f"Fetched {len(batch_headers)} headers ({batch_start}..{batch_end-1})")

        return headers
