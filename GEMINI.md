# VHDL Design & Coding Guidelines

This project enforces strict synthesizable VHDL coding practices. When writing or modifying VHDL files in this repository:

1. **Keywords**: MUST be in ALL CAPS (`ENTITY`, `PORT`, `SIGNAL`, `PROCESS`, `BEGIN`, `END`, etc.).
2. **Standard Types**: MUST be in ALL CAPS (`STD_LOGIC`, `STD_LOGIC_VECTOR`, `INTEGER`, `UNSIGNED`, etc.).
3. **Identifiers**:
   - Entities, procedures, and functions: lowercase.
   - Signals: lowercase with `s_` prefix (`s_clk`, `s_valid`).
   - Variables: lowercase with `v_` prefix (`v_index`).
   - Generics: lowercase with `g_` prefix (`g_width`).
4. **Ports & Clocking**:
   - Port 1 is always clock (`clk_in`).
   - Port 2 is always reset (active-low, e.g. `rst_n_in` synchronous or `areset_n_in` asynchronous).
5. **Processes**:
   - MUST be labeled with `_proc` suffix (e.g. `reg_proc: PROCESS(...)`).
   - Clocked processes: sensitivity list MUST only contain clock and asynchronous reset.
   - Combinatorial processes: MUST use `PROCESS(ALL)`.
   - Latch prevention: every assigned signal must receive a value in all conditional branches (`IF/ELSE`, `CASE/WHEN OTHERS`).
6. **FSMs**:
   - Never use `rising_edge()` on data inputs.
   - Use default assignments at the top of the process before `CASE` statements.
   - Use `numeric_std` and `UNSIGNED` for vector math. Never use `std_logic_unsigned`.

For complete reference and details, consult the skill at `.agents/skills/vhdl-guideline/SKILL.md` or [`vhdl_guideline.typ`](./vhdl_guideline.typ).
