---
name: vhdl-guideline
description: >-
  Comprehensive VHDL hardware design rules, coding standards, synthesizable best practices,
  and architecture patterns. Activate this skill whenever writing, reviewing, refactoring,
  or debugging VHDL code, testbenches, or finite state machines (FSMs).
---

# Basics

- Must is non negotiable
- Should and permitted is best practice
- Tip is recommended


- Entity should be lowercase.
- Keywords **must** be in **ALL CAPS**.
- Functions and procedures are permitted to be in lowercase.
- Signals and variables **must** be lowercase.
- Signals should have prefix `s_`
- Variables should have prefix `v_`
- **STD** and provided functions, procedures, typecasts etc. should be all caps, custom datatypes, procedures, functions can be lowercase.

- Created library **must not** be named work.
- **IF/FOR/WHILE** statements should be named.

# Port and generics
- Generics should have prefix `g_`
  - Example:

```vhdl
  GENERIC (
    g_num_tx   : INTEGER
  );
```

- Port should have comments that indicate categories like inputs/outputs/debug...

# Clock and reset

- Clock should be first specified port.
- Reset should be second specified port.
- Reset should have active value and synchronicity specified.
- Reset name should reflect synchronicity and active value.
- Reset should be active low.
- Example:
  - `areset_n/arst_n -> asynchronous reset negated`
  - `rst_n    -> synchronous reset negated` 
  

Example: 

```vhdl
PORT (
    -- Inputs
    clk_in      : IN STD_LOGIC;
    rst_n_in    : IN STD_LOGIC; -- synchronous reset, active low
    areset_n_in : IN STD_LOGIC  -- asynchronous reset, active low
);
```

# Process

- Process **must** be named.
- Name should be `something_proc`
- Example:

```vhdl
main_proc: PROCESS(clk_in)
BEGIN
    -- something
END PROCESS main_proc;
```

- Process with senstivity to only clock and reset should be in clocked modules.
- Process with sensitivity list **ALL** should be used for combinatorial modules.

```vhdl
reg_proc: PROCESS(clk_in, areset_n_in)
BEGIN
    reset_if: IF areset_n_in = '0' THEN
        -- Asynchronous Reset Logic
    ELSIF rising_edge(clk_in) THEN
        -- Synchronous Logic
    END IF reset_if;
END PROCESS reg_proc;
```

## Combinatorial process

- Combinatorial process **must** have **ALL** sensitivity - `PROCESS(ALL)`
- If you are using VHDL 93, sensitivity list **must** contain every signal read inside the process.

### Latch prevention

- To ensure the logic is purely combinational and not a latch, every signal assigned in the process **must** be assigned a value in all possible branches (i.e., every **IF** needs an **ELSE**, every **CASE** needs a **WHEN OTHERS**)

# Architecture

# FSM

FSMs (Finite State Machines) are the heart of VHDL control logic. Proper implementation ensures speed, resource efficiency, and robustness against "illegal state" hangs.

## Process structure

### Two-Process FSM

Separates combinatorial next-state logic from sequential state registers.

### One-Process FSM

- Recommended on FPGA.
- Results in registered outputs, which is better for timing closure.

## State changes

- **Never** use `rising_edge()` on input signals (data) to control state changes.
- If an edge trigger is required, generate a pulse signal (lasts one clock cycle) and check the level of that pulse.
- When specifing state transitions via **IF** case, and **ELSE** would only point to the active state, then do not specify **ELSE** cause, leave only plain **IF**.

Example:
```vhdl
  -- RIGHT (No ELSE needed for synthesizable FSM)
  IF start = '1' THEN
      next_state <= RUN;
  END IF;
  -- (Assumes default assignment or OTHERS handles IDLE if necessary)
```

## FSM Optimizations and Hacks

### The "Default Assignment" Hack

Instead of assigning outputs in every single **WHEN** branch, assign them **once** at the very top of the process. This ensures no latches are created and makes the state logic much cleaner.

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

