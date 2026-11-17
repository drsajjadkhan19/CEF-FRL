# CEF-FRL: Channel-Aware Admission Control for Client-Edge-Fog Federated Reinforcement Learning

MATLAB code that reproduces the results and figures of the paper

> S. A. Khan, S. Eken, K. Kucuk, M. Asshad, N. Ashraf, K. Yahya, and S. A. Chaudhry,
> "Channel-Aware Admission Control for Client-Edge-Fog Federated Reinforcement Learning
> in 6G Embodied IoT Networks," *Computers, Materials & Continua*, 2026.

CEF-FRL admits a client update to aggregation only when its sub-THz link can deliver it
within the round budget (CFAA), weights the admitted updates by link reliability, data skew
and starvation, compensates coverage gaps (AGSC), and trains a dual-timescale actor-critic
with separate fast and slow value heads (DTRD). The code evaluates the framework at two levels
that share the same channel traces, parameters and model payload:

| Level | What it measures | Paper |
|---|---|---|
| Communication level | Round closure, deadline compliance, radio and device energy, uplink traffic, rate models, blockage sweep, sensitivity | Sections 6.2 to 6.4, Tables 3 and 4, Figures 2 to 5 |
| Learning level | End-to-end federated actor-critic navigation with ten robots, six baselines, four ablations, timescale and reward-weight sweeps, uneven blockage | Sections 6.5 to 6.7, Table 5, Figures 6 and 7 |

## Requirements

* MATLAB R2021a or later. No toolboxes are needed.
* GNU Octave 8 or later can run the simulations (`run_quick_check`, and `run_all` up to
  the figure step); drawing the figures uses MATLAB graphics functions.
* Optional: Python 3 with NumPy, only to regenerate the channel traces in `data/`.

## Quick start

Clone the repository, open MATLAB in its root folder, and run one of the three scripts.

| Script | Purpose | Run time |
|---|---|---|
| `plot_paper_figures` | Redraws Figures 2 to 7 from the data reported in the paper (`paper_results/`) | seconds |
| `run_quick_check` | Runs every stage on a reduced scale to check the installation | a few minutes |
| `run_all` | Reproduces all results and figures from scratch | several hours |

```matlab
>> plot_paper_figures      % figures/*.eps from the published data
>> run_quick_check         % results/quick_check/
>> run_all                 % results/ and figures/
```

`run_all` writes

```
results/communication_level.mat    all communication-level results
results/communication_level.txt    summary of Tables 3 and 4, blockage sweep, sensitivity
results/learning/*.mat             one file per (setting, method, seed)
results/learning_level.txt         summary of Table 5, timescale and weight sweeps, uneven blockage
results/paper_fig_data.json        Monte Carlo means and 95% confidence intervals
figures/*.eps                      Figures 2 to 7
```

The learning-level campaign saves every run to its own file. If MATLAB is closed, run
`run_all` again and it continues from the last completed run.

## Reproducibility

* Every random stream is seeded (`cfg.seed` in `src/communication/cef_frl_config.m`,
  `c.seed` in `src/learning/ac_config.m`), so repeated runs on the same platform give
  identical results.
* The communication level averages 100 independent seeds (20 per sweep point); the
  channel traces stay fixed and each seed resamples the learning noise. The learning level
  uses 10 seeds per method (5 per sweep point and in the uneven-blockage setting).
* Figures show Monte Carlo means; shaded bands and error bars are 95% confidence intervals.
* The published numbers were produced with GNU Octave. MATLAB uses a different random
  number generator, so a MATLAB run gives slightly different values within the reported
  confidence intervals, and the same conclusions. `paper_results/paper_fig_data.json`
  holds the exact data behind the published figures.

## Repository structure

```
run_all.m                 full reproduction
run_quick_check.m         reduced-scale check
plot_paper_figures.m      figures from the published data
data/telemetry_v3.csv     sub-THz channel traces (5 clients, 1000 frames of 10 ms)
paper_results/            data behind the published figures
src/channel/              path loss, absorption, blockage, rate models, trace checks
src/communication/        CEF-FRL and baselines at the communication level
src/learning/             federated actor-critic, navigation task, campaigns
src/figures/              figure data export and plotting
src/common/               seeding, statistics and utilities
tools/generate_telemetry.py   generator of the channel traces
```

## Channel traces

`data/telemetry_v3.csv` contains, for five clients over 1000 frames of 10 ms, the distance,
path loss, absorption, shadowing, blockage state, SINR, Shannon capacity, upload delay and
device energy at 0.3 THz with 2 GHz bandwidth. The path loss exponent (2.1) and shadowing
(2.8 dB) follow measurements at 142 GHz, the blockage dwell (375 ms) follows measurements
at 156 GHz, and the training cycle time and CPU load of the edge device follow measured
NVIDIA Jetson Nano data. `run_communication_level` checks the traces against 19 closed-form
consistency tests before any experiment.

To regenerate the file, which gives an identical copy:

```bash
python3 tools/generate_telemetry.py --output data/telemetry_v3.csv
```

## Main parameters

| Parameter | Value | File |
|---|---|---|
| Carrier, bandwidth | 0.3 THz, 2 GHz | `cef_frl_config.m` |
| Strict bound D_s, admission budget D | 1 ms, 2 ms | `cef_frl_config.m` |
| Admission floor, staleness cap | 4 dB, 5 rounds | `cef_frl_config.m` |
| Model payload | 2.10 Mbit (FP16) | both configs |
| Robots, rounds, episodes per round | 10, 300, 2 | `ac_config.m` |
| Actor-critic | two hidden layers of 354 tanh units, 131,341 parameters | `ac_config.m` |
| Slow-head period N_s, DTRD weight lambda | 10, 0.5 | `ac_config.m` |

## Citation

If you use this code, please cite the paper above.

## License

MIT License. See `LICENSE`.
