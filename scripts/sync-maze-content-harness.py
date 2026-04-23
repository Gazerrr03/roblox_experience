#!/usr/bin/env python3
from __future__ import annotations

import argparse
import copy
import re
import xml.etree.ElementTree as ET
from pathlib import Path


REFERENT_RE = re.compile(r"^-?\d+$")
TOP_LEVEL_PRESERVE_NAMES = ("Workspace", "Lighting")


def get_name(item: ET.Element) -> str | None:
    props = item.find('Properties')
    if props is None:
        return None
    for child in props:
        if child.get('name') == 'Name':
            return child.text or ''
    return None


def find_top_level_child(parent: ET.Element, name: str) -> tuple[int, ET.Element] | tuple[None, None]:
    for index, child in enumerate(list(parent)):
        if get_name(child) == name:
            return index, child
    return None, None


def collect_referents(element: ET.Element) -> set[str]:
    referents: set[str] = set()
    for node in element.iter():
        referent = node.get('referent')
        if referent:
            referents.add(referent)
        if node.tag == 'Ref' and node.text:
            referents.add(node.text)
    return referents


def next_referent(used: set[str]) -> str:
    numeric = [int(value) for value in used if REFERENT_RE.match(value)]
    candidate = max(numeric, default=0) + 1
    while str(candidate) in used:
        candidate += 1
    return str(candidate)


def remap_subtree_referents(element: ET.Element, used: set[str]) -> None:
    mapping: dict[str, str] = {}

    for node in element.iter():
        referent = node.get('referent')
        if referent:
            replacement = next_referent(used)
            used.add(replacement)
            mapping[referent] = replacement
            node.set('referent', replacement)

    for node in element.iter('Ref'):
        if node.text in mapping:
            node.text = mapping[node.text]



def load_tree(path: Path) -> ET.ElementTree:
    return ET.parse(path)



def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('--authored', required=True)
    parser.add_argument('--scaffold', required=True)
    parser.add_argument('--output', required=True)
    args = parser.parse_args()

    authored_path = Path(args.authored)
    scaffold_path = Path(args.scaffold)
    output_path = Path(args.output)

    authored_tree = load_tree(authored_path)
    scaffold_tree = load_tree(scaffold_path)

    authored_root = authored_tree.getroot()
    scaffold_root = scaffold_tree.getroot()

    authored_top = authored_root
    scaffold_top = scaffold_root

    used_referents = collect_referents(scaffold_top)

    for name in TOP_LEVEL_PRESERVE_NAMES:
        _, authored_item = find_top_level_child(authored_top, name)
        scaffold_index, scaffold_item = find_top_level_child(scaffold_top, name)
        if authored_item is None or scaffold_item is None or scaffold_index is None:
            continue

        replacement = copy.deepcopy(authored_item)
        remap_subtree_referents(replacement, used_referents)
        scaffold_top.remove(scaffold_item)
        scaffold_top.insert(scaffold_index, replacement)

    ET.indent(scaffold_tree, space='  ')
    scaffold_tree.write(output_path, encoding='unicode', short_empty_elements=False)


if __name__ == '__main__':
    main()
