# 开发指南

## 环境准备

使用支持 HarmonyOS API 24 的 DevEco Studio，安装 `6.1.1(24)` SDK。项目采用 Stage 模型，Hvigor 与 OHPM 工程模型版本为 `6.1.1`。建议使用 DevEco Studio 随附的 Node 和构建工具。

2026-10-12 的本机构建与测试使用随 DevEco Studio 提供的 Node.js `18.20.1`；这是已验证的环境记录，并非独立指定的 Node 版本要求。

```powershell
git clone https://github.com/Ryuuson/RebelRoutine.git
cd RebelRoutine
ohpm install
```

`ohpm` 需已加入终端 PATH，也可在 DevEco Studio 中同步依赖。本机 SDK 路径由 IDE 配置，`local.properties` 不提交。

## 补齐界面资源

公开仓库仅包含源码、构建配置、文字/颜色/页面配置和业务测试脚本。图片、SVG、字体、截图、提取工具和研究资料均未上传。

在以下目录提供同名替代资源：

| 目录 | 用途 |
| --- | --- |
| `AppScope/resources/base/media/` | 应用图标等应用级资源 |
| `entry/src/main/resources/base/media/` | 启动图标、页面背景、维度图标及其他界面素材 |

资源名由 `AppScope/app.json5`、`entry/src/main/module.json5` 与 ArkTS 源码中的 `$r('app.media.…')` 确定，其中包括 `app_icon_p5` 和 `start_icon_p5`。

若安装了 ripgrep，可列出引用：

```powershell
rg 'app\.media\.' entry/src/main/ets
rg '\$media:' AppScope/app.json5 entry/src/main/module.json5
```

缺少资源时，完整构建会失败；业务测试不需要这些素材。

## 构建 HAP

可以直接通过 DevEco Studio 构建。下面是 Windows PowerShell 示例，将 `$devecoPath` 改为本机安装目录：

```powershell
$devecoPath = 'C:\Program Files\Huawei\DevEco Studio'
$env:DEVECO_SDK_HOME = Join-Path $devecoPath 'sdk'
$env:JAVA_HOME = Join-Path $devecoPath 'jbr'
$nodePath = Join-Path $devecoPath 'tools/node/node.exe'
$hvigorPath = Join-Path $devecoPath 'tools/hvigor/bin/hvigorw.js'

& $nodePath $hvigorPath --mode module `
  -p module=entry@default -p product=default -p requiredDeviceType=phone `
  clean assembleHap --no-daemon
```

输出目录为 `entry/build/default/outputs/default/`。当前签名配置为空，默认生成未签名 HAP；在 DevEco Studio 中配置自己的签名后安装到设备。不要提交签名证书、私钥或本机路径配置。

## 运行业务测试

在项目根目录执行：

```powershell
$devecoPath = 'C:\Program Files\Huawei\DevEco Studio'
$env:DEVECO_SDK_HOME = Join-Path $devecoPath 'sdk'
$nodePath = Join-Path $devecoPath 'tools/node/node.exe'
& $nodePath tools/test.cjs
```

SDK 需包含 `default/openharmony/ets/build-tools/ets-loader/node_modules/typescript`。

脚本读取真实应用源码，覆盖事项操作、导航、成长维度、委托、重复计划、便签、删除恢复、日期选择器调用、迁移、备份和写入失败。SDK I/O、时钟及 UI 挂载使用模拟实现；真机文件读写、输入法和界面显示仍需单独检查。
