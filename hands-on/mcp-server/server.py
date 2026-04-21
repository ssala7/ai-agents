"""
Custom MCP Server — exposes two tools:
  1. get_system_info  → returns OS, time, disk usage
  2. word_count       → counts words/lines/chars in text

Run: python server.py
Kiro connects to this via stdio.
"""
import json
import sys
import platform
import shutil
from datetime import datetime


def handle_request(req):
    method = req.get("method")
    id_ = req.get("id")

    if method == "initialize":
        return {"jsonrpc": "2.0", "id": id_, "result": {
            "protocolVersion": "2024-11-05",
            "capabilities": {"tools": {"listChanged": False}},
            "serverInfo": {"name": "demo-tools", "version": "1.0.0"}
        }}

    if method == "notifications/initialized":
        return None  # no response needed

    if method == "tools/list":
        return {"jsonrpc": "2.0", "id": id_, "result": {"tools": [
            {
                "name": "get_system_info",
                "description": "Returns current system info: OS, time, disk usage",
                "inputSchema": {"type": "object", "properties": {}}
            },
            {
                "name": "word_count",
                "description": "Counts words, lines, and characters in the given text",
                "inputSchema": {
                    "type": "object",
                    "properties": {"text": {"type": "string", "description": "Text to analyze"}},
                    "required": ["text"]
                }
            }
        ]}}

    if method == "tools/call":
        name = req["params"]["name"]
        args = req["params"].get("arguments", {})

        if name == "get_system_info":
            disk = shutil.disk_usage("/")
            result = (
                f"OS: {platform.system()} {platform.release()}\n"
                f"Time: {datetime.now().isoformat()}\n"
                f"Disk: {disk.free // (1024**3)}GB free / {disk.total // (1024**3)}GB total"
            )
        elif name == "word_count":
            text = args.get("text", "")
            result = f"Words: {len(text.split())}\nLines: {len(text.splitlines())}\nChars: {len(text)}"
        else:
            return {"jsonrpc": "2.0", "id": id_, "error": {"code": -32601, "message": f"Unknown tool: {name}"}}

        return {"jsonrpc": "2.0", "id": id_, "result": {
            "content": [{"type": "text", "text": result}]
        }}

    return {"jsonrpc": "2.0", "id": id_, "error": {"code": -32601, "message": f"Unknown method: {method}"}}


def main():
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            req = json.loads(line)
            resp = handle_request(req)
            if resp:
                sys.stdout.write(json.dumps(resp) + "\n")
                sys.stdout.flush()
        except Exception as e:
            err = {"jsonrpc": "2.0", "id": None, "error": {"code": -32603, "message": str(e)}}
            sys.stdout.write(json.dumps(err) + "\n")
            sys.stdout.flush()


if __name__ == "__main__":
    main()
