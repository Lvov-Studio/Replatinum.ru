"""Refresh app navigation labels from the site's public catalog menu (read-only)."""
import html
from datetime import date
import json
import re
import sys
from pathlib import Path
from urllib.request import urlopen

source = Path(sys.argv[1]).read_text(encoding='utf-8') if len(sys.argv) > 1 else urlopen('https://replatinum.ru/catalog/', timeout=30).read().decode('utf-8')
tree = {}
for block in re.findall(r'<div class="sub-col">(.*?)</ul>', source, re.S):
    parent = re.search(r'<h4[^>]*>\s*<a[^>]*href="([^"]+)"[^>]*>(.*?)</a>', block, re.S)
    if not parent:
        continue
    path, title = parent.groups()
    parts = path.strip('/').split('/')
    if len(parts) != 3 or parts[0] != 'catalog':
        continue
    clean = lambda s: html.unescape(re.sub('<[^>]+>', '', s)).strip()
    children = []
    for link, label in re.findall(r'<li>\s*<a[^>]*href="([^"]+)"[^>]*>(.*?)</a>', block, re.S):
        if link.startswith(path) and link != path:
            children.append((link, clean(label)))
    tree.setdefault(parts[1], {})[path] = (clean(title), list(dict.fromkeys(children)))
quote = lambda s: json.dumps(s, ensure_ascii=False).replace('$', r'\$')
lines = [f"// Generated from https://replatinum.ru/catalog/ on {date.today().isoformat()}.", "// Refresh: python tools/update_catalog_navigation.py", "class CatalogNode {", "  final String path, title;", "  final List<CatalogNode> children;", "  const CatalogNode(this.path, this.title, [this.children = const []]);", "}", "const catalogNavigation = <String, List<CatalogNode>>{"]
for root, nodes in tree.items():
    lines.append(f'  {quote(root)}: [')
    for path, (title, children) in nodes.items():
        lines.append(f'    CatalogNode({quote(path)}, {quote(title)}, [')
        lines.extend(f'      CatalogNode({quote(link)}, {quote(label)}),' for link, label in children)
        lines.append('    ]),')
    lines.append('  ],')
lines.append('};')
Path('lib/data/catalog_navigation.dart').write_text('\n'.join(lines)+'\n', encoding='utf-8')
print(f'{len(tree)} roots, {sum(len(nodes) for nodes in tree.values())} groups')
