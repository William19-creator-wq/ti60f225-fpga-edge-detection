# Full M0-M5 DDR frame-buffer candidate 2026-10-29

Full candidate contains official Efinity DDR3 Soft Controller5.16, 64 RAW8 source slots, last60-frame history, freeze/same-source M0-M5 reprocessing, timestamp playback/pause/step and paired960x540 A/B comparison. Full Canny M5 worker is enabled. This supersedes M5_OFF trial scope; no physical function pass is yet claimed for this bitstream.

Changes since source-reviewv3: equivalent shared OSD glyph decode; Canny256-entry tag register bank replaced by one synchronous RAM. Data/dirty writeback/flush/abort behavior passes434 independent cache operations against a backing model. Cache microbenchmark186085ns old vs191205ns new; this is not a fullM5 FPS measurement. HS-based source line ends preserve CSI DE bubbles and pass full1080p capture/commit/read/FIFO/pixel ordering and short-frame rejection.

Build tag_ram_ordered_build: map/interface/PNR/pgm all exit0, XLR54418/60800,DSP160/160,RAM252/256. Final17 setup/17hold relationships pass, minimumsetup0.072ns,hold0.026ns. Generated DDR IO clock constraints corrected;25MHz reference explicit40ns.

Hardware gate: actual camera/history60 were observed only on prior smaller M5_OFF trial. Fullcandidate hardware, freeze/playback/A-B, same-source Canny reprocessing, performance/stability and full reference DDR integrity remain unverified. Five-hour deadline missed; complete release not claimed.

Controls: mode long0.8s toggles menu(S); mode short selects I0..I6 in menu or image M0..M5 outside. +/- adjusts. I2 stateP0live/P1freeze/P2playonce/P3pause; I3history seek/step; I4Aindex/I5Bindex/I6comparetoggle. F64sourceID,Hhistorycount,Eerror; all numeric fields hex. DefaultA=B0; chooseB59 with one minus from0 onI5 to compare endpoints.

Keep ReadAhead20261028 bit and smaller hs_readback_function_build M5_OFF trial as rollback. JTAG temporary only, noFlash.
