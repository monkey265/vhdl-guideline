#set document(
  title: "VHDL Coding Guideline",
  author: "Hardware Design Guideline",
)

#set page(
  paper: "a4",
  margin: (x: 2cm, top: 2cm, bottom: 2cm),
  header: context {
    if here().page() > 1 {
      text(size: 8.5pt, fill: rgb("#64748b"), font: "Liberation Sans")[
        VHDL Coding Guideline & Best Practices
        #h(1fr)
        #datetime.today().display("[year]-[month]-[day]")
      ]
      v(-4pt)
      line(length: 100%, stroke: 0.4pt + rgb("#cbd5e1"))
    }
  },
  footer: context {
    text(size: 8.5pt, fill: rgb("#64748b"), font: "Liberation Sans")[
      #line(length: 100%, stroke: 0.4pt + rgb("#cbd5e1"))
      #v(2pt)
      #h(1fr)
      Page #here().page() of #counter(page).final().at(0)
    ]
  }
)

#set text(
  font: "Liberation Sans",
  size: 9.5pt,
  fill: rgb("#1e293b"),
  lang: "en"
)

#set par(
  justify: true,
  leading: 0.6em
)

#set heading(numbering: "1.1")

#show heading: it => block(
  sticky: true,
  breakable: false,
  [
    #set text(font: "Liberation Sans", fill: rgb("#0f2d59"), weight: "bold")
    #v(0.6em)
    #it
    #v(0.25em)
  ]
)

#show heading.where(level: 1): it => block(
  sticky: true,
  breakable: false,
  [
    #v(0.8em)
    #text(size: 13.5pt, fill: rgb("#0f2d59"), weight: "bold", it)
    #v(0.2em)
    #line(length: 100%, stroke: 0.8pt + rgb("#cbd5e1"))
    #v(0.3em)
  ]
)

#show heading.where(level: 2): it => block(
  sticky: true,
  breakable: false,
  [
    #text(size: 11pt, fill: rgb("#0f2d59"), weight: "bold", it)
  ]
)

#show heading.where(level: 3): it => block(
  sticky: true,
  breakable: false,
  [
    #text(size: 9.8pt, fill: rgb("#0f2d59"), weight: "bold", it)
  ]
)

#set raw(theme: "vhdl_theme.tmTheme", syntaxes: "vhdl.sublime-syntax")
#show raw: set text(font: "Liberation Mono", size: 8.5pt)
#show raw.where(block: true): block.with(
  fill: rgb("#f8fafc"),
  inset: (x: 10pt, y: 7pt),
  radius: 4pt,
  stroke: 0.5pt + rgb("#cbd5e1"),
  width: 100%,
  breakable: false
)

#show raw.where(block: false): box.with(
  fill: rgb("#f1f5f9"),
  inset: (x: 3pt, y: 1.5pt),
  radius: 3pt,
  baseline: 0%
)

// Callout blocks
#let callout(title: none, color: rgb("#2563eb"), fill: rgb("#eff6ff"), body) = {
  block(
    fill: fill,
    stroke: (left: 3pt + color),
    inset: (x: 10pt, y: 7pt),
    radius: (right: 4pt),
    width: 100%,
    breakable: false,
    [
      #if title != none [
        #text(weight: "bold", fill: color)[#title]
        #v(1.5pt)
      ]
      #body
    ]
  )
}

#let tip(body) = callout(title: "Tip", color: rgb("#059669"), fill: rgb("#ecfdf5"), body)
#let note(body) = callout(title: "Note", color: rgb("#2563eb"), fill: rgb("#eff6ff"), body)
#let warning(body) = callout(title: "Synthesis Note", color: rgb("#d97706"), fill: rgb("#fffbeb"), body)

// Title block
#align(center)[
  #v(1em)
  #text(size: 24pt, weight: "bold", fill: rgb("#0f2d59"))[VHDL Coding Guideline]
  #v(6pt)
  #text(size: 11.5pt, fill: rgb("#475569"))[Hardware Design Rules, Synthesizable Best Practices, and Reference Appendix]
  #v(1.2em)
]

#outline(indent: 1.5em, depth: 2)

#pagebreak()

= Basics

== Rule Terminology & Severity Levels
- *Must*: Non-negotiable requirement.
- *Should* and *Permitted*: Recommended best practice.
- *Tip*: Suggested optimization or pattern.

