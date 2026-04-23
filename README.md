# Cognitive Amplification vs Cognitive Delegation in Human-AI Systems

This repository accompanies the paper:

**Cognitive Amplification vs Cognitive Delegation in Human-AI Systems: A Metric Framework**

## Overview

This project introduces a metric framework for distinguishing between two broad regimes of human–AI interaction:

- **Cognitive amplification**, where AI improves hybrid performance while preserving or strengthening human capability.
- **Cognitive delegation**, where AI use progressively displaces human cognitive contribution and may lead to long-term deskilling.

The framework is built around four main quantities:

- **Cognitive Amplification Index (CAI\*)**: collaborative gain relative to the best standalone agent
- **Dependency Ratio (D)**: structural dependence of the hybrid system on the AI component
- **Human Reliance Index (HRI)**: complementary measure of retained human contribution
- **Human Cognitive Drift Rate (HCDR)**: longitudinal change in autonomous human capability under periodic AI-off evaluation

The repository includes the NetLogo simulation used to explore these regimes under controlled conditions.

## Repository contents

Typical contents of this repository include:

- the NetLogo simulation model
- BehaviorSpace experiment configurations
- output files or processed summaries used in the paper
- supporting figures, tables, or analysis artifacts

## Simulation summary

The simulator models agents with structured skill vectors facing heterogeneous tasks of varying difficulty. Agents may choose to rely on AI assistance depending on their baseline reliance regime, task difficulty, and accumulated dependency.

The model includes:

- autonomous learning
- AI-mediated shallow learning
- capability atrophy under insufficient exercise
- dependency reinforcement
- periodic AI-off evaluations
- perturbation and novelty probes
- shifted task-family stress phases

This allows the framework to distinguish not only immediate hybrid performance, but also retained human capability and robustness under changing task conditions.

## Main experimental setup

The paper evaluates three reliance regimes:

- **Full delegation**
- **Minimal AI**
- **Mixed reliance**

and three parameter configurations:

- **P0**: dependency-use-sensitivity = 0.2, atrophy-delta = 0.004
- **P1**: dependency-use-sensitivity = 0.6, atrophy-delta = 0.003
- **P2**: dependency-use-sensitivity = 0.4, atrophy-delta = 0.002

Each condition is evaluated over multiple random seeds, with results aggregated over a final evaluation window.

## Main result

Across the tested configurations, the framework clearly separates degenerate delegation, human-preserving but weakly competitive interaction, and intermediate boundary regimes.

A key result is that **strong hybrid performance does not by itself imply genuine cognitive amplification**. In the reported experiments, mixed reliance often preserves substantially more human capability than full delegation, yet still fails to achieve positive collaborative gain.

A constrained optimization over the atrophy parameter further shows that **even reducing atrophy to zero is not, by itself, sufficient to recover genuine amplification** under the current interaction dynamics.

## Reproducibility

The experiments were implemented in **NetLogo** and executed through **BehaviorSpace**.

To reproduce the reported results:

1. Open the NetLogo model.
2. Load or recreate the BehaviorSpace experiments described in the paper.
3. Run the relevant configurations across the specified random seeds.
4. Aggregate the exported results over the final evaluation window.
5. Recreate tables and plots from the generated outputs.

## Citation

If you use this code or build on this framework, please cite the associated paper.

## License

You may add your preferred license here (for example, MIT, BSD, or another open-source license).

## Contact

**Eduardo Di Santi**  
University of Colorado Boulder

eduardo.disanti@colorado.edu

Repository:  
https://github.com/eduardodisanti/cognitive_amplification_vs_delegation

## Citation

If you use this repository or build on the simulation framework, please cite the associated work. Citation metadata is provided in `CITATION.cff`.

The repository contains the simulation code and supporting materials associated with the manuscript on cognitive amplification versus cognitive delegation in human--AI systems.
