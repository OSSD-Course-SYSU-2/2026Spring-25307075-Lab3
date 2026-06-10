# 鸿蒙自动流转功能使用说明

## 功能概述

本项目已将原有的手动流转改造为智能条件触发的自动流转功能。系统会根据预设条件自动检测并执行流转，无需用户手动选择设备。

## 自动流转触发条件

系统支持以下四种自动流转触发条件：

### 1. 设备距离变近
- **触发机制**：当检测到其他设备距离变近（小于阈值）时自动流转
- **默认阈值**：5.0（单位：米，可根据实际情况调整）
- **实现方式**：监听设备状态变化，估算设备距离

### 2. 网络状态变化
- **触发机制**：当设备网络状态发生变化时自动流转
- **监听事件**：
  - 网络可用（netAvailable）
  - 网络丢失（netLost）
  - 网络属性变化（netConnectionPropertiesChange）
- **实现方式**：使用NetworkKit的connection模块监听网络变化

### 3. 用户操作行为
- **触发机制**：当用户执行特定操作时自动流转
- **监听行为**：
  - 页面跳转（page_change）
  - 按钮点击（button_click）
  - 数据提交（data_submit）
- **实现方式**：在关键用户操作处调用通知方法

### 4. 屏幕状态变化
- **触发机制**：当设备屏幕状态变化时自动流转
- **监听事件**：
  - 应用进入前台（onForeground）→ 屏幕亮起
  - 应用进入后台（onBackground）→ 屏幕熄灭
- **实现方式**：在Ability生命周期中触发

## 使用方法

### 1. 启用/禁用自动流转

在主页面（MainIndex）中，提供了自动流转开关：

```typescript
Toggle({ type: ToggleType.Switch, isOn: this.autoContinuationEnabled })
  .onChange((isOn: boolean) => {
    this.autoContinuationEnabled = isOn;
    if (isOn) {
      this.autoContinuationManager.enable();
    } else {
      this.autoContinuationManager.disable();
    }
  })
```

### 2. 配置自动流转参数

可以通过`setConfig`方法自定义配置：

```typescript
this.autoContinuationManager.setConfig({
  enabled: true,                                    // 是否启用
  triggers: [                                       // 触发条件列表
    AutoContinuationTrigger.DEVICE_DISTANCE,
    AutoContinuationTrigger.NETWORK_CHANGE,
    AutoContinuationTrigger.USER_ACTION,
    AutoContinuationTrigger.SCREEN_STATE
  ],
  deviceDistanceThreshold: 5.0,                    // 设备距离阈值（米）
  autoSelectDevice: true,                          // 是否自动选择设备
  preferredDeviceId: 'xxx',                        // 首选设备ID（可选）
  minInterval: 30000                               // 最小流转间隔（毫秒）
});
```

### 3. 自定义流转回调

可以设置自动流转成功/失败的回调：

```typescript
this.autoContinuationManager.setAutoContinuationCallback((result) => {
  if (result.success) {
    console.log(`自动流转成功: ${result.message}`);
  } else {
    console.log(`自动流转失败: ${result.message}`);
  }
});
```

### 4. 手动通知用户操作

在需要的地方手动通知用户操作：

```typescript
// 页面跳转时
this.autoContinuationManager.notifyUserAction('page_change');

// 按钮点击时
this.autoContinuationManager.notifyUserAction('button_click');

// 数据提交时
this.autoContinuationManager.notifyUserAction('data_submit');
```

### 5. 自定义屏幕状态回调

可以设置屏幕状态变化的回调：

```typescript
this.autoContinuationManager.setScreenStateCallback((isScreenOn: boolean) => {
  if (isScreenOn) {
    console.log('屏幕亮起');
  } else {
    console.log('屏幕熄灭');
  }
});
```

### 6. 自定义用户操作回调

可以设置用户操作的回调：

```typescript
this.autoContinuationManager.setUserActionCallback((action: string) => {
  console.log(`用户操作: ${action}`);
});
```

## 核心文件说明

### 1. AutoContinuationManager.ets
**路径**：`entry/src/main/ets/common/bean/AutoContinuationManager.ets`

**功能**：
- 智能条件检测管理器
- 设备状态监听
- 网络状态监听
- 自动流转触发逻辑
- 设备选择策略