In high-reliability designs, a radiation bit-flip could kick an FSM into an undefined state. This attribute forces the compiler to include recovery logic.

| Attribute | Value | Description |
| :--- | :--- | :--- |
| **`fsm_safe_state`** | `"default_state"` | Forces the FSM to return to reset state if it enters an illegal value. |
| **`fsm_encoding`** | `"one_hot"`, `"gray"` | Overrides the compiler's choice for state bit encoding. |

**Example:**

```vhdl
TYPE t_state IS (ST_IDLE, ST_READ, ST_WRITE);
SIGNAL s_state : t_state;

ATTRIBUTE fsm_safe_state : STRING;
ATTRIBUTE fsm_safe_state OF s_state : SIGNAL IS "default_state";
```

### Registered Look-Ahead Outputs

To fix slow combinatorial output logic, calculate the **next** output based on the **next** state within the same clock cycle so that State and Output change at the same clock edge.

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

Use a "Last State" signal to easily detect when the FSM has moved without complex edge-detection.

```vhdl
s_state_changed <= '1' WHEN (s_current_state /= s_last_state) ELSE '0';
```

### Integer-Based FSMs for Math

If an FSM follows a mathematical sequence, using an **INTEGER** range instead of an **ENUMERATION** allows math operators on states.

```vhdl
SIGNAL s_state : INTEGER RANGE 0 TO 15;
-- ...
WHEN 0 TO 5 => 
    s_state <= s_state + 1;
```

## Handling counters and incrementing in FSMs

In VHDL, signal assignments take a clock cycle to update. Handling counters correctly prevents "off-by-one" errors.

### 1. The "Exit Condition" Look-Ahead
Check for `TERMINAL_COUNT - 1` when using signals to avoid staying in a state for one extra cycle.

```vhdl
-- RIGHT: Stays for exactly 10 cycles
IF s_count = g_LIMIT - 1 THEN
    s_count <= 0;
    s_state <= ST_NEXT;
ELSE
    s_count <= s_count + 1;
END IF;
```

### 2. Use a "Terminal Count" (TC) Signal
Calculate terminal counts outside the **CASE** statement to reduce logic depth and improve timing.
```vhdl
s_count_done <= '1' WHEN s_count = g_LIMIT - 1 ELSE '0';
```

### 3. The "State Entry" Reset
Reset counters in the **transition** leading into the counting state to ensure it starts from zero every time the state is entered.

### 4. Variables for "Same-Cycle" Logic
If you must use an updated increment value immediately within the same clock cycle, use a **VARIABLE**.

### FSM Counter Patterns

| Pattern | Best For | Pros | Cons |
| :--- | :--- | :--- | :--- |
| **Signal Increment** | General Purpose | Easy to debug in waveforms. | 1-cycle latency in comparisons. |
| **Variable Increment**| Complex Math | Logic happens in "zero time." | Harder to see in some simulators. |
| **External TC** | High Speed ($F_{max}$) | Best for timing closure. | Requires an extra signal. |

### Counter Overflow Hack
Always use range-limited integers and a reset in the **WHEN OTHERS** branch to prevent permanent hangs.

### The "Shared Counter" Hack
Use one generic counter signal and reset it on every state transition to significantly reduce FPGA area (LUT usage) when multiple states need counting logic.

> **Tip:** Always use `numeric_std` and cast to **UNSIGNED** when incrementing vectors. Avoid the non-standard `std_logic_unsigned` library.

# Appendix

## Attributes

An attribute provides additional information about a specific part of a VHDL description, such as a type, range, signal, or function.

### Syntax

```vhdl
object_name[ signature ]'attribute_name[ ( expression ) ]
```

---

## 1. Global Type Attributes
| Attribute | Result |
| --- | --- |
| `T'Base` | Returns the base type of `T`. |

---

