+++
date = "2025-02-08T12:00:00+08:00"
title = "在群晖 DSM 7.2.1 上开启 Video Station 硬件直通"
draft = false
toc = true
comments = true
+++

本文记录在**群晖 DSM 7.2.1** 上，为 **Video Station** 启用**硬件转码**（硬件直通）的完整流程。我实际采用的步骤分为三步：先激活 Advanced Media Extensions，再修复 DTS/EAC3/TrueHD 支持，最后用 VA-API 开启硬解。

---

## 前置条件

- **系统**：DSM 7.2.1，x86_64（ARM 不适用下文中的 AME 补丁）。
- **套件**：在套件中心先安装 **Video Station** 和 **Advanced Media Extensions（AME）**。
- **SSH**：能以管理员账号登录 DSM 并执行 `sudo -i` 取得 root。
- **硬件**：CPU/核显支持 VA-API 硬件解码且已安装对应的驱动。

---

## 第一步：激活 Advanced Media Extensions

AME 未自动授权时，需要运行社区补丁脚本激活后，才能正常使用 HEVC 等解码及后续的硬件转码。本步参考自 [我不是矿神：黑群晖一键修复（root、AME、DTS、转码等）](https://imnks.com/385.html)。

- **DSM 7.1** 与 **DSM 7.2** 的 AME 版本不同，**脚本不通用**；7.2 对应 AME 3.1.0-3005，使用 7.2 专用脚本。
- 仅适用于 **x86_64**，不支持 ARM。
- 激活过程会下载官方解码包，耗时可能较长，需耐心等待。若一直无法激活，可先卸载 AME、重启系统后再重新安装并再次执行脚本。

**操作步骤：**

1. SSH 登录群晖，执行 `sudo -i` 切换为 root。
2. 执行以下命令：

   ```bash
   # DSM 7.2，AME 3.1.0-3005
   curl -L http://code.imnks.com/ame3patch/ame72-3005.py | python
   ```

3. 脚本执行完毕且无报错即表示 AME 已激活。若出现 **MD5 校验失败**，多为 AME 版本与脚本不匹配，可尝试按社区说明修改脚本中的 MD5 判断或换用对应版本补丁。

---

## 第二步：修复 VideoStation 对 DTS、EAC3 和 TrueHD 的支持

群晖自带的 Video Station 对 DTS、EAC3、TrueHD 等音频格式支持有限。通过 [VideoStation-FFMPEG-Patcher](https://github.com/AlexPresso/VideoStation-FFMPEG-Patcher) 用 SynoCommunity 的 ffmpeg 替换相关组件，可开启这些格式的转码支持。本步参考该项目的 [README](https://github.com/AlexPresso/VideoStation-FFMPEG-Patcher?tab=readme-ov-file)。

**依赖：**

- 提前在套件中心安装 **SynoCommunity ffmpeg**（4.x / 5.x / 6.x / 7.x 均可，建议 6，脚本用 `-v` 指定版本）。

**支持场景（摘自项目说明）：**

- (DTS 或 EAC3 或 TrueHD) + 任意非 HEVC 标准视频：✅
- 无 DTS/EAC3/TrueHD + HEVC：✅
- (DTS 或 EAC3 或 TrueHD) + HEVC：✅（由社区贡献支持）

**操作步骤：**

1. SSH 登录并 `sudo -i` 取得 root。
2. 执行 Patcher（按你安装的 ffmpeg 版本修改 `-v`，例如 4、5、6、7）：

   默认使用 ffmpeg4 的写法：

   ```bash
   curl https://raw.githubusercontent.com/AlexPresso/VideoStation-FFMPEG-Patcher/main/patcher.sh | bash
   ```

3. 每次**更新 Video Station、AME 或 DSM** 后，建议重新执行一次 patcher（先 unpatch 再 patch，见项目 README 的 Update procedure）。

---

## 第三步：使用 VA-API 开启硬解

本步让 Video Station 通过 **VA-API** 调用核显/独显做硬件解码与转码。要点是：AME 自带的 `ffmpeg41` 才支持 VA-API，但 **Codec Pack** 里的 ffmpeg 硬解有问题，需要换成 SynoCommunity 的 ffmpeg，并对 Video Station 的若干文件打补丁。以下整理自 [xpenology 论坛：Video Station 使用 VAAPI 硬解的方法](https://xpenology.com/forum/topic/70520-video-station-%E4%BD%BF%E7%94%A8vaapi-%E7%A1%AC%E8%A7%A3-%E7%9A%84%E6%96%B9%E6%B3%95/)（作者 Martian，2024 年 6 月）。

**手动操作步骤：**

1. **确认 AME 已安装并已激活**

2. **安装 SynoCommunity 的 ffmpeg**
   在套件中心安装 **SynoCommunity** 源中的 **ffmpeg 4**（若第二步已为 DTS/TrueHD 安装了 ffmpeg 5/6/7，可沿用，下面路径按实际套件名调整，例如 `ffmpeg6` 对应 `/var/packages/ffmpeg6/target/bin/ffmpeg`）。

3. **对 Video Station 打补丁**
   需要打补丁的文件为：
   - `/var/packages/VideoStation/target/lib/libvideostation_webapi.so`
   - `/var/packages/VideoStation/target/lib/libsynovideostation.so`
   - `/var/packages/VideoStation/target/lib/libsynovte.so`
   - `/var/packages/VideoStation/target/ui/cgi/advanced_manage.cgi`

4. **用 SynoCommunity 的 ffmpeg 替代 Codec Pack 的 ffmpeg41**

   ```bash
   # 若原位置已有 ffmpeg41，可先备份或删除后再建链接
   ln -sf /var/packages/ffmpeg/target/bin/ffmpeg /var/packages/CodecPack/target/bin/ffmpeg41
   ```

   若安装的是 SynoCommunity 的 ffmpeg 6，则可能是：

   ```bash
   ln -sf /var/packages/ffmpeg6/target/bin/ffmpeg /var/packages/CodecPack/target/bin/ffmpeg41
   ```

   作者还提供了一个 **代理程序** `ffmpeg41`（会复制到 `/var/packages/CodecPack/target/bin/ffmpeg41`），并在 `ffmpeg41.ini` 中配置 `app_path=/var/packages/ffmpeg/target/bin/ffmpeg`，可将实际调用日志写入 `/tmp/logs/ffmpeg41_proxy.log` 便于调试；若不需要调试，用上述符号链接即可。

5. **在 Video Station 设置中确认硬件加速**
   打开 Video Station → 设置，在转码/播放相关选项中勾选**启用硬件解码**。保存后播放高码率或 HEVC 视频，在**资源监控**中观察 CPU 占用应明显降低，且内核日志中可能出现 `SNVS display_info: has_dcb: yes`、`has_dci: yes` 等，表示 VA-API 已被识别。

**自动脚本：**

1. Patch: [vs_patch.zip](https://chou.oss-cn-hangzhou.aliyuncs.com/yii.im/asset/vs_patch.zip)

2. Usage:

   ```bash
   cd /path/to/vs_patch
   ./patch.sh
   ```
3. 脚本中默认使用 ffmpeg41，若你安装的是 ffmpeg6，则需要修改 ffmpeg41.ini 中的配置。

   配置文件：`/var/packages/CodecPack/target/pack/bin/ffmpeg41.ini`

   ```ini
   [Paths]
   app_path=/var/packages/ffmpeg6/target/bin/ffmpeg

   [Logging]
   enabled=false # 如果不需要调试，可以关闭日志
   log_file=/tmp/logs/ffmpeg41_proxy.log
   include_time=false
   ```

**测试环境：**
SA6400，Intel N100，Intel UHD730 核显，Video Station 3.1.1-3168，AME 3.1.0-3005。

**说明：** 论坛中有人反馈 **HEVC 10bit** 在部分环境下用 VA-API 编码时会报 “No usable encoding profile found”，与驱动或编码 profile 有关，可到该主题下查看后续讨论与解决方案。

---

## 小结与参考链接

- **三步流程**：
  1）[激活 AME](https://imnks.com/385.html)（DSM 7.2 使用 `ame72-3005.py`）；
  2）[VideoStation-FFMPEG-Patcher](https://github.com/AlexPresso/VideoStation-FFMPEG-Patcher) 修复 DTS、EAC3、TrueHD；
  3）[VA-API 硬解](https://xpenology.com/forum/topic/70520-video-station-%E4%BD%BF%E7%94%A8vaapi-%E7%A1%AC%E8%A7%A3-%E7%9A%84%E6%96%B9%E6%B3%95/)：安装 SynoCommunity ffmpeg，对 Video Station 指定库与 CGI 打补丁，并将 Codec Pack 的 `ffmpeg41` 替换为 SynoCommunity ffmpeg 的符号链接（或使用帖中代理程序），最后在设置中启用 VA-API 硬件解码。

- 若将来升级到 **DSM 7.2.2**，官方已移除 Video Station，需先用社区脚本（如 [007revad/Video_Station_for_DSM_722](https://github.com/007revad/Video_Station_for_DSM_722)）安装再按同样思路配置 AME 与硬解。

以上步骤整理自上述文章与项目，仅供学习与个人环境使用；请以各参考链接的最新说明为准。
