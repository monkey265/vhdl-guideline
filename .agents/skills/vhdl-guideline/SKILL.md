---
name: vhdl-guideline
description: >-
  Comprehensive VHDL hardware design rules, coding standards, synthesizable best practices,
  and architecture patterns. Activate this skill whenever writing, reviewing, refactoring,
  or debugging VHDL code, testbenches, or finite state machines (FSMs).
---

# Basics & Coding Standards

## Rule Terminology & Severity Levels
- **Must**: Non-negotiable requirement.
- **Should** and **Permitted**: Recommended best practice.
- **Tip**: Suggested optimization or pattern.

## Naming & Style Rules
- **Entity names** should be in `lowercase`.
- **Keywords** **must** be in **ALL CAPS** (`ENTITY`, `PORT`, `SIGNAL`, `PROCESS`, `BEGIN`, `END`, etc.).
- **Standard datatypes** **must** be in **ALL CAPS** (`STD_LOGIC`, `STD_LOGIC_VECTOR`, `INTEGER`, `UNSIGNED`, `SIGNED`, `BOOLEAN`).
- Write custom **functions and procedures** in `lowercase`.
- **Signals and variables** **must** be `lowercase`.
- **Signals** should have prefix `s_`.
- **Variables** should have prefix `v_`.
- **Generics** should have prefix `g_`.
- **Constants** should have prefix `c_`.
- **Custom Types & Enums** should have prefix `t_`.
- **Subtypes** should have prefix `st_`.
- **Component Instances** should have prefix `u_` or `inst_`.
- **STD** and provided standard library functions, procedures, typecasts, etc. should be **ALL CAPS**. Custom datatypes, procedures, and functions can be `lowercase`.
- **Created libraries** **must not** be named `work`.
- **IF / FOR / WHILE** statements should be named with descriptive labels.

## Naming Conventions Quick Reference

| Prefix / Suffix | Applies To | Example | Description |
| :--- | :--- | :--- | :--- |
| `g_` | Generics | `g_data_width`, `g_depth` | Module configuration parameters. |
| `c_` | Constants | `c_baud_limit`, `c_depth` | Static design constants. |
| `s_` | Internal Signals | `s_rx_data`, `s_valid` | Internal register/combinatorial nets. |
| `v_` | Variables | `v_sum`, `v_idx` | Process-local variables. |
| `t_` | Custom Types | `t_state`, `t_axi_m2s` | Enumerations, records, arrays. |
| `st_` | Subtypes | `st_byte`, `st_addr` | Range-constrained subtypes. |
| `u_` | Instances | `u_fifo_ctrl`, `u_uart_tx` | Direct entity instances. |
| `_in` | Input Ports | `clk_in`, `data_in` | Signals entering entity. |
| `_out` | Output Ports | `ready_out`, `tx_out` | Signals driven by entity. |
| `_io` | Bidirectional Ports | `sda_io`, `scl_io` | Tri-state bus pins. |
| `_n` | Active-Low Signals | `rst_n_in`, `cs_n_out` | Negated / active-low polarity. |
| `_proc` | Process Labels | `fsm_proc`, `sample_proc` | Mandatory process label suffix. |
| `_pkg` | Packages | `axi_bus_pkg.vhd` | Shared type/function package. |
| `_tb` | Testbenches | `uart_tx_tb.vhd` | Simulation verification wrapper. |

---

# Standard Libraries & Packages

Hardware designs must import modern, standardized IEEE packages and avoid deprecated vendor-proprietary libraries.

## Mandatory Imports

Every synthesizable VHDL design file **must** import the standard IEEE logic and numeric packages:

```vhdl
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
```

## Forbidden Packages & Anti-Patterns

Legacy packages created by Synopsys before IEEE standardization are strictly forbidden in modern designs:

- **`ieee.std_logic_arith`** (**FORBIDDEN**): Non-standard arithmetic package.
- **`ieee.std_logic_unsigned`** (**FORBIDDEN**): Treats `STD_LOGIC_VECTOR` implicitly as unsigned numbers.
- **`ieee.std_logic_signed`** (**FORBIDDEN**): Treats `STD_LOGIC_VECTOR` implicitly as signed numbers.

> **Synthesis Note:** Using `std_logic_unsigned` or `std_logic_signed` pollutes the namespace and causes severe operator ambiguity and compilation errors when mixed with standard `ieee.numeric_std`. Always use `numeric_std` and cast vectors explicitly to `UNSIGNED` or `SIGNED`.

## Mathematical Functions (`ieee.math_real`)

Use the `ieee.math_real` package **only** for compile-time elaboration and constant calculations (such as computing address bus widths from memory depth):

```vhdl
USE IEEE.MATH_REAL.ALL;

-- Constant calculation in architecture or package header:
CONSTANT c_depth      : INTEGER := 1024;
CONSTANT c_addr_width : INTEGER := INTEGER(CEIL(LOG2(REAL(c_depth))));
```

> **Synthesis Note:** `ieee.math_real` is strictly **non-synthesizable** and **must never** be used inside clocked sequential processes or runtime combinatorial logic.

## Unresolved (`STD_ULOGIC`) vs. Resolved (`STD_LOGIC`)

- `STD_ULOGIC` (unresolved) detects multiple simultaneous drivers at compilation/elaboration time, turning multi-driver wiring bugs into immediate build errors.
- `STD_LOGIC` (resolved) should be reserved for top-level tri-state I/O buffers, bidirectional pins, or when required by third-party vendor IP cores.
- Using `STD_ULOGIC` internally is strongly recommended for large, complex architectures.

---

# Types, Constants & The Record Pattern

## Custom Types & Constants Naming

