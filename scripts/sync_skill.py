#!/usr/bin/env python3
"""
Syncs vhdl_guideline.md to .agents/skills/vhdl-guideline/SKILL.md
by injecting the required YAML frontmatter.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE_MD = ROOT / "vhdl_guideline.md"
TARGET_SKILL = ROOT / ".agents" / "skills" / "vhdl-guideline" / "SKILL.md"

FRONTMATTER = """---
name: vhdl-guideline
description: >-
  Comprehensive VHDL hardware design rules, coding standards, synthesizable best practices,
  and architecture patterns. Activate this skill whenever writing, reviewing, refactoring,
  or debugging VHDL code, testbenches, or finite state machines (FSMs).
---

"""

def main():
    if not SOURCE_MD.exists():
        print(f"Error: {SOURCE_MD} not found.")
        return 1

    content = SOURCE_MD.read_text(encoding="utf-8").strip()
    TARGET_SKILL.parent.mkdir(parents=True, exist_ok=True)
    TARGET_SKILL.write_text(FRONTMATTER + content + "\n", encoding="utf-8")
    print(f"Successfully synced {SOURCE_MD.name} -> {TARGET_SKILL.relative_to(ROOT)}")
    return 0

if __name__ == "__main__":
    exit(main())