== Naming & Style Rules
- *Entity names* should be in `lowercase`.
- *Keywords* *must* be in *ALL CAPS*.
- *Functions and procedures* are permitted to be in `lowercase`.
- *Signals and variables* *must* be `lowercase`.
- *Signals* should have prefix `s_`.
- *Variables* should have prefix `v_`.
- *STD* and provided standard library functions, procedures, typecasts, etc. should be *ALL CAPS*; custom datatypes, procedures, and functions can be `lowercase`.
- *Created libraries* *must not* be named `work`.
- *IF / FOR / WHILE* statements should be named with descriptive labels.

= Ports and Generics

- *Generics* should have the prefix `g_`.

```vhdl
GENERIC (
  g_num_tx : INTEGER
);
```

- *Port declarations* should contain comments that clearly indicate categories such as inputs, outputs, debug signals, etc.

#pagebreak()

= Clock and Reset

- *Clock* should be the first specified port in the port list.
- *Reset* should be the second specified port in the port list.
- *Reset* should have its active value and synchronicity explicitly documented.
- *Reset naming* should reflect both synchronicity and active value:
  - `areset_n` / `arst_n` $->$ Asynchronous reset, active low (negated)
  - `rst_n` $->$ Synchronous reset, active low (negated)
- *Reset* should be active low.

#block(breakable: false)[
*Example:*

```vhdl
PORT (
    -- Inputs
    clk_in      : IN STD_LOGIC;
    rst_n_in    : IN STD_LOGIC; -- synchronous reset, active low
    areset_n_in : IN STD_LOGIC  -- asynchronous reset, active low
);
```
]

= Process

- Processes *must* be named with a label.
- The process label should follow the format `something_proc`.

#block(breakable: false)[
*Example:*

```vhdl
main_proc: PROCESS(clk_in)
BEGIN
    -- something
END PROCESS main_proc;
```
]

- Clocked modules should contain processes sensitive *only* to clock and reset.
- Combinatorial modules should use a process with the sensitivity list `ALL`.

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

== Combinatorial Process
- Combinatorial processes *must* have `ALL` sensitivity: `PROCESS(ALL)`.
- If using VHDL-93, the sensitivity list *must* explicitly contain every signal read inside the process body.

== Latch Prevention
- To ensure logic is purely combinational and does not synthesize unintentional latches, every signal assigned in the process *must* be assigned a value in all possible branches (i.e., every `IF` needs an `ELSE`, and every `CASE` needs a `WHEN OTHERS`).

#pagebreak()

= Architecture & Finite State Machines (FSM)

FSMs (Finite State Machines) are the heart of VHDL control logic. Proper implementation ensures high speed, resource efficiency, and robustness against illegal state hangs.

== Process Structure

=== Two-Process FSM
Separates combinatorial next-state logic from sequential state registers into two distinct processes.

=== One-Process FSM
- Recommended for FPGA targets.
- Results in registered outputs, which is beneficial for timing closure.

== State Changes
- *Never* use `rising_edge()` on input (data) signals to control state changes.
- If an edge trigger is required, generate a single-cycle pulse signal and check the level of that pulse.
- When specifying state transitions using `IF` conditions where an `ELSE` would only point to the currently active state, omit the `ELSE` branch and leave only a plain `IF`.

#block(breakable: false)[
*Example:*

```vhdl
-- RIGHT (No ELSE needed for synthesizable FSM)
IF start = '1' THEN
    next_state <= RUN;
END IF;
-- (Assumes default assignment or OTHERS handles IDLE if necessary)
```
]

== FSM Optimizations and Hacks

=== The "Default Assignment" Hack
Instead of assigning outputs in every single `WHEN` branch, assign default values *once* at the very top of the process. This guarantees no latches are inferred and significantly simplifies state logic.

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

=== The "Safe FSM" Attribute
In high-reliability designs, radiation-induced single-event upsets (SEUs) or bit-flips can kick an FSM into an undefined state. Synthesis attributes force the compiler to generate state recovery logic.

#table(
  columns: (1.5fr, 1.5fr, 3.5fr),
  align: (left + horizon, left + horizon, left + horizon),
  inset: (x: 6pt, y: 5pt),
  fill: (col, row) => if row == 0 { rgb("#e2e8f0") } else { none },
  stroke: (x, y) => if y == 0 { (bottom: 1pt + rgb("#94a3b8")) } else { (bottom: 0.5pt + rgb("#e2e8f0")) },
  table.header([*Attribute*], [*Value*], [*Description*]),
  [`fsm_safe_state`], [`"default_state"`], [Forces the FSM to return to reset state if it enters an illegal value.],
  [`fsm_encoding`], [`"one_hot"`, `"gray"`], [Overrides the compiler's automatic choice for state bit encoding.],
)

