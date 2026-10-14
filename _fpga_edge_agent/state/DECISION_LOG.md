# Decision Log

| ID | Decision | Status | Evidence | Owner |
| --- | --- | --- | --- | --- |
| DEC-001 | Exclude Verilog/C++/TinyML learning plan from this Agent | ACCEPTED | User instruction | Human |
| DEC-002 | Use `_fpga_edge_agent` as separate control-plane directory | ACCEPTED | User instruction | Human |
| DEC-003 | Agent may compile; human must program and observe hardware | ACCEPTED | User instruction | Human |
| DEC-004 | Use independent work copy for source modifications | ACCEPTED | User choice | Human |
| DEC-005 | Preserve both Efinity outputs and registered Agent artifacts | ACCEPTED | User choice | Human |
| DEC-006 | PostgreSQL is the only structured database backend | ACCEPTED | User choice | Human |
| DEC-007 | Use local JSONL and static reports; no external telemetry | ACCEPTED | User choice | Human |
| DEC-008 | Retain runtime and audit data fully by default | ACCEPTED | User choice | Human |
| DEC-009 | Use an existing PostgreSQL service; do not provision automatically | ACCEPTED | User choice | Human |
| DEC-010 | Hardware identity must be confirmed before selecting a board profile | ACCEPTED | User choice | Human |

## Pending decisions

2026-09-23 更新：赛题四已确定；用户明确实物尚未确定，先以 VF-Ti60F225 检查环境。详见下方 DEC-011–014，不能把参考样例当实物确认。

- Actual board silk-screen and variant.
- FPGA device/package confirmation.
- Camera model, lane count, adapter and display path.
- Efinity version to use for the first build.
- PostgreSQL database name and least-privilege account.

## 2026-09-23 需求与环境补充

| ID | Decision | Status | Evidence | Owner |
| --- | --- | --- | --- | --- |
| DEC-011 | Project is competition track 4; decompose basic requirements and all six advanced challenges in the plan | ACCEPTED_SCOPE_PLAN | User instruction; corrected competition PDF pp24–26 | Human/Agent |
| DEC-012 | Actual hardware undecided; VF-Ti60F225 is the environment inspection example only | CONFIRMED_REFERENCE_ONLY | User reply 2026-09-23 | Human |
| DEC-013 | Keep VF/V4 hardware profiles separate; no borrowed pin/voltage/DDR assumptions | ENGINEERING_CONSTRAINT | docs/requirements/HARDWARE_AND_TOOLCHAIN_EVIDENCE.md | Agent |
| DEC-014 | TinyML/RISC-V optional for track 4; 60Hz requirement applies to HDMI output | SOURCE_VERIFIED | docs/requirements/TRACK4_REQUIREMENTS.md | Agent |
| DEC-015 | Prefer general Siemens Questa for current protected IP; legitimate university license first; Aldec evaluation is backup. Exact release and actual compatibility remain pending; Icarus only optional plain RTL | SELECTION_ONLY_NOT_APPROVED_TO_INSTALL | tools/SIMULATOR_SELECTION.md; current FIFO protected header; 10.1c failure log | Agent |

## 2026-09-27 借用板与新增相机资料

| ID | Decision | Status | Evidence | Owner |
| --- | --- | --- | --- | --- |
| DEC-016 | User switches intended hardware from the contemplated VF purchase to a borrowed Ti60F225 board; new materials identify DemoBoard V4. Exact physical revision and accessories remain unconfirmed. DEC-012 is historical environment-reference context. | USER_SELECTED_BOARD_FAMILY_PHYSICAL_REVISION_PENDING | User messages 2026-09-27; docs/requirements/V4_CAMERA_SELECTION_20260927.md | Human/Agent |
| DEC-017 | Prefer the V4 provider's matching SC431HAI color MIPI module and cable, based on newly supplied camera-to-HDMI sources and 4-lane CSI configuration. Do not automatically reuse the former VF OV5640 purchase recommendation. | RECOMMENDATION_NOT_PURCHASED_OR_VALIDATED | docs/requirements/V4_CAMERA_SELECTION_20260927.md | Agent |

本次为资料审阅和选型建议，没有变更硬件验收状态、选择可烧写的板卡配置或写入数据库。