## 2. Scalar Type Attributes
| Attribute | Return Type | Description |
| --- | --- | --- |
| `T'Left` | Same as `T` | The leftmost value of `T`. |
| `T'Right` | Same as `T` | The rightmost value of `T`. |
| `T'Low` | Same as `T` | The least value in `T`. |
| `T'High` | Same as `T` | The greatest value in `T`. |
| `T'Ascending` | `Boolean` | `True` if `T` is an ascending range. |
| `T'Image(x)` | `String` | Textual representation of value `x`. |
| `T'Value(s)` | Base of `T` | Value in `T` represented by string `s`. |

---

## 3. Discrete/Physical Type Attributes
| Attribute | Return Type | Description |
| --- | --- | --- |
| `T'Pos(s)` | `Integer` | Position number of `s` in `T`. |
| `T'Val(x)` | Base of `T` | Value at integer position `x` in `T`. |

> **Note:** Synthesis tools generally discourage navigation attributes for hardware generation.

---

## 4. Array Attributes
| Attribute | Result |
| --- | --- |
| `A'Left(n)` | Leftmost value in index range of dimension `n`. |
| `A'Right(n)` | Rightmost value in index range of dimension `n`. |
| `A'Range(n)` | The specific index range (e.g., `7 downto 0`). |
| `A'Length(n)` | Number of values in the `n`-th index range. |

---

## 5. Signal Attributes
| Attribute | Result |
| --- | --- |
| `S'Delayed(t)` | Signal `S` delayed by `t` time units. |
| `S'Stable(t)` | `True` if no event has occurred on `S` for `t` time units. |
| `S'Event` | `True` if an event occurred on `S` in the current cycle. |
| `S'Last_value` | The previous value of `S` before the last event. |
| `S'Driving` | `True` if the current process is driving `S`. |

---

## 6. Named Entity Attributes
| Attribute | Result |
| --- | --- |
| `E'Path_name` | String describing the full hierarchy path to `E`. |
| `E'Instance_name` | Full path including entity/architecture names. |

---

## 7. Simulation & Delta Control

### 7.1 Process Control
| Keyword | Description |
| :--- | :--- |
| **`POSTPONED`** | Ensures the block executes only during the **last** delta cycle of a simulation time step. |

### 7.2 Delay Modeling
| Keyword | Delay Type | Description |
| :--- | :--- | :--- |
| **`TRANSPORT`** | Transport | Models a wire; all pulses pass through. |
| **`REJECT`** | Inertial | Sets the rejection limit for pulses. |

### 7.3 Simulation Hacks & Testbenching
| Technique | Description |
| :--- | :--- |
| **`WAIT FOR 0 NS;`** | Forces simulator to the next **delta cycle**. |
| **`FORCE`** | Overrides a signal's value (VHDL-2008). |
| **`RELEASE`** | Removes a **`FORCE`** override. |

> **Synthesis Note:** All keywords in Section 7 are **non-synthesizable**.

### 7.4 Driving Attributes
| Attribute | Description |
| :--- | :--- |
| **`S'DRIVING`** | Returns `TRUE` if the current process is contributing a value. |
| **`S'DRIVING_VALUE`** | Returns the value this specific process is trying to drive. |

### 7.5 Hierarchical Reference (External Names)
Access internal signals without ports: `<<SIGNAL .path.to.signal : type>>`

### 7.6 Simulation Termination
Use `FINISH` or `STOP` from `STD.ENV` to end simulations gracefully.

### 7.7 Transaction Tracking (`'TRANSACTION`)
A `BIT` signal that toggles every time an assignment is made, even if the value does not change.

---

## 8. Other VHDL useful stuff

### 8.1 Scoping with `BLOCK`
Creates a local scope for signals to avoid naming interference in large architectures.

### 8.2 The `ALIAS` Keyword
Creates a "nickname" for a slice of a signal or a large vector.
```vhdl
ALIAS a_payload_id : STD_LOGIC_VECTOR(7 DOWNTO 0) IS s_long_bus(119 DOWNTO 112);
```
