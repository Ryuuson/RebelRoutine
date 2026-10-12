# 架构说明

## 项目结构

```text
AppScope/                     应用信息与文字资源
entry/src/main/ets/
  entryability/               生命周期入口
  pages/                      页面宿主与统一提交
  views/                      四个主页面与辅助工作区
  components/                 表单、列表、弹窗与视觉控件
  common/                     状态、查询、操作协调、主题与窗口适配
  data/                       模型、命令、结算、校验与本地存储
entry/src/main/resources/     文字、颜色和页面配置
hvigor/                       构建配置
tools/visual-check/           业务测试脚本
```

## 页面与提交

应用使用单个 `entry` 模块，入口为 `EntryAbility → pages/Index`。`Index` 负责初始化、生命周期、返回键、页面和弹层组合；主页面与辅助工作区通过共享状态切换。

`RoutineState` 保存业务数据和界面状态；`PageActions` 聚合草稿、事项生命周期、批量操作、查询、委托、便签、计时和反馈。操作层通过 `RoutineHost` 接口访问页面宿主。

业务写入流程：

```text
界面操作
  → Commands / Engine 生成候选快照
  → 委托进度与奖励结算
  → 数据校验与事务保存
  → adopt 更新界面状态
```

统一提交入口通过 `mutationBusy` 阻止重叠写入，保存失败时不采用候选状态。

## 业务模型

| 模型 | 职责 |
| --- | --- |
| `HabitRecord` | 事项安排、完成结果、成长奖励及关联委托 |
| `PinnedTask` | 固定模板，复用后生成独立事项 |
| `ActionRecord` | 兼容旧版直接录入的行动 |
| `Commission` | 长期目标、周期、父子关系与奖励配置 |
| `RepeatPlan` | 重复生成规则和已使用日期 |
| `NoteRecord` | 便签内容及单个来源关联 |

安排日期与实际完成日期分别保存；普通事项与完成结果仍共用 `HabitRecord`。直接登记委托进度会生成已完成事项，留下行动来源。

固定模板与生成事项独立。重复计划在应用刷新时补生成，并通过已使用日期避免重复创建。便签不直接改变成长或委托进度，来源删除后仍保留内容及原来源名称。

## 成长与委托

`RoutineCommands / RoutineEngine / RoutineBatch` 负责事项、奖励变化与批量操作。自动选择成长维度由 `LocalTraitAnalyzer` 的关键词规则完成，当前最多匹配两个维度。

`CommissionProgress` 计算进度，`CommissionEngine` 结算阶段和目标奖励，`CommissionLedger` 保存点数账目，`CommissionRepeats` 生成重复事项。

独立目标累计关联行动的进度值；父项目按子目标完成比例求平均，避免混加不同单位。奖励凭据记录阶段和达成结果，进度回退时撤回奖励，再次达成时恢复；行动关联时的奖励配置会被冻结。

## 本地存储与恢复

`RoutineStore` 使用 ArkData 的 `routine_v2.db`，在 `app_state` 表中保存完整 JSON 快照：`id = 1` 为当前状态，`id = 2` 为上次恢复前的状态。筛选和统计主要在内存中完成。

旧 Preferences 数据迁移前保留原值备份。完整 JSON 备份支持恢复并保留恢复前快照；CSV 用于导出查看，不能用于完整恢复。数据异常时暂停普通写入，提供原始数据导出和备份恢复入口。
