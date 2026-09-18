# VHDL Coding Guideline & Agent Skill

A comprehensive standard, reference guide, and AI Agent Skill for robust, synthesizable VHDL design on FPGAs and ASICs.

[![Build and Release](https://github.com/monkey265/vhdl-guideline/actions/workflows/compile-pdf.yml/badge.svg)](https://github.com/monkey265/vhdl-guideline/actions/workflows/compile-pdf.yml)
[![Latest Release](https://img.shields.io/github/v/release/monkey265/vhdl-guideline?label=Release)](https://github.com/monkey265/vhdl-guideline/releases/latest)

---

## Documents

- **[PDF Reference](https://github.com/monkey265/vhdl-guideline/releases/latest/download/vhdl_guideline.pdf)**: Compiled publication-quality document with custom VHDL syntax highlighting.
- **[`vhdl_guideline.typ`](./vhdl_guideline.typ)**: Typst document source.
- **[`vhdl_guideline.md`](./vhdl_guideline.md)**: Markdown version.

---

## Using as an AI Skill (Gemini / Antigravity / Claude)

This repository includes preconfigured skill manifests for Gemini (Antigravity CLI) and Claude Code.

### 1. Workspace-Level (Current Project)
When cloning or including this repository in your workspace, the skill is automatically discovered by:
- **Gemini / Antigravity CLI**: `.agents/skills/vhdl-guideline/SKILL.md`
- **Claude Code**: `.claude/skills/vhdl-guideline/SKILL.md`
- **Rule enforcement**: `GEMINI.md` and `CLAUDE.md`

### 2. Global Installation (All Projects on your Machine)

#### For Gemini / Antigravity:
Copy the skill directory to your global Gemini config:
```bash
mkdir -p ~/.gemini/config/skills
cp -r .agents/skills/vhdl-guideline ~/.gemini/config/skills/
```

#### For Claude Code:
Copy the skill directory to your global Claude skills:
```bash
mkdir -p ~/.claude/skills
cp -r .claude/skills/vhdl-guideline ~/.claude/skills/
```

---

## Core Guidelines Summary

1. **Keywords & Types**: `ALL CAPS` (`ENTITY`, `PORT`, `PROCESS`, `STD_LOGIC`, `INTEGER`, etc.).
2. **Signal Naming**: `s_` prefix for signals, `v_` for variables, `g_` for generics.
3. **Ports**: Clock is port #1, reset is port #2 (active-low `rst_n_in` or `areset_n_in`).
4. **Processes**: Must have label with `_proc` suffix; sensitivity list is `(clk, areset_n)` for clocked processes, `(ALL)` for combinatorial.
5. **Latch Prevention**: All signals assigned in all branches (`IF/ELSE`, `CASE/WHEN OTHERS`).
6. **FSMs**: 1-process FSM preferred on FPGA; default assignments before `CASE`; look-ahead output registers.
7. **Arithmetic**: Strict `ieee.numeric_std` + `UNSIGNED`/`SIGNED` casting.
8. **Subprograms**: Pure functions for synthesizable datapath; impure functions reserved for ROM init via `TEXTIO` or testbenches; no `WAIT` in synthesizable procedures; normalize array parameters with `ALIAS`.
