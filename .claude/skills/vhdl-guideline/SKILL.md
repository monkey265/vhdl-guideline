---
name: vhdl-guideline
description: >-
  Comprehensive VHDL hardware design rules, coding standards, synthesizable best practices,
  and architecture patterns. Activate this skill whenever writing, reviewing, refactoring,
  or debugging VHDL code, testbenches, or finite state machines (FSMs).
---

# VHDL Hardware Design & Coding Guideline Skill

This skill guides the design, implementation, and review of robust, synthesizable VHDL code for FPGAs and ASICs.

---

## 1. Core Language & Naming Rules

| Element | Rule | Example / Note |
| :--- | :--- | :--- |
| **Keywords** | **MUST** be in **ALL CAPS** | `ENTITY`, `ARCHITECTURE`, `PORT`, `SIGNAL`, `PROCESS`, `BEGIN`, `END` |
| **Standard Items** | **MUST** be in **ALL CAPS** | `STD_LOGIC`, `STD_LOGIC_VECTOR`, `INTEGER`, `BOOLEAN`, `UNSIGNED`, `SIGNED` |
| **Entities** | **SHOULD** be `lowercase` | `entity counter is`, `entity uart_tx is` |
| **Signals** | **MUST** be `lowercase`, **SHOULD** have prefix `s_` | `signal s_data_ready : STD_LOGIC;` |
| **Variables** | **MUST** be `lowercase`, **SHOULD** have prefix `v_` | `variable v_temp_sum : INTEGER;` |
| **Generics** | **SHOULD** have prefix `g_` | `generic ( g_data_width : INTEGER := 8 );` |
| **User Types & Subprograms** | **CAN** be `lowercase` | `type t_state is (...)`, `procedure calculate_crc(...)` |
| **User Library Names** | **MUST NOT** be named `work` | Use custom library names; `work` is reserved for current compilation unit |
| **Block Labels** | **SHOULD** name all `IF`, `FOR`, `WHILE`, `PROCESS` | `check_valid_if: IF ...`, `main_proc: PROCESS(...)` |

---

## 2. Ports, Clocking & Resets

### Port List Ordering & Grouping
1. **Clock** is always the first port: `clk_in : IN STD_LOGIC;`
2. **Reset** is always the second port: `rst_n_in` or `areset_n_in`.
3. Separate inputs, outputs, and debug signals using category comments.

### Reset Standards
- Resets **SHOULD** be active low (`_n` suffix).
- Explicitly denote synchronicity in signal names:
  - `areset_n` / `arst_n`: **Asynchronous** reset, active low.
  - `rst_n`: **Synchronous** reset, active low.

```vhdl
PORT (
    -- Inputs
    clk_in      : IN STD_LOGIC;
    rst_n_in    : IN STD_LOGIC; -- Synchronous reset, active low
    areset_n_in : IN STD_LOGIC; -- Asynchronous reset, active low
    s_data_in   : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    -- Outputs
    s_data_out  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
);
```

---

## 3. Processes & Latch Prevention

### Process Labeling
Every process **MUST** have a label with suffix `_proc`:
```vhdl
reg_proc: PROCESS(clk_in, areset_n_in)
BEGIN
    reset_if: IF areset_n_in = '0' THEN
        s_reg <= (OTHERS => '0');
    ELSIF rising_edge(clk_in) THEN
        s_reg <= s_next_reg;
    END IF reset_if;
END PROCESS reg_proc;
```

### Sensitivity Lists
- **Clocked / Sequential Processes**: Sensitivity list **MUST** contain *only* clock and asynchronous reset (e.g. `PROCESS(clk_in, areset_n_in)`). Never include synchronous reset or data signals.
- **Combinatorial Processes**: **MUST** use `PROCESS(ALL)`. In VHDL-93, list every read signal.

### Pure Combinational Logic & Latch Prevention
To prevent accidental latch inference:
- Every signal assigned in a combinatorial process **MUST** be assigned in **all** possible conditional branches.
- Every `IF` needs an `ELSE`.
- Every `CASE` needs a `WHEN OTHERS`.

---

## 4. Finite State Machines (FSMs)

### Architecture Patterns
- **One-Process FSM (Recommended on FPGA)**: Registers outputs automatically, resulting in optimal timing closure ($F_{max}$).
- **Two-Process FSM**: Separates next-state combinational logic from state registers.