**主要方法**：
- `init()` - 初始化管理器
- `enable()` / `disable()` - 启用/禁用自动流转
- `setConfig()` - 设置配置
- `notifyUserAction()` - 通知用户操作
- `notifyScreenStateChange()` - 通知屏幕状态变化

### 2. ContinuationManager.ets
**路径**：`entry/src/main/ets/common/bean/ContinuationManager.ets`

**功能**：
- 流转管理器（基础能力）
- 设备发现
- 流转执行
- 设备状态监听接口

**新增方法**：
- `getDeviceManager()` - 获取设备管理器
- `onDeviceStateChange()` - 注册设备状态变化监听
- `offDeviceStateChange()` - 注销设备状态变化监听

### 3. EntryAbility.ets
**路径**：`entry/src/main/ets/entryability/EntryAbility.ets`

**修改内容**：
- 集成AutoContinuationManager
- 在onCreate中初始化自动流转管理器
- 在onDestroy中销毁自动流转管理器
- 在onForeground/onBackground中通知屏幕状态变化

### 4. MainIndex.ets
**路径**：`entry/src/main/ets/pages/MainIndex.ets`

**修改内容**：
- 添加自动流转开关UI
- 显示当前自动流转状态
- 在用户操作处通知AutoContinuationManager
- 保留手动流转按钮（作为备用）

### 5. module.json5
**路径**：`entry/src/main/module.json5`

**新增权限**：
- `ohos.permission.INTERNET` - 网络访问权限
- `ohos.permission.GET_NETWORK_INFO` - 获取网络信息权限

## 流转流程

### 自动流转流程
```
条件触发（设备距离/网络变化/用户操作/屏幕状态）
  ↓
检查是否启用自动流转
  ↓
检查最小流转间隔
  ↓
获取可用设备列表
  ↓
选择最佳设备（基于距离、优先级等）
  ↓
执行流转（startContinuation）
  ↓
更新流转时间戳
  ↓
触发回调通知
```

### 设备选择策略
1. 如果指定了preferredDeviceId，优先使用该设备
2. 如果autoSelectDevice为true，自动选择距离最近的设备
3. 否则需要手动选择设备

## 配置参数说明

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| enabled | boolean | true | 是否启用自动流转 |
| triggers | AutoContinuationTrigger[] | 全部四种 | 触发条件列表 |
| deviceDistanceThreshold | number | 5.0 | 设备距离阈值（米） |
| autoSelectDevice | boolean | true | 是否自动选择设备 |
| preferredDeviceId | string | undefined | 首选设备ID |
| minInterval | number | 30000 | 最小流转间隔（毫秒） |

## 注意事项

1. **权限配置**：确保已添加必要的权限（INTERNET、GET_NETWORK_INFO、DISTRIBUTED_DATASYNC、ACCESS_SERVICE_DM）

2. **设备距离估算**：当前设备距离为模拟值，实际项目中需要根据蓝牙信号强度、WiFi信号强度等方式计算真实距离

3. **流转间隔**：为避免频繁流转，设置了最小流转间隔（默认30秒），可根据实际需求调整

4. **设备选择**：自动流转会自动选择最佳设备，如需指定设备可设置preferredDeviceId

5. **手动流转**：保留了手动流转按钮作为备用方案，用户仍可手动选择设备流转

6. **日志查看**：可通过hilog查看自动流转的详细日志，TAG为'AutoContinuationManager'

## 调试建议

1. 查看自动流转状态：
```typescript
const config = this.autoContinuationManager.getConfig();
console.log('自动流转配置:', JSON.stringify(config));
```

2. 查看设备距离信息：
```typescript
const proximityList = await this.autoContinuationManager.getDeviceProximityList();
console.log('设备距离列表:', JSON.stringify(proximityList));
```

3. 查看可用设备：
```typescript
const devices = await this.continuationManager.getAvailableDevices();
console.log('可用设备:', devices.length);
```

## 后续优化建议

1. **真实距离计算**：集成蓝牙/WiFi信号强度计算真实设备距离
2. **智能设备选择**：基于设备性能、电量、网络质量等因素选择最佳设备
3. **流转预测**：基于用户行为模式预测流转时机
4. **流转失败重试**：自动重试机制
5. **流转历史记录**：记录流转历史，优化流转策略

## 技术支持

如有问题，请查看日志输出或联系开发团队。