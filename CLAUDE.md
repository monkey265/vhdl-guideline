# VHDL Design & Coding Guidelines (Claude Code Instructions)

When generating, editing, or reviewing VHDL code in this project, adhere strictly to these rules:

- **Keywords**: ALL CAPS (`ENTITY`, `PORT`, `SIGNAL`, `PROCESS`, `BEGIN`, `IF`, `THEN`, `CASE`, `WHEN`, `END`).
- **Standard Types**: ALL CAPS (`STD_LOGIC`, `STD_LOGIC_VECTOR`, `INTEGER`, `BOOLEAN`, `UNSIGNED`, `SIGNED`).
- **Naming Conventions**:
  - Signals: `s_<name>` (lowercase)
  - Variables: `v_<name>` (lowercase)
  - Generics: `g_<name>` (lowercase)
  - Processes: `<name>_proc` (lowercase label)
- **Port Order & Resets**:
  - Port 1: Clock (`clk_in`).
  - Port 2: Reset (`rst_n_in` synchronous active-low, or `areset_n_in` asynchronous active-low).
- **Process Sensitivity**:
  - Clocked: `PROCESS(clk_in, areset_n_in)` (only clk and async reset).
  - Combinatorial: `PROCESS(ALL)` with latch prevention (all signals assigned in all branches).
- **FSM & Counters**:
  - 1-process FSM preferred on FPGA for registered outputs.
  - Default assignments before `CASE` to prevent latches.
  - Avoid `rising_edge()` on data inputs.
  - Look-ahead exit conditions (`s_count = g_LIMIT - 1`).
  - Strict `ieee.numeric_std` usage (no `std_logic_unsigned`).

See `.claude/skills/vhdl-guideline/SKILL.md` for full reference and examples.
