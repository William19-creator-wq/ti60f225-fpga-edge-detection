# FPGA Edge Agent Bootstrap

This is the root entry point for the project control plane. Before operating the Agent, read:

1. `config/AGENTS.md` for durable project rules;
2. `config/AGENT_PROMPT.md` for runtime behavior;
3. `config/PROJECT_CONFIG.yaml` for paths and permissions;
4. `state/PROJECT_STATE.json` and `state/TASK_LEDGER.csv` for current state;
5. `database/README.md` for PostgreSQL requirements.

For a new feature, behavior/interface change, refactor, bug fix, or C++/RTL mapping, read the project’s sole current design standard [v0.2](../AI_Agent_代码可理解性规范_增补提案_v0.2.md) before planning implementation. Use [planning/PLAN_TEMPLATE.md](planning/PLAN_TEMPLATE.md), save `planning/design-<task-id>.md`, and present the overall design before local details. Complete interface/composition checks, Chinese operation sketches, language contracts and bidirectional traceability; stop at `READY_FOR_REVIEW` for explicit approval of the design version, scope and baseline. Do not generate business implementation, executable tests or testbenches before approval, including through messages, prototypes or subagents.

Read [docs/WORKFLOW.md](docs/WORKFLOW.md) for the design-to-hardware handoff. When an approved node is ready for a hardware build, explicitly read [skills/fpga-hardware-node-gate/SKILL.md](skills/fpga-hardware-node-gate/SKILL.md); its current directory is a project document location, not a verified host Skill registration. This entry point references documents that the Agent must actually read; a reference alone does not inject their contents.

The original HDK and reference materials remain read-only. Hardware programming and observation are human-only actions. Extra tools, plugins, MCPs, Skills, drivers, downloads, installations and network actions require a recorded approval before execution.