Custom data types **must** use the `t_` prefix, subtypes **must** use `st_`, and constants **must** use `c_`:

```vhdl
CONSTANT c_max_retries : INTEGER := 3;

TYPE t_state IS (ST_IDLE, ST_FETCH, ST_EXECUTE, ST_ERROR);
SUBTYPE st_byte IS STD_LOGIC_VECTOR(7 DOWNTO 0);
TYPE t_data_array IS ARRAY (0 TO 15) OF st_byte;
```

## Type Conversion & Explicit Casting

Always use standard conversion paths between `STD_LOGIC_VECTOR`, `UNSIGNED`/`SIGNED`, and `INTEGER`:

| Source Type | Target Type | Conversion Syntax |
| :--- | :--- | :--- |
| `STD_LOGIC_VECTOR` | `UNSIGNED` | `UNSIGNED(s_slv)` |
| `UNSIGNED` | `STD_LOGIC_VECTOR` | `STD_LOGIC_VECTOR(s_uns)` |
| `UNSIGNED` | `INTEGER` | `TO_INTEGER(s_uns)` |
| `INTEGER` | `UNSIGNED` | `TO_UNSIGNED(s_int, s_uns'LENGTH)` |
| `STD_LOGIC_VECTOR` | `INTEGER` | `TO_INTEGER(UNSIGNED(s_slv))` |
| `INTEGER` | `STD_LOGIC_VECTOR` | `STD_LOGIC_VECTOR(TO_UNSIGNED(s_int, s_slv'LENGTH))` |

## The Record Interface Pattern

For complex bus protocols (e.g., AXI, Avalon, Wishbone, SPI) and multi-signal module interfaces, bundle related signals into a `RECORD` type inside a shared package. This reduces 20--40 individual port wires down to 2 clean interface records:

```vhdl
-- Package Declaration (uart_bus_pkg.vhd)
PACKAGE uart_bus_pkg IS
    TYPE t_uart_m2s IS RECORD
        txd   : STD_LOGIC;
        rts_n : STD_LOGIC;
    END RECORD t_uart_m2s;

    TYPE t_uart_s2m IS RECORD
        rxd   : STD_LOGIC;
        cts_n : STD_LOGIC;
    END RECORD t_uart_s2m;

    -- Deterministic reset/default constant
    CONSTANT c_uart_m2s_init : t_uart_m2s := (txd => '1', rts_n => '1');
    CONSTANT c_uart_s2m_init : t_uart_s2m := (rxd => '1', cts_n => '1');
END PACKAGE uart_bus_pkg;
```

```vhdl
-- Entity using Record Ports
ENTITY uart_transceiver IS
    PORT (
        clk_in   : IN  STD_LOGIC;
        rst_n_in : IN  STD_LOGIC;
        uart_m2s : OUT t_uart_m2s;
        uart_s2m : IN  t_uart_s2m
    );
END ENTITY uart_transceiver;
```

> **Tip:** Providing a constant default record (`c_uart_m2s_init`) guarantees single-line, clean reset initialization and avoids missing field assignments when adding new record members later.

---

# Ports and Generics

- **Generics** should have the prefix `g_`.

```vhdl
GENERIC (
    g_data_width : INTEGER := 32;
    g_num_tx     : INTEGER := 4
);
```

- **Port declarations** should contain comments that clearly indicate categories such as inputs, outputs, debug signals, etc.
- Ports should follow standard direction suffixes: `_in`, `_out`, and `_io`.

## Generic Parameter Validation (`ASSERT`)

Always validate generic configuration parameters during design elaboration inside the architecture statement body:

```vhdl
ARCHITECTURE rtl OF packet_buffer IS
BEGIN
    ASSERT (g_data_width = 8 OR g_data_width = 16 OR g_data_width = 32)
        REPORT "g_data_width must be 8, 16, or 32!"
        SEVERITY FAILURE;

    ASSERT (g_depth > 0)
        REPORT "g_depth must be strictly positive!"
        SEVERITY FAILURE;
-- ...
END ARCHITECTURE rtl;
```

## Handling Unconnected Ports (`OPEN`)

When you instantiate a module with unused output ports, explicitly assign them to the `OPEN` keyword to document intended disconnection:

```vhdl
u_uart : ENTITY work.uart_rx(rtl)
    PORT MAP (
        clk_in    => clk_in,
        rst_n_in  => rst_n_in,
        data_out  => s_rx_byte,
        error_out => OPEN -- Intentionally unconnected
    );
```

---

# Structural Design & Instantiations

## Direct Entity Instantiation

Modern VHDL designs **must** use direct entity instantiation (`ENTITY work.module_name(arch_name)`) rather than declaring `COMPONENT ... END COMPONENT` blocks in the architecture declarative header.

```vhdl
-- RECOMMENDED: Direct Entity Instantiation
u_crc_engine: ENTITY work.crc32(rtl)
    GENERIC MAP (
        g_poly => x"04C11DB7"
    )
    PORT MAP (
        clk_in   => clk_in,
        rst_n_in => rst_n_in,
        data_in  => s_tx_data,
        crc_out  => s_tx_crc
    );
```

> **Note:** Direct entity instantiation prevents mismatch errors between component signatures and entity definitions, eliminates duplicate boilerplate code, and enables compile-time generic verification.

## Mandatory Named Association

Positional port mapping (`PORT MAP (clk_in, rst_n_in, s_data, s_valid);`) is **strictly forbidden** for any entity with more than one port. Always use explicit named association:

```vhdl
-- FORBIDDEN (Positional):
-- u_tx: ENTITY work.tx PORT MAP (clk_in, rst_n_in, s_din, s_dout);

-- CORRECT (Named Association):
u_tx: ENTITY work.tx(rtl)
    PORT MAP (
        clk_in   => clk_in,
        rst_n_in => rst_n_in,
        data_in  => s_din,
        data_out => s_dout
    );
```