*Example:*

```vhdl
TYPE t_state IS (ST_IDLE, ST_READ, ST_WRITE);
SIGNAL s_state : t_state;

ATTRIBUTE fsm_safe_state : STRING;
ATTRIBUTE fsm_safe_state OF s_state : SIGNAL IS "default_state";
```

=== Registered Look-Ahead Outputs
To eliminate slow combinatorial output paths, calculate the *next* output based on the *next* state within the same clock cycle so that both State and Output update simultaneously at the clock edge.

```vhdl
CASE s_current_state IS
    WHEN ST_IDLE =>
        IF s_start = '1' THEN
            s_current_state <= ST_RUN;
            s_output_reg    <= '1'; -- Look ahead
        END IF;
END CASE;
```

=== The "Transition Bit" Hack
Use a "Last State" register to cleanly detect state transitions without constructing complex combinatorial edge detectors:

```vhdl
s_state_changed <= '1' WHEN (s_current_state /= s_last_state) ELSE '0';
```

=== Integer-Based FSMs for Math
If an FSM progresses through an arithmetic sequence, declaring states as an `INTEGER RANGE` instead of an `ENUMERATION` enables direct mathematical operations on state variables:

```vhdl
SIGNAL s_state : INTEGER RANGE 0 TO 15;
-- ...
WHEN 0 TO 5 => 
    s_state <= s_state + 1;
```

== Handling Counters and Incrementing in FSMs

In VHDL, sequential signal assignments take one clock cycle to take effect. Correct counter management prevents off-by-one errors.

=== Exit Condition Look-Ahead
Check against `TERMINAL_COUNT - 1` when using registered signals to prevent lingering in a state for an unintended extra cycle.

```vhdl
-- RIGHT: Stays for exactly 10 cycles
IF s_count = g_LIMIT - 1 THEN
    s_count <= 0;
    s_state <= ST_NEXT;
ELSE
    s_count <= s_count + 1;
END IF;
```

=== Terminal Count (TC) Signal
Calculate terminal count comparisons outside the `CASE` statement to reduce logic depth and improve maximum clock frequency ($F_max$).

```vhdl
s_count_done <= '1' WHEN s_count = g_LIMIT - 1 ELSE '0';
```

=== State Entry Reset
Reset counters during the *transition* leading into the counting state so that counting always starts cleanly from zero upon entry.

=== Variables for Same-Cycle Logic
If updated increment values must be evaluated immediately within the exact same clock cycle, use a `VARIABLE`.

=== Counter Patterns Comparison

#table(
  columns: (1.5fr, 1.3fr, 2.2fr, 2.2fr),
  align: (left + horizon, left + horizon, left + horizon, left + horizon),
  inset: (x: 6pt, y: 5pt),
  fill: (col, row) => if row == 0 { rgb("#e2e8f0") } else { none },
  stroke: (x, y) => if y == 0 { (bottom: 1pt + rgb("#94a3b8")) } else { (bottom: 0.5pt + rgb("#e2e8f0")) },
  table.header([*Pattern*], [*Best For*], [*Pros*], [*Cons*]),
  [*Signal Increment*], [General Purpose], [Easy to debug in simulation waveforms.], [1-cycle latency in comparisons.],
  [*Variable Increment*], [Complex Math], [Logic evaluates in "zero time."], [Harder to observe in some simulators.],
  [*External TC*], [High Speed ($F_max$)], [Optimal for timing closure.], [Requires an additional signal.],
)

=== Counter Overflow Prevention
Always declare range-bounded integers and include an explicit reset assignment in the `WHEN OTHERS` branch to prevent permanent deadlocks.

=== Shared Counter Optimization
Instantiate a single generic counter signal and reset it across state transitions to substantially decrease FPGA logic utilization (LUT count) when multiple states require counting sequences.

#tip[
Always use `ieee.numeric_std` and cast vectors to `UNSIGNED` when performing arithmetic. Avoid legacy, non-standard libraries like `std_logic_unsigned`.
]

#pagebreak()

= Appendix: VHDL Language Reference

== Attributes

An attribute provides additional information about a specific element in a VHDL description, such as a type, range, signal, or subprogram.

=== Attribute Syntax

