# ART Heap Size Selector

适用于 Magisk 和 KernelSU 的模块，用于调整 Android ART 的 Java 堆上限。

## 32 位 Zygote 兼容性

本模块通过 `dalvik.vm.heapsize` 调整堆上限。ROM 同时启动 32 位和 64 位 Zygote 时，两者会读取同一个值。可运行 `adb shell getprop ro.zygote` 检查，`zygote32`、`zygote32_64` 和 `zygote64_32` 均包含 32 位 Zygote。

32 位 Zygote 的虚拟地址空间有限。堆上限设得过大时，ART 启动时可能无法预留所需的连续地址空间，导致系统卡在开机。小米 13 Ultra 的一版 HyperOS 移植 ROM 实测在 **1024 MiB** 时出现此问题，恢复为 ROM 原来的 **512 MiB** 后可以正常启动。

含 32 位 Zygote 的 ROM 建议沿用原有堆上限。若原值为 512 MiB，请在安装时用音量加切到 **512 MiB**，再用音量减确认。**安装器默认选择 1024 MiB，超时也会使用这一档。**