## Reading Output Ports (`OUT` vs `BUFFER`)

- In **VHDL-2008**: Reading `OUT` ports directly within the architecture is standard and fully supported.
- In **VHDL-93**: Reading `OUT` ports is illegal. Always declare an internal shadow signal (`s_<name>_out`), operate on it, and assign the port concurrently at the bottom of the architecture (`port_out <= s_port_out;`).
- **Strict Rule**: The `BUFFER` port mode **must not** be used. `BUFFER` restricts port connections up through the hierarchy and introduces severe synthesis limitations.

---

# Clocking, Resets & Synchronous Design

Reliable synchronous design requires clean clock distribution, controlled reset strategies, and disciplined clock domain crossing (CDC).

## Port Order & Reset Naming
- **Clock** should be the first specified port in the port list (`clk_in`).
- **Reset** should be the second specified port in the port list.
- **Reset** should have its active value and synchronicity explicitly documented.
- **Reset naming** should reflect both synchronicity and active value:
  - `areset_n` / `arst_n` -> Asynchronous reset, active low (negated)
  - `rst_n` -> Synchronous reset, active low (negated)
- **Reset** should be active low.

```vhdl
PORT (
    -- Inputs
    clk_in      : IN STD_LOGIC;
    rst_n_in    : IN STD_LOGIC; -- synchronous reset, active low
    areset_n_in : IN STD_LOGIC  -- asynchronous reset, active low
);
```

## Clock Gating Anti-Pattern & Clock Enables

- **Never** gate clock signals with combinatorial logic (`clk_gated <= clk_in AND s_en;` is **strictly forbidden**). Gated clocks introduce clock skew, false transitions, and timing violation hazards.
- Always use dedicated synchronous **Clock Enables** inside the clocked process:

```vhdl
-- RIGHT: Synchronous Clock Enable
reg_proc: PROCESS(clk_in)
BEGIN
    IF rising_edge(clk_in) THEN
        IF s_clk_en = '1' THEN
            s_data_reg <= s_data_next;
        END IF;
    END IF;
END PROCESS reg_proc;
```

## Single Clock Edge & Ripple Clocks

- Designs **must** trigger exclusively on `rising_edge(clk_in)`. Mixing `falling_edge()` in the same clock domain cuts available setup time in half and complicates static timing analysis.
- **No Ripple Clocks**: Never use flip-flop outputs or combinatorial counters as clocks for downstream registers. Use PLL / MMCM primitives or synchronous clock enable strobes.

## The 2-Stage Reset Synchronizer

Asynchronous reset inputs from external pins **must** be de-asserted synchronously to prevent metastability and ensure clean recovery/removal timing closure. Synchronizer registers must include the `async_reg` attribute:

```vhdl
ARCHITECTURE rtl OF reset_synchronizer IS
    SIGNAL s_rst_sync_stage1 : STD_LOGIC;
    SIGNAL s_rst_sync_stage2 : STD_LOGIC;

    ATTRIBUTE async_reg : STRING;
    ATTRIBUTE async_reg OF s_rst_sync_stage1 : SIGNAL IS "TRUE";
    ATTRIBUTE async_reg OF s_rst_sync_stage2 : SIGNAL IS "TRUE";
BEGIN
    reset_sync_proc: PROCESS(clk_in, areset_n_in)
    BEGIN
        IF areset_n_in = '0' THEN
            s_rst_sync_stage1 <= '0';
            s_rst_sync_stage2 <= '0';
        ELSIF rising_edge(clk_in) THEN
            s_rst_sync_stage1 <= '1';
            s_rst_sync_stage2 <= s_rst_sync_stage1;
        END IF;
    END PROCESS reset_sync_proc;

    s_sync_rst_n <= s_rst_sync_stage2;
END ARCHITECTURE rtl;
```

## Selective Datapath Reset (SRL Optimization)

- Reset **only** critical control registers, state machines, and valid flags.
- Do **not** reset wide datapath pipeline shift registers. Omitting resets on datapath pipelines allows FPGA synthesis tools to infer efficient Look-Up Table Shift Registers (SRL16E/SRL32E) and reduces high-fanout reset network congestion.

## Clock Domain Crossing (CDC) Rules

When transferring signals between independent asynchronous clock domains:

1. **Single-Bit Control Levels**: Use a 2-stage (or 3-stage) flip-flop synchronizer with synthesis attributes preventing register optimization (`async_reg = "TRUE"`).
2. **Single-Cycle Pulses**: A simple 2-stage synchronizer **cannot** reliably transfer single-cycle pulses from a fast clock to a slower clock (the pulse may be missed). Use a **Toggle Synchronizer** (toggle a level on input pulse, 2-stage sync the level, and edge-detect on destination clock).
3. **Multi-Bit Data Buses**: **Never** pass multi-bit buses through parallel bit synchronizers (bus skew causes sampling of invalid intermediate words). Always use:
   - An **Asynchronous FIFO** with Gray-coded read/write pointers.
   - A **Handshake / Toggle Qualifier** where multi-bit data remains stable while a single-bit synchronized strobe transfers across domains.

---

# Process & Combinatorial Logic

- Processes **must** be named with a label.
- The process label should follow the format `something_proc`.

## Clocked Process: Synchronous Reset vs Asynchronous Reset

Clocked processes must strictly isolate clock and reset logic into one of two standard patterns:

### Pattern A: Synchronous Reset Process
For synchronous resets, the sensitivity list **must contain ONLY the clock**:

```vhdl
sync_reg_proc: PROCESS(clk_in)
BEGIN
    IF rising_edge(clk_in) THEN
        IF rst_n_in = '0' THEN
            s_reg <= (OTHERS => '0');
        ELSE
            s_reg <= s_next;
        END IF;
    END IF;
END PROCESS sync_reg_proc;
```

### Pattern B: Asynchronous Reset Process
For asynchronous resets, the sensitivity list **must contain ONLY clock and asynchronous reset**:

```vhdl
async_reg_proc: PROCESS(clk_in, areset_n_in)
BEGIN
    IF areset_n_in = '0' THEN
        s_reg <= (OTHERS => '0');
    ELSIF rising_edge(clk_in) THEN
        s_reg <= s_next;
    END IF;
END PROCESS async_reg_proc;
```

## Combinatorial Process
- Combinatorial processes **must** have `ALL` sensitivity: `PROCESS(ALL)`.
- If using VHDL-93, the sensitivity list **must** explicitly contain every signal read inside the process body.

## Latch Prevention
- In a combinatorial process, assign every signal a value in all conditional branches. Every `IF` statement needs an `ELSE` branch, and every `CASE` statement needs a `WHEN OTHERS` branch. This prevents unintended latch inference.

---

# Architecture & Finite State Machines (FSM)

FSMs (Finite State Machines) are the heart of VHDL control logic. Proper implementation ensures high speed, resource efficiency, and robustness against illegal state hangs.

## Process Structure

### Two-Process FSM
Separates combinatorial next-state logic from sequential state registers into two distinct processes.

### One-Process FSM
- Recommended for FPGA targets.
- Results in registered outputs, which is beneficial for timing closure.

## State Transitions
- **Never** use `rising_edge()` on input (data) signals to control state transitions.
- To detect an edge, generate a single-cycle pulse signal and sample the level of that pulse.
- When an `ELSE` branch points only to the active state, omit the `ELSE` branch and keep only the `IF` statement.

```vhdl
-- RIGHT (No ELSE needed for synthesizable FSM)
IF start = '1' THEN
    next_state <= RUN;
END IF;
-- (Assumes default assignment or OTHERS handles IDLE if necessary)
```

## FSM Optimizations and Hacks

### The "Default Assignment" Hack
Assign default values *once* at the top of the process rather than in every `WHEN` branch. This prevents latches and simplifies state logic.

```vhdl
fsm_proc: PROCESS(clk_in)
BEGIN
    IF rising_edge(clk_in) THEN
        -- CORRECT: Default assignments
        s_output_val <= '0'; 
        s_busy       <= '1';

        CASE s_current_state IS
            WHEN ST_IDLE =>
                s_busy <= '0';
                IF s_start = '1' THEN
                    s_current_state <= ST_RUN;
                END IF;
            
            WHEN ST_RUN =>
                s_output_val <= '1';
        END CASE;
    END IF;
END PROCESS fsm_proc;
```

### The "Safe FSM" Attribute
In high-reliability designs, radiation-induced single-event upsets (SEUs) or bit-flips can kick an FSM into an undefined state. Synthesis attributes force the compiler to generate state recovery logic.

| Attribute | Value | Description |
| :--- | :--- | :--- |
| `fsm_safe_state` | `"default_state"` | AMD/Vivado: Forces FSM to return to reset on illegal state. |
| `syn_encoding` | `"safe"` | Intel/Quartus & Synopsys: Generates safe recovery logic. |
| `fsm_encoding` | `"one_hot"`, `"gray"` | Overrides compiler default state bit encoding. |

```vhdl
TYPE t_state IS (ST_IDLE, ST_READ, ST_WRITE);
SIGNAL s_state : t_state;

-- AMD Vivado safe FSM attribute:
ATTRIBUTE fsm_safe_state : STRING;
ATTRIBUTE fsm_safe_state OF s_state : SIGNAL IS "default_state";
```

### Registered Look-Ahead Outputs
To eliminate slow combinatorial output paths, calculate the **next** output from the **next** state in the same cycle. Both state and output then update together at the clock edge.

```vhdl
CASE s_current_state IS
    WHEN ST_IDLE =>
        IF s_start = '1' THEN
            s_current_state <= ST_RUN;
            s_output_reg    <= '1'; -- Look ahead
        END IF;
END CASE;
```

### The "Transition Bit" Hack
Use a "Last State" register to cleanly detect state transitions without constructing complex combinatorial edge detectors:

```vhdl
s_state_changed <= '1' WHEN (s_current_state /= s_last_state) ELSE '0';
```

### Integer-Based FSMs for Math
If an FSM progresses through an arithmetic sequence, declaring states as an `INTEGER RANGE` instead of an `ENUMERATION` enables direct mathematical operations on state variables:

```vhdl
SIGNAL s_state : INTEGER RANGE 0 TO 15;
-- ...
WHEN 0 TO 5 => 
    s_state <= s_state + 1;
```

## Handling Counters and Incrementing in FSMs

In VHDL, sequential signal assignments take one clock cycle to take effect. Correct counter management prevents off-by-one errors.

### Exit Condition Look-Ahead
Compare against `TERMINAL_COUNT - 1` when using registered signals to prevent lingering in a state for an unintended extra cycle.

```vhdl
-- RIGHT: Stays for exactly 10 cycles
IF s_count = g_LIMIT - 1 THEN
    s_count <= 0;
    s_state <= ST_NEXT;
ELSE
    s_count <= s_count + 1;
END IF;
```

### Terminal Count (TC) Signal
Calculate terminal count comparisons outside the `CASE` statement to reduce logic depth and improve maximum clock frequency ($F_max$).