```vhdl
object_name[ signature ]'attribute_name[ ( expression ) ]
```

=== Global Type Attributes

#table(
  columns: (2fr, 4fr),
  align: (left + horizon, left + horizon),
  inset: (x: 6pt, y: 5pt),
  fill: (col, row) => if row == 0 { rgb("#e2e8f0") } else { none },
  stroke: (x, y) => if y == 0 { (bottom: 1pt + rgb("#94a3b8")) } else { (bottom: 0.5pt + rgb("#e2e8f0")) },
  table.header([*Attribute*], [*Result*]),
  [`T'Base`], [Returns the base type of type `T`.],
)

=== Scalar Type Attributes

#table(
  columns: (1.5fr, 1.5fr, 3.5fr),
  align: (left + horizon, left + horizon, left + horizon),
  inset: (x: 6pt, y: 5pt),
  fill: (col, row) => if row == 0 { rgb("#e2e8f0") } else { none },
  stroke: (x, y) => if y == 0 { (bottom: 1pt + rgb("#94a3b8")) } else { (bottom: 0.5pt + rgb("#e2e8f0")) },
  table.header([*Attribute*], [*Return Type*], [*Description*]),
  [`T'Left`], [Same as `T`], [The leftmost value of `T`.],
  [`T'Right`], [Same as `T`], [The rightmost value of `T`.],
  [`T'Low`], [Same as `T`], [The least value in `T`.],
  [`T'High`], [Same as `T`], [The greatest value in `T`.],
  [`T'Ascending`], [`Boolean`], [`True` if `T` is an ascending range.],
  [`T'Image(x)`], [`String`], [Textual string representation of value `x`.],
  [`T'Value(s)`], [Base of `T`], [Value in `T` represented by string `s`.],
)

=== Discrete & Physical Type Attributes

#table(
  columns: (1.5fr, 1.5fr, 3.5fr),
  align: (left + horizon, left + horizon, left + horizon),
  inset: (x: 6pt, y: 5pt),
  fill: (col, row) => if row == 0 { rgb("#e2e8f0") } else { none },
  stroke: (x, y) => if y == 0 { (bottom: 1pt + rgb("#94a3b8")) } else { (bottom: 0.5pt + rgb("#e2e8f0")) },
  table.header([*Attribute*], [*Return Type*], [*Description*]),
  [`T'Pos(s)`], [`Integer`], [Position number of `s` in type `T`.],
  [`T'Val(x)`], [Base of `T`], [Value at integer position `x` in type `T`.],
)

#note[
Synthesis tools generally discourage the use of value navigation attributes for physical hardware generation.
]

=== Array Attributes

#table(
  columns: (2fr, 4fr),
  align: (left + horizon, left + horizon),
  inset: (x: 6pt, y: 5pt),
  fill: (col, row) => if row == 0 { rgb("#e2e8f0") } else { none },
  stroke: (x, y) => if y == 0 { (bottom: 1pt + rgb("#94a3b8")) } else { (bottom: 0.5pt + rgb("#e2e8f0")) },
  table.header([*Attribute*], [*Result*]),
  [`A'Left(n)`], [Leftmost value in the index range of dimension `n`.],
  [`A'Right(n)`], [Rightmost value in the index range of dimension `n`.],
  [`A'Range(n)`], [The specific index range (e.g., `7 downto 0`).],
  [`A'Length(n)`], [Total number of values in the `n`-th dimension index range.],
)

=== Signal Attributes

#table(
  columns: (2fr, 4fr),
  align: (left + horizon, left + horizon),
  inset: (x: 6pt, y: 5pt),
  fill: (col, row) => if row == 0 { rgb("#e2e8f0") } else { none },
  stroke: (x, y) => if y == 0 { (bottom: 1pt + rgb("#94a3b8")) } else { (bottom: 0.5pt + rgb("#e2e8f0")) },
  table.header([*Attribute*], [*Result*]),
  [`S'Delayed(t)`], [Signal `S` delayed by simulation time units `t`.],
  [`S'Stable(t)`], [`True` if no event has occurred on `S` for time duration `t`.],
  [`S'Event`], [`True` if an event occurred on `S` in the current cycle.],
  [`S'Last_value`], [The previous value of `S` prior to the most recent event.],
  [`S'Driving`], [`True` if the current process is actively driving signal `S`.],
)

=== Named Entity Attributes

