#!/usr/bin/env python3
from __future__ import annotations

import argparse
import copy
import re
import xml.etree.ElementTree as ET
from pathlib import Path


REFERENT_RE = re.compile(r"^-?\d+$")
WORKSPACE_NAME = 'Workspace'
STATIC_WORLD_NAME = 'MazeStaticWorld'
SCENERY_NAME = 'Scenery'
CHUNK_NAME = 'maze.3dm'
OVERLAY_PATH = Path('places/maze/assets/Overlays/MazeStaticWorldOverlay_Default.rbxmx')
CHUNK_PATH = Path('places/maze/assets/Chunks/MazeChunk_maze_v1.rbxmx')


def get_name(item: ET.Element) -> str | None:
    props = item.find('Properties')
    if props is None:
        return None
    for child in props:
        if child.get('name') == 'Name':
            return child.text or ''
    return None



def set_name(item: ET.Element, value: str) -> None:
    props = item.find('Properties')
    if props is None:
        props = ET.SubElement(item, 'Properties')

    for child in props:
        if child.get('name') == 'Name':
            child.text = value
            return

    name_prop = ET.Element('string', {'name': 'Name'})
    name_prop.text = value
    props.insert(0, name_prop)



def find_top_level_child(parent: ET.Element, name: str) -> tuple[int | None, ET.Element | None]:
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



def make_folder(name: str) -> ET.Element:
    item = ET.Element('Item', {'class': 'Folder'})
    props = ET.SubElement(item, 'Properties')
    name_prop = ET.SubElement(props, 'string', {'name': 'Name'})
    name_prop.text = name
    return item



def load_single_item(path: Path) -> ET.Element:
    tree = ET.parse(path)
    root = tree.getroot()
    items = root.findall('Item')
    if len(items) != 1:
        raise ValueError(f'{path} must contain exactly one top-level Item')
    return items[0]



def build_authored_static_world(repo_root: Path) -> ET.Element:
    overlay_root = load_single_item(repo_root / OVERLAY_PATH)
    chunk_root = load_single_item(repo_root / CHUNK_PATH)

    authored_root = make_folder(STATIC_WORLD_NAME)
    for child in overlay_root.findall('Item'):
        authored_root.append(copy.deepcopy(child))

    scenery_root = make_folder(SCENERY_NAME)
    chunk_clone = copy.deepcopy(chunk_root)
    set_name(chunk_clone, CHUNK_NAME)
    scenery_root.append(chunk_clone)
    authored_root.append(scenery_root)

    return authored_root



def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('harness_path')
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parents[1]
    harness_path = Path(args.harness_path).resolve()

    tree = ET.parse(harness_path)
    root = tree.getroot()

    _, workspace = find_top_level_child(root, WORKSPACE_NAME)
    if workspace is None:
        raise ValueError(f'{harness_path} is missing top-level Workspace')

    existing_index, existing_root = find_top_level_child(workspace, STATIC_WORLD_NAME)
    if existing_root is not None and existing_index is not None:
        workspace.remove(existing_root)

    used_referents = collect_referents(root)
    authored_root = build_authored_static_world(repo_root)
    remap_subtree_referents(authored_root, used_referents)
    workspace.append(authored_root)

    ET.indent(tree, space='  ')
    tree.write(harness_path, encoding='unicode', short_empty_elements=False)


if __name__ == '__main__':
    main()