```vhdl
s_count_done <= '1' WHEN s_count = g_LIMIT - 1 ELSE '0';
```

### State Entry Reset
Reset counters during the **transition** leading into the counting state so that counting always starts cleanly from zero upon entry.

### Variables for Same-Cycle Logic
If updated increment values must be evaluated immediately within the exact same clock cycle, use a `VARIABLE`.

### Counter Patterns Comparison

| Pattern | Best For | Pros | Cons |
| :--- | :--- | :--- | :--- |
| **Signal Increment** | General Purpose | Easy to debug in simulation waveforms. | 1-cycle latency in comparisons. |
| **Variable Increment** | Complex Math | Logic evaluates in "zero time." | Harder to observe in some simulators. |
| **External TC** | High Speed ($F_max$) | Optimal for timing closure. | Requires an additional signal. |

### Counter Overflow Prevention
Always declare range-bounded integers and include an explicit reset assignment in the `WHEN OTHERS` branch to prevent permanent deadlocks.

### Shared Counter Optimization
Use a single generic counter signal across multiple states. Reset it across transitions to reduce FPGA logic utilization (LUT count).

---

# Subprograms: Functions & Procedures

Subprograms (functions and procedures) modularize repetitive algorithms, compute elaboration parameters, and decompose complex process logic. Distinguishing between pure functions, impure functions, and procedures is vital for synthesizable and deterministic hardware design.

## Architectural Scope & Subprogram Selection

VHDL provides two distinct subprogram classes: **Functions** and **Procedures**. Choosing the correct subprogram and defining its scope properly ensures clean hierarchy, high performance, and synthesis predictability.

| Characteristic | Function | Procedure |
| :--- | :--- | :--- |
| **Return Value** | Single value via `RETURN` | None (modifies `OUT` / `INOUT` parameters) |
| **Parameter Modes** | `IN` only (default class `CONSTANT`) <br> *(VHDL-2008 adds `FILE`, `PROTECTED`)* | `IN`, `OUT`, `INOUT` (classes `CONSTANT`, `VARIABLE`, `SIGNAL`) |
| **Invocation Context** | Within expressions, concurrent assignments, generic maps | As sequential statement in a process or concurrent procedure call |
| **WAIT Statements** | **Strictly Forbidden** (illegal in functions) | **Simulation only** (forbidden in synthesizable RTL) |
| **Synthesis Target** | Combinatorial netlist (LUTs/ALU) or elaboration constants | Combinatorial/sequential logic within host process |

### Declarative Scope Placement

Subprograms can be declared in three primary scopes:

- **Package Body (`_pkg.vhd`)**: For globally reusable subprograms across entities and testbenches (e.g., CRC functions, `clog2`, bus conversion utilities). Declare the subprogram signature in the `PACKAGE`, and place its implementation in the `PACKAGE BODY`.
- **Architecture Declarative Region**: For helper routines shared among multiple processes within a single module architecture, but not needed outside the entity.
- **Process Declarative Region**: For local subprograms called exclusively by one specific process. This encapsulates process-specific temporary variables and logic, keeping the architecture namespace clean.

## Pure Functions (`PURE FUNCTION`)

Functions in VHDL are **pure** by default (the `PURE` keyword is optional). Pure functions adhere to strict mathematical functional purity:

1. **Determinism**: For identical input arguments, a pure function **always** returns the exact same result.
2. **No Side Effects**: A pure function cannot read or modify any signal, variable, or external state outside its formal parameter list.
3. **Synthesis Friendly**: Synthesis tools can optimize pure functions aggressively (constant folding, dead-code elimination, and resource sharing).

> **Note:** Custom functions and procedures **should** use `lowercase` names, while IEEE standard functions and datatypes **must** be in `ALL CAPS`.

### Elaboration Width Calculation (`clog2`)

A classic pure function calculates address bus widths from memory depth parameters at compile time:

```vhdl
FUNCTION clog2(depth : POSITIVE) RETURN NATURAL IS
    VARIABLE v_temp  : POSITIVE := depth - 1;
    VARIABLE v_width : NATURAL  := 0;
BEGIN
    WHILE v_temp > 0 LOOP
        v_temp  := v_temp / 2;
        v_width := v_width + 1;
    END LOOP;
    RETURN v_width;
END FUNCTION clog2;
```

### Combinatorial Logic Generation

Pure functions can also generate synthesizable combinatorial logic networks, such as a parameterized bit-reversal:

```vhdl
FUNCTION reverse_bits(vec : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR IS
    VARIABLE v_res : STD_LOGIC_VECTOR(vec'RANGE);
BEGIN
    FOR i IN vec'LOW TO vec'HIGH LOOP
        v_res(vec'HIGH - (i - vec'LOW)) := vec(i);
    END LOOP;
    RETURN v_res;
END FUNCTION reverse_bits;
```

## Impure Functions (`IMPURE FUNCTION`)

An `IMPURE FUNCTION` is explicitly declared with the `IMPURE` keyword. Unlike pure functions, impure functions:

- Can read or modify signals, shared variables, or files outside their parameter list.
- Can return different values on successive calls even when invoked with identical arguments.

> **Synthesis Note:** **Impure functions must NEVER be used for runtime synthesizable datapath logic.** Reading external signals inside an impure function hides sensitivity dependencies. This causes delta-cycle race conditions and simulation-synthesis mismatches.

### Synthesizable Use Case: ROM Pre-loading via File I/O (`TEXTIO`)

The primary synthesizable use of an `IMPURE FUNCTION` is compile-time elaboration. Use it to initialize FPGA block RAMs or ROMs from an external data file:

```vhdl
USE STD.TEXTIO.ALL;

-- Architecture Declarative Region
TYPE t_rom_array IS ARRAY (0 TO c_rom_depth - 1) OF STD_LOGIC_VECTOR(g_data_width - 1 DOWNTO 0);

IMPURE FUNCTION init_rom_from_file(file_name : STRING) RETURN t_rom_array IS
    FILE rom_file   : TEXT OPEN READ_MODE IS file_name;
    VARIABLE v_line : LINE;
    VARIABLE v_data : STD_LOGIC_VECTOR(g_data_width - 1 DOWNTO 0);
    VARIABLE v_rom  : t_rom_array := (OTHERS => (OTHERS => '0'));
BEGIN
    FOR i IN 0 TO c_rom_depth - 1 LOOP
        IF NOT ENDFILE(rom_file) THEN
            READLINE(rom_file, v_line);
            HREAD(v_line, v_data); -- VHDL-2008 / standard hex read
            v_rom(i) := v_data;
        END IF;
    END LOOP;
    RETURN v_rom;
END FUNCTION init_rom_from_file;

-- Initialized ROM constant (inferred as Block RAM/ROM during synthesis)
CONSTANT c_rom_data : t_rom_array := init_rom_from_file("boot_code.hex");
```

### Testbench Use Case: Random Generators & Monitors

In testbenches, impure functions are commonly used for:
- Pseudorandom number generators that update an internal or shared seed variable.
- Accessing simulation time (`NOW`) or sampling global simulation flags without passing them through parameter lists.

## Procedures (`PROCEDURE`)

Procedures execute sequential statements, can return multiple results through `OUT` or `INOUT` parameters, and can directly drive signals.

### Parameter Modes & Classes

Procedure parameters support three modes:
- `IN`: Read-only. The default parameter class is `CONSTANT`.
- `OUT`: Write-only. The default parameter class is `VARIABLE`.
- `INOUT`: Read and write. The default parameter class is `VARIABLE`.

Procedure parameters can also explicitly declare the `SIGNAL` class:

```vhdl
PROCEDURE pulse_strobe(
    SIGNAL strobe_out : OUT STD_LOGIC
);
```

### Synthesizable RTL Procedure Rules

When using procedures in synthesizable RTL designs, follow these mandatory rules:

1. **No `WAIT` Statements**: Procedures synthesized into hardware **must not** contain `WAIT` statements. All operations must complete in zero simulation time within the host process.
2. **Latch Prevention**: If a procedure assigns output variables or signals conditionally, ensure all possible execution paths assign a value, or initialize defaults prior to invocation.
3. **Single Driver Rule**: When passing signals as `OUT` or `INOUT` to a procedure, ensure only one active process drives that signal.

### The `SIGNAL` vs `VARIABLE` Parameter Trap

A critical semantic difference exists between passing a `VARIABLE` and a `SIGNAL` to a procedure:

- **Variable parameter (`VARIABLE`)**: Assigned using `:=`. The variable updates **immediately** within the procedure.
- **Signal parameter (`SIGNAL`)**: Assigned using `<=`. The assignment schedules an event that takes effect **only at the next delta cycle or clock edge**.

```vhdl
-- Factoring out repetitive synchronous handshake logic in an FSM
PROCEDURE send_packet(
    SIGNAL tx_data_out  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL tx_valid_out : OUT STD_LOGIC;
    CONSTANT c_payload  : IN  STD_LOGIC_VECTOR(31 DOWNTO 0)
) IS
BEGIN
    tx_data_out  <= c_payload;
    tx_valid_out <= '1';
END PROCEDURE send_packet;
```

## Array Parameter Handling & Index Normalization

A pervasive bug in VHDL subprograms is assuming the index range or direction of unconstrained array parameters.

### The Index Range Trap

When passing an array slice like `s_data(15 DOWNTO 8)` or an ascending array `s_bus(0 TO 7)` to a subprogram declared with `(vec : STD_LOGIC_VECTOR)`:
- The parameter **inherits the exact index range and direction** of the actual signal passed to it.
- If the function body attempts to access `vec(0)` or `vec(7)`, a runtime index failure occurs because valid indices for `s_data(15 DOWNTO 8)` are `15 DOWNTO 8`.

### The Normalization Solution (`ALIAS`)

To write reliable, reusable subprograms that accept any vector range or direction:

1. Declare unconstrained vector parameters (`STD_LOGIC_VECTOR` or `UNSIGNED`).
2. Normalize the index range inside the subprogram using an `ALIAS`:

```vhdl
FUNCTION count_ones(vec : STD_LOGIC_VECTOR) RETURN NATURAL IS
    -- Normalize index to (vec'LENGTH - 1 DOWNTO 0) regardless of caller range
    ALIAS a_vec      : STD_LOGIC_VECTOR(vec'LENGTH - 1 DOWNTO 0) IS vec;
    VARIABLE v_count : NATURAL := 0;
BEGIN
    FOR i IN a_vec'LOW TO a_vec'HIGH LOOP
        IF a_vec(i) = '1' THEN
            v_count := v_count + 1;
        END IF;
    END LOOP;
    RETURN v_count;
END FUNCTION count_ones;
```

> **Tip:** Normalizing array parameters with `ALIAS a_vec : ... (vec'LENGTH - 1 DOWNTO 0)` guarantees immunity against ascending (`TO`) vs descending (`DOWNTO`) index discrepancies and non-zero slice offsets.

### Subprogram Overloading

VHDL permits subprogram overloading, where multiple functions or procedures share the same name with different parameter signatures (types or counts) or return types:

```vhdl
-- Overloaded to accept both STD_LOGIC_VECTOR and UNSIGNED
FUNCTION to_gray(val : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR;
FUNCTION to_gray(val : UNSIGNED) RETURN UNSIGNED;
```

