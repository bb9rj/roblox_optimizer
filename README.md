# Roblox Resource Farm Optimizer — Tray Version
A lightweight **Windows tray application** that automatically reduces **CPU**, **GPU**, and **power usage** for running Roblox clients by adjusting **process priority**, **CPU affinity**, and **graphics power preferences**.

This tool works entirely at the **OS level** — it does **not** interact with games, memory, or gameplay.  
It simply limits how many hardware resources Windows gives to each Roblox instance, allowing smoother multitasking and dramatically lower system load.

---

## Features

### CPU Limiting  
- Restricts each Roblox Player instance to **2 cores**, **4 cores**, or **all cores**.  
- Uses Windows *ProcessorAffinity* to keep Roblox within a predictable CPU budget.  
- Default: **2 cores (recommended for stability and low load)**.

### GPU Power Saving  
- Uses Windows **DirectX UserGpuPreferences** to force Roblox into **low-power GPU mode**.  
- Helps reduce unnecessary GPU usage when running many clients.  
- Requires a Roblox restart to take effect.

### Adjustable CPU Priority  
- Choose between:
  - **Idle**
  - **Below Normal** (default)
  - **Normal**
- Lower priority prevents Roblox from starving other system tasks.

### Live Tray Controls  
Right-click the tray icon to toggle:
- CPU limiting
- GPU power saving  
- Core count
- Priority level  
- Silent Mode  
- Restore defaults  
- Exit

### Automatic Application  
A background timer applies optimization settings every **3 seconds** to any newly-opened Roblox instances.

### 100% Safe OS-Level Optimization  
- Does **not** modify Roblox files  
- Does **not** interact with gameplay  
- Does **not** hook or inject into any process  
- Purely manages Windows scheduling & power settings

---

## Why This Lowers CPU Usage So Much
Modern Roblox clients spread their rendering and UI load across **all CPU cores** by default.  
When running many clients at once, this causes:

- heavy context switching  
- high background render activity  
- excessive CPU heat  
- poor system responsiveness  

By restricting each client to **2–4 cores** and lowering the priority, Windows schedules them far more efficiently:

- No render thread thrashing  
- No unnecessary multi-core usage  
- Much smoother multitasking  
- CPU usage often drops from **80–100% → 20–40%**

Because the script only changes **how many CPU/GPU resources Windows allocates**, internal game timers and logic run normally.

---

## Settings Overview

### `OptCPU`
Enable or disable CPU limiting.  
```powershell
$global:OptCPU = $true
