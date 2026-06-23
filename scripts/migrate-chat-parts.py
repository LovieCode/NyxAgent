#!/usr/bin/env python3
"""
临时测试环境迁移脚本：旧 messages.extra → 新 message parts。

用法：
  python scripts/migrate-chat-parts.py path/to/agent_chat.db

行为：
- 原地更新 SQLite messages.extra，把 content/thinking/blocks/msgType/imageUrl/tool_calls 转为 extra.message。
- 自动创建同目录 .bak 备份。
- 只用于未发布正式版前的测试数据转换；迁移后 APP 运行时不再做历史兼容。
"""
from __future__ import annotations

import json
import shutil
import sqlite3
import sys
from pathlib import Path
from typing import Any


def as_list(value: Any) -> list[dict[str, Any]]:
    return value if isinstance(value, list) else []


def as_dict(value: Any) -> dict[str, Any]:
    return value if isinstance(value, dict) else {}


def read_extra(raw: str) -> dict[str, Any]:
    try:
        value = json.loads(raw or '{}')
        return value if isinstance(value, dict) else {}
    except Exception:
        return {}


def text_part(text: str) -> dict[str, Any]:
    return {'type': 'plain', 'text': text}


def think_part(text: str) -> dict[str, Any]:
    return {'type': 'think', 'think': text}


def tool_item_from_old(block: dict[str, Any]) -> dict[str, Any]:
    name = str(block.get('name') or '')
    args = str(block.get('arguments') or block.get('args') or '{}')
    return {
        'id': str(block.get('id') or block.get('tool_call_id') or ''),
        'name': name,
        'arguments': args,
        'args': args,
        'ts': int(block.get('ts') or 0),
        'finished_ts': int(block.get('finished_ts') or 0),
        'status': str(block.get('status') or 'pending'),
        'result': str(block.get('result') or ''),
        'isError': bool(block.get('isError') or False),
    }


def tool_items_from_tool_calls(tool_calls: list[dict[str, Any]]) -> list[dict[str, Any]]:
    items: list[dict[str, Any]] = []
    for call in tool_calls:
        fn = as_dict(call.get('function'))
        name = str(fn.get('name') or call.get('name') or '')
        if not name:
            continue
        args = str(fn.get('arguments') or call.get('arguments') or call.get('args') or '{}')
        items.append({
            'id': str(call.get('id') or ''),
            'name': name,
            'arguments': args,
            'args': args,
            'ts': 0,
            'status': 'pending',
            'result': '',
            'isError': False,
        })
    return items


def convert_message(role: str, content: str, extra: dict[str, Any]) -> list[dict[str, Any]]:
    if isinstance(extra.get('message'), list):
        return as_list(extra['message'])

    parts: list[dict[str, Any]] = []
    blocks = as_list(extra.get('blocks'))
    for block in blocks:
        btype = str(block.get('type') or '')
        if btype == 'text':
            text = str(block.get('text') or '')
            if text:
                parts.append(text_part(text))
        elif btype == 'thinking':
            thinking = str(block.get('thinking') or block.get('think') or '')
            if thinking:
                parts.append(think_part(thinking))
        elif btype == 'toolCall':
            item = tool_item_from_old(block)
            if item['name']:
                parts.append({'type': 'tool_call', 'tool_calls': [item]})

    if not parts:
        thinking = str(extra.get('thinking') or '')
        if thinking:
            parts.append(think_part(thinking))

    if not parts:
        msg_type = str(extra.get('msgType') or 'text')
        image_url = str(extra.get('imageUrl') or '')
        if msg_type == 'image' and image_url:
            parts.append({'type': 'image', 'url': image_url, 'path': image_url})
        elif msg_type == 'file':
            parts.append({'type': 'file', 'filename': content.replace('[文件]', '').strip(), 'path': image_url})
        elif msg_type == 'voice':
            parts.append({'type': 'record', 'url': image_url, 'path': image_url})
        elif msg_type == 'location':
            parts.append({'type': 'location', 'text': content})
        elif content:
            parts.append(text_part(content))

    old_tool_calls = tool_items_from_tool_calls(as_list(extra.get('tool_calls')))
    if old_tool_calls and not any(part.get('type') == 'tool_call' for part in parts):
        parts.append({'type': 'tool_call', 'tool_calls': old_tool_calls})

    if role == 'toolResult' and content:
        parts.append(text_part(content))

    return parts


def migrate(db_path: Path) -> None:
    if not db_path.exists():
        raise SystemExit(f'DB 不存在：{db_path}')
    backup = db_path.with_suffix(db_path.suffix + '.bak')
    if not backup.exists():
        shutil.copy2(db_path, backup)
        print(f'已创建备份：{backup}')
    con = sqlite3.connect(str(db_path))
    cur = con.cursor()
    rows = cur.execute('SELECT id, role, content, extra FROM messages ORDER BY id ASC').fetchall()
    changed = 0
    for row_id, role, content, extra_raw in rows:
        extra = read_extra(extra_raw)
        parts = convert_message(str(role or ''), str(content or ''), extra)
        extra = {
            'message': parts,
            **({'isStreaming': extra['isStreaming']} if 'isStreaming' in extra else {}),
            **({'isError': extra['isError']} if 'isError' in extra else {}),
            **({'tool_call_id': extra['tool_call_id']} if 'tool_call_id' in extra else {}),
            **({'toolCallId': extra['toolCallId']} if 'toolCallId' in extra else {}),
            **({'toolName': extra['toolName']} if 'toolName' in extra else {}),
        }
        cur.execute('UPDATE messages SET extra = ? WHERE id = ?', (json.dumps(extra, ensure_ascii=False), row_id))
        changed += 1
    con.commit()
    con.close()
    print(f'迁移完成：{changed} 条消息')


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit('用法：python scripts/migrate-chat-parts.py path/to/agent_chat.db')
    migrate(Path(sys.argv[1]))


if __name__ == '__main__':
    main()