Overloading should be used judiciously—principally for type conversions and widening arithmetic operations—to avoid ambiguity in expressions.

## Subprograms Quick Reference & Rules

| Rule | Severity | Description |
| :--- | :--- | :--- |
| **Pure by Default** | Must | All runtime datapath and math functions **must** be pure. |
| **Impure for ROM Init** | Permitted | Use `IMPURE FUNCTION` with `TEXTIO` for compile-time ROM pre-loading. |
| **No Impure Datapath** | Must | Never use impure functions in runtime synthesizable datapath logic. |
| **No WAIT in RTL** | Must | Procedures for synthesis **must not** contain `WAIT` statements. |
| **Normalize Arrays** | Should | Use `ALIAS` or `'RANGE` / `'LENGTH` to prevent index range mismatches. |
| **Subprogram Overloading** | Permitted | Permitted for polymorphic types. Keep signatures unambiguous. |
| **Lowercase Naming** | Should | Custom subprogram names should be `lowercase` (e.g., `clog2`, `count_ones`). |
| **Latch Prevention** | Must | Procedures assigning combinatorial outputs must assign values in all branches. |

---

# Modern VHDL-2008 Quality-of-Life Features

VHDL-2008 provides significant enhancements that eliminate historical verbosity while maintaining strict type safety.

## Unary Reduction Operators

Unary logical reduction operators apply across all bits of a vector, eliminating manual for-loops and reduction functions:

```vhdl
s_all_ones <= AND s_data_bus;  -- Equivalent to s_data_bus = (s_data_bus'RANGE => '1')
s_has_one  <= OR  s_data_bus;  -- Equivalent to s_data_bus /= (s_data_bus'RANGE => '0')
s_parity   <= XOR s_data_bus;  -- Computes odd/even parity bit
```

## Matching Relational Operators (`?=`, `?/=`, `?<`, `?<=`, `?>`, `?>=`)

Matching operators treat bit elements as standard `STD_ULOGIC` values and support bitwise "don't care" (`'-'`) matching:

```vhdl
-- Compares against bitmask containing '-' don't-care bits:
IF (s_instruction ?= "1010----") THEN
    s_is_branch <= '1';
END IF;
```

## Sequential Conditional and Selected Assignments

VHDL-2008 allows conditional (`WHEN/ELSE`) and selected (`WITH/SELECT`) assignments inside sequential `PROCESS` blocks:

```vhdl
reg_proc: PROCESS(clk_in)
BEGIN
    IF rising_edge(clk_in) THEN
        -- Conditional assignment directly inside sequential process:
        s_data <= c_init_val WHEN s_reset = '1' ELSE s_next_data;
    END IF;
END PROCESS reg_proc;
```

## Unconstrained Array Elements

Packages and records can declare arrays of unconstrained elements, enabling truly generic data structures:

```vhdl
TYPE t_slv_array IS ARRAY (NATURAL RANGE <>) OF STD_LOGIC_VECTOR;
```

## Direct Reading of Output Ports

VHDL-2008 removes the restriction forbidding reads of `OUT` mode ports, eliminating unnecessary internal shadow signals:

```vhdl
ENTITY counter IS
    PORT (
        clk_in    : IN  STD_LOGIC;
        count_out : OUT UNSIGNED(7 DOWNTO 0)
    );
END ENTITY counter;

ARCHITECTURE rtl OF counter IS
BEGIN
    count_proc: PROCESS(clk_in)
    BEGIN
        IF rising_edge(clk_in) THEN
            -- In VHDL-2008, reading count_out directly is fully legal:
            count_out <= count_out + 1;
        END IF;
    END PROCESS count_proc;
END ARCHITECTURE rtl;
```

## Block Comments

VHDL-2008 supports C-style block comments in addition to standard `--` line comments:

```vhdl
/*
   Multi-line block comment
   Supported in VHDL-2008 compliant synthesis and simulation tools.
*/
```

---

# Appendix: VHDL Language Reference

## Attributes

An attribute provides additional information about a specific element in a VHDL description, such as a type, range, signal, or subprogram.

### Attribute Syntax

```vhdl
object_name[ signature ]'attribute_name[ ( expression ) ]
```

### Global Type Attributes

| Attribute | Result |
| :--- | :--- |
| `T'BASE` | Returns the base type of type `T`. |

### Scalar Type Attributes

| Attribute | Return Type | Description |
| :--- | :--- | :--- |
| `T'LEFT` | Same as `T` | The leftmost value of `T`. |
| `T'RIGHT` | Same as `T` | The rightmost value of `T`. |
| `T'LOW` | Same as `T` | The least value in `T`. |
| `T'HIGH` | Same as `T` | The greatest value in `T`. |
| `T'ASCENDING` | `BOOLEAN` | `TRUE` if `T` is an ascending range. |
| `T'IMAGE(x)` | `STRING` | Textual string representation of value `x`. |
| `T'VALUE(s)` | Base of `T` | Value in `T` represented by string `s`. |

### Discrete & Physical Type Attributes

| Attribute | Return Type | Description |
| :--- | :--- | :--- |
| `T'POS(s)` | `INTEGER` | Position number of `s` in type `T`. |
| `T'VAL(x)` | Base of `T` | Value at integer position `x` in type `T`. |

> **Note:** Synthesis tools generally discourage the use of value navigation attributes for physical hardware generation.

### Array Attributes

