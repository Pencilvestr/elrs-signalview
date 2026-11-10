# Performance — 0.5.0

[Back to README](../README.md)

History review uses a bounded 901-record archive and at most 32 render points. Acquisition remains rate-limited, and valid graph geometry is reused while reviewing. No raw-sample log or SD writes are added.

Native EdgeTX 2.12.5 tests of the executable-equivalent bench candidate found the following combined acquisition/render costs. Percentages measure Lua instruction-budget consumption, not total radio CPU usage or hardware latency.

| Radio | Live mean / maximum | Moving-review mean / maximum |
| --- | ---: | ---: |
| TX16S MK3 | 42.7% / 53% | 56.8% / 70% |
| TX16S | 41.3% / 51% | 55.8% / 69% |
| TX15 | 41.3% / 51% | 55.8% / 69% |
| NV14 | 42.0% / 52% | 56.6% / 70% |
| PA01 | 41.2% / 51% | 55.8% / 69% |

The MK3's retained test VM heap reached about 323 KiB after rendering, versus about 185 KiB for 0.4.0 under the earlier matched test. VM figures include the common observer and are not total radio RAM. The archive remained capped and retained heap was essentially stable between the first full buffer and a further 15 simulated minutes. These accelerated checks do not represent a continuous 30-minute hardware endurance test.

A separate stationary-window experiment during development reduced mean review work from 62.00% to 55.08% of the instruction budget by preserving geometry caches. Its initial-render maximum was 63%, versus 62% before the optimization. Those measurements describe that experiment, not the mixed scrolling workload above.

The maintainer reported three separate 10-minute MK3 bench tests without issues on EdgeTX 2.12.5 and internal ELRS 4.0.0. Receiver identity and in-flight testing were not supplied. The release changes only version/comment text from the bench-tested source; [verification](verification.json) records provenance and current release checks.

Earlier measurements remain in [the 0.2.0 review](PERFORMANCE-0.2.0.md) and [its results](performance-results.json). They should not be presented as current-release measurements.