#table(
  columns: (2fr, 4fr),
  align: (left + horizon, left + horizon),
  inset: (x: 6pt, y: 5pt),
  fill: (col, row) => if row == 0 { rgb("#e2e8f0") } else { none },
  stroke: (x, y) => if y == 0 { (bottom: 1pt + rgb("#94a3b8")) } else { (bottom: 0.5pt + rgb("#e2e8f0")) },
  table.header([*Attribute*], [*Result*]),
  [`E'Path_name`], [String describing the full hierarchical design path to `E`.],
  [`E'Instance_name`], [Full hierarchical path including entity and architecture names.],
)

== Simulation & Delta Control

=== Process Control

#table(
  columns: (2fr, 4fr),
  align: (left + horizon, left + horizon),
  inset: (x: 6pt, y: 5pt),
  fill: (col, row) => if row == 0 { rgb("#e2e8f0") } else { none },
  stroke: (x, y) => if y == 0 { (bottom: 1pt + rgb("#94a3b8")) } else { (bottom: 0.5pt + rgb("#e2e8f0")) },
  table.header([*Keyword*], [*Description*]),
  [`POSTPONED`], [Ensures the block executes only during the *last* delta cycle of a simulation time step.],
)

=== Delay Modeling

#table(
  columns: (1.5fr, 1.5fr, 3.5fr),
  align: (left + horizon, left + horizon, left + horizon),
  inset: (x: 6pt, y: 5pt),
  fill: (col, row) => if row == 0 { rgb("#e2e8f0") } else { none },
  stroke: (x, y) => if y == 0 { (bottom: 1pt + rgb("#94a3b8")) } else { (bottom: 0.5pt + rgb("#e2e8f0")) },
  table.header([*Keyword*], [*Delay Type*], [*Description*]),
  [`TRANSPORT`], [Transport], [Models ideal wire delay; all signal pulses pass through regardless of width.],
  [`REJECT`], [Inertial], [Specifies pulse rejection width threshold for inertial delay.],
)

=== Simulation Hacks & Testbenching

#table(
  columns: (2fr, 4fr),
  align: (left + horizon, left + horizon),
  inset: (x: 6pt, y: 5pt),
  fill: (col, row) => if row == 0 { rgb("#e2e8f0") } else { none },
  stroke: (x, y) => if y == 0 { (bottom: 1pt + rgb("#94a3b8")) } else { (bottom: 0.5pt + rgb("#e2e8f0")) },
  table.header([*Technique*], [*Description*]),
  [`WAIT FOR 0 NS;`], [Forces simulator to advance to the next *delta cycle*.],
  [`FORCE`], [Overrides a signal's value directly during simulation (VHDL-2008).],
  [`RELEASE`], [Removes a previously applied `FORCE` override.],
)

#warning[
All keywords and constructs in this simulation section are strictly *non-synthesizable* and intended exclusively for testbench verification.
]

=== Driving Attributes

#table(
  columns: (2fr, 4fr),
  align: (left + horizon, left + horizon),
  inset: (x: 6pt, y: 5pt),
  fill: (col, row) => if row == 0 { rgb("#e2e8f0") } else { none },
  stroke: (x, y) => if y == 0 { (bottom: 1pt + rgb("#94a3b8")) } else { (bottom: 0.5pt + rgb("#e2e8f0")) },
  table.header([*Attribute*], [*Description*]),
  [`S'DRIVING`], [Returns `TRUE` if the current process is actively contributing a value to `S`.],
  [`S'DRIVING_VALUE`], [Returns the value this specific process is attempting to drive onto `S`.],
)

=== Hierarchical Reference (External Names)
Access internal signals without routing intermediate ports:
```vhdl
<<SIGNAL .path.to.signal : type>>
```

=== Simulation Termination
Use `FINISH` or `STOP` from `STD.ENV` to terminate simulations cleanly without assertion failures:
```vhdl
USE std.env.all;
-- ...
finish;
```

=== Transaction Tracking (`'TRANSACTION`)
A `BIT` signal attribute that toggles whenever a signal assignment is performed, even if the value itself does not change.

== Other Useful VHDL Features

=== Scoping with `BLOCK`
Creates an isolated local scope for signals to eliminate naming collisions and partition large architectures cleanly.

=== The `ALIAS` Keyword
Defines a concise nickname for a slice of a wide vector or bus:

```vhdl
ALIAS a_payload_id : STD_LOGIC_VECTOR(7 DOWNTO 0) IS s_long_bus(119 DOWNTO 112);
```