| Attribute | Result |
| :--- | :--- |
| `A'LEFT(n)` | Leftmost value in the index range of dimension `n`. |
| `A'RIGHT(n)` | Rightmost value in the index range of dimension `n`. |
| `A'LOW(n)` | Lowest bound in the index range of dimension `n`. |
| `A'HIGH(n)` | Highest bound in the index range of dimension `n`. |
| `A'RANGE(n)` | The specific index range (e.g., `7 DOWNTO 0`). |
| `A'REVERSE_RANGE(n)` | Reversed index range (e.g., `0 TO 7`). |
| `A'LENGTH(n)` | Total number of values in the `n`-th dimension index range. |

### Signal Attributes

| Attribute | Result |
| :--- | :--- |
| `S'DELAYED(t)` | Signal `S` delayed by simulation time units `t`. |
| `S'STABLE(t)` | `TRUE` if no event has occurred on `S` for time duration `t`. |
| `S'EVENT` | `TRUE` if an event occurred on `S` in the current cycle. |
| `S'ACTIVE` | `TRUE` if any transaction occurred on `S` in current cycle. |
| `S'LAST_EVENT` | Time elapsed since the most recent event on `S`. |
| `S'LAST_VALUE` | The previous value of `S` prior to the most recent event. |
| `S'DRIVING` | `TRUE` if the current process is actively driving signal `S`. |

### Named Entity Attributes

| Attribute | Result |
| :--- | :--- |
| `E'PATH_NAME` | String describing the full hierarchical design path to `E`. |
| `E'INSTANCE_NAME` | Full hierarchical path including entity and architecture names. |

### Synthesis Attributes & Placement Control

Synthesis attributes provide compiler directives to guide physical hardware mapping, register packing, and netlist optimizations.

#### The I/O Timing Savior: `IOB`

- **What it does**: Packs interface flip-flops into dedicated ILOGIC/OLOGIC storage elements in the physical I/O ring, rather than general FPGA fabric slices.
- **Why it matters**: High-speed external interfaces (ADCs, DACs, SPI flash, Ethernet PHYs) require strict setup ($t_{su}$), hold ($t_h$), and clock-to-output ($t_{co}$) times. Fabric routing adds variable delays that break timing across builds. Setting `IOB = "TRUE"` packs the register into the pin buffer. This eliminates interconnect delay and ensures deterministic timing.

**Example:**

```vhdl
ARCHITECTURE rtl OF spi_master IS
    SIGNAL s_spi_miso_reg : STD_LOGIC;

    -- 1. Declare the synthesis attribute
    ATTRIBUTE iob : STRING;
    
    -- 2. Apply it to the internal register signal or port
    ATTRIBUTE iob OF s_spi_miso_reg : SIGNAL IS "TRUE";
BEGIN
    sample_proc: PROCESS(clk_in)
    BEGIN
        IF rising_edge(clk_in) THEN
            s_spi_miso_reg <= spi_miso_in;
        END IF;
    END PROCESS sample_proc;
END ARCHITECTURE rtl;
```

| Attribute | Value | Description |
| :--- | :--- | :--- |
| `iob` | `"TRUE"`, `"FALSE"` | AMD/Vivado: Packs flip-flops into dedicated I/O pad ring blocks (Quartus equivalent: `useioff`). |
| `async_reg` | `"TRUE"` | Prevents logic absorption and places synchronizers close together. |
| `dont_touch` / `keep` | `"TRUE"` | Prevents optimization/merging of redundant registers or nets. |
| `fsm_safe_state` | `"default_state"` | AMD/Vivado: Enforces illegal state recovery logic in FSMs. |
| `syn_encoding` | `"safe"` | Intel/Quartus & Synopsys: Enforces safe FSM recovery encoding. |

---

## Simulation & Delta Control

### Process Control

| Keyword | Description |
| :--- | :--- |
| `POSTPONED` | Ensures the block executes only during the **last** delta cycle of a simulation time step. |

### Delay Modeling

| Keyword | Delay Type | Description |
| :--- | :--- | :--- |
| `TRANSPORT` | Transport | Models ideal wire delay. All signal pulses pass through regardless of width. |
| `REJECT` | Inertial | Specifies pulse rejection width threshold for inertial delay. |

### Simulation Hacks & Testbenching

| Technique | Description |
| :--- | :--- |
| `WAIT FOR 0 NS;` | Forces simulator to advance to the next **delta cycle**. |
| `FORCE` | Overrides a signal's value directly during simulation (VHDL-2008). |
| `RELEASE` | Removes a previously applied `FORCE` override. |

> **Synthesis Note:** All keywords and constructs in this simulation section are strictly **non-synthesizable** and intended exclusively for testbench verification.

### Driving Attributes

| Attribute | Description |
| :--- | :--- |
| `S'DRIVING` | Returns `TRUE` if the current process is actively contributing a value to `S`. |
| `S'DRIVING_VALUE` | Returns the value this specific process is attempting to drive onto `S`. |

### Hierarchical Reference (External Names)
Access internal signals without routing intermediate ports:
```vhdl
<<SIGNAL .path.to.signal : type>>
```

### Simulation Termination
Use `FINISH` or `STOP` from `STD.ENV` to terminate simulations cleanly without assertion failures:
```vhdl
USE STD.ENV.ALL;
-- ...
FINISH;
```

### Transaction Tracking (`'TRANSACTION`)
A `BIT` signal attribute that toggles on every signal transaction, even when the driven value remains identical.

---

## Other Useful VHDL Features

### Scoping with `BLOCK`
Creates an isolated local scope for signals to eliminate naming collisions and partition large architectures cleanly.

### The `ALIAS` Keyword
Defines a concise nickname for a slice of a wide vector or bus:

```vhdl
ALIAS a_payload_id : STD_LOGIC_VECTOR(7 DOWNTO 0) IS s_long_bus(119 DOWNTO 112);
```