### Critical FSM Rules
1. **Never use `rising_edge()` on data/control signals** to trigger state transitions. Use a 1-clock-cycle pulse detector if edge sensing is needed.
2. **Transition Conditions**: When specifying state transitions with `IF`, omit `ELSE` if the else-action is just remaining in the current state.
3. **The "Default Assignment" Pattern**: Assign default signal/output values at the top of the process before the `CASE` statement.

```vhdl
fsm_proc: PROCESS(clk_in)
BEGIN
    IF rising_edge(clk_in) THEN
        -- Default assignments (prevents latches, clean code)
        s_output_valid <= '0';
        s_busy         <= '1';

        CASE s_state IS
            WHEN ST_IDLE =>
                s_busy <= '0';
                IF s_start = '1' THEN
                    s_state <= ST_RUN;
                END IF;
            
            WHEN ST_RUN =>
                s_output_valid <= '1';
                IF s_done = '1' THEN
                    s_state <= ST_IDLE;
                END IF;

            WHEN OTHERS =>
                s_state <= ST_IDLE;
        END CASE;
    END IF;
END PROCESS fsm_proc;
```

### Safe FSM Synthesis Attributes
Protect against single-event upsets (SEUs) and illegal states:
```vhdl
TYPE t_state IS (ST_IDLE, ST_READ, ST_WRITE);
SIGNAL s_state : t_state;

ATTRIBUTE fsm_safe_state : STRING;
ATTRIBUTE fsm_safe_state OF s_state : SIGNAL IS "default_state";
```

### Look-Ahead Outputs
To eliminate combinatorial output delay, compute the output based on the *next* state within the same cycle:
```vhdl
CASE s_state IS
    WHEN ST_IDLE =>
        IF s_start = '1' THEN
            s_state      <= ST_RUN;
            s_output_reg <= '1'; -- Look-ahead
        END IF;
END CASE;
```

---

## 5. Counter & Arithmetic Guidelines

1. **Look-Ahead Exit Condition**: Compare against `g_LIMIT - 1` to eliminate 1-cycle latency in sequential state transitions:
   ```vhdl
   IF s_count = g_LIMIT - 1 THEN
       s_count <= 0;
       s_state <= ST_NEXT;
   ELSE
       s_count <= s_count + 1;
   END IF;
   ```
2. **Standard Arithmetic**: Always use `ieee.numeric_std` and cast vectors to `UNSIGNED` or `SIGNED`. **Never** use `std_logic_unsigned` or `std_logic_arith`.
3. **Bounded Ranges**: Declare integer counters with bounded ranges (`INTEGER RANGE 0 TO 15`) and assign a reset in `WHEN OTHERS` to avoid synthesizer overflows.
4. **Shared Counter Pattern**: Use a single counter signal reset on transitions across multiple counting states to minimize FPGA LUT usage.

---

## 6. Language Reference Quick Table

| Feature | Syntax / Example | Synthesizable? |
| :--- | :--- | :---: |
| **Type Base** | `T'Base` | Yes |
| **Bounds** | `T'Left`, `T'Right`, `T'Low`, `T'High` | Yes |
| **Array Range** | `A'Range(n)`, `A'Length(n)` | Yes |
| **Signal Event** | `rising_edge(clk)` (preferred over `clk'event and clk='1'`) | Yes |
| **Hierarchy Path** | `E'Path_name`, `E'Instance_name` | No (Sim only) |
| **Simulation Postpone** | `POSTPONED PROCESS(...)` | No (Sim only) |
| **Delay Modeling** | `s_out <= TRANSPORT s_in AFTER 5 ns;` | No (Sim only) |
| **Delta Cycle Step** | `WAIT FOR 0 NS;` | No (Sim only) |
| **Signal Override** | `s_sig <= FORCE '1';` / `s_sig <= RELEASE;` | No (Sim only) |
| **External Name** | `<<SIGNAL .top.u1.s_internal : STD_LOGIC>>` | No (Sim only) |
| **Stop Simulation** | `USE std.env.finish; finish;` | No (Sim only) |
| **Alias** | `ALIAS a_byte : STD_LOGIC_VECTOR(7 DOWNTO 0) IS s_bus(15 DOWNTO 8);` | Yes |
