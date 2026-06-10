# 健康服务应用 - 鸿蒙多端协同版

## 项目简介

本项目是一个基于鸿蒙生态的健康服务应用，实现了完整的**多端协同**能力，支持应用在多设备间自由流转、协同工作。

### 核心特性

- ✅ **自动流转** - 基于智能条件自动触发流转，无需手动操作
- ✅ **协同状态管理** - 管理主从设备关系，支持三种协同模式
- ✅ **分布式UI组件** - 跨设备UI同步，多设备显示相同界面
- ✅ **跨设备功能调用** - 跨设备调用功能，如手机控制TV播放
- ✅ **分布式数据同步** - 数据在多设备间实时同步

---

## 功能详解

### 一、自动流转

将原有的手动流转改造为智能条件触发的自动流转，系统根据预设条件自动检测并执行流转。

#### 触发条件

| 触发条件 | 说明 | 默认启用 |
|---------|------|---------|
| 设备距离变近 | 检测到设备距离小于阈值时自动流转 | ✅ |
| 网络状态变化 | 网络连接/断开/切换时自动流转 | ✅ |
| 用户操作行为 | 页面跳转、按钮点击等操作时自动流转 | ✅ |
| 屏幕状态变化 | 应用前台/后台切换时自动流转 | ✅ |

#### 使用方法

```typescript
import { AutoContinuationManager, AutoContinuationTrigger } from '../common/bean/AutoContinuationManager';

const autoContinuationManager = AutoContinuationManager.getInstance();

// 启用/禁用自动流转
autoContinuationManager.enable();
autoContinuationManager.disable();

// 自定义配置
autoContinuationManager.setConfig({
  enabled: true,
  triggers: [
    AutoContinuationTrigger.DEVICE_DISTANCE,
    AutoContinuationTrigger.NETWORK_CHANGE
  ],
  deviceDistanceThreshold: 5.0,  // 距离阈值（米）
  minInterval: 30000              // 最小流转间隔（毫秒）
});

// 通知用户操作（在页面跳转、按钮点击等处调用）
autoContinuationManager.notifyUserAction('page_change');
autoContinuationManager.notifyUserAction('button_click');

// 设置流转回调
autoContinuationManager.setAutoContinuationCallback((result) => {
  if (result.success) {
    console.log('自动流转成功:', result.message);
  }
});
```

---

### 二、协同状态管理

管理多设备协同状态，支持主从设备角色管理和三种协同模式。

#### 设备角色

| 角色 | 说明 | 权限 |
|------|------|------|
| MASTER（主设备） | 控制协同流程，管理从设备 | 可添加/移除从设备，广播消息 |
| SLAVE（从设备） | 接收主设备指令，同步状态 | 接收指令，同步数据 |
| STANDALONE（独立） | 未参与协同 | - |

#### 协同模式

| 模式 | 说明 | 应用场景 |
|------|------|---------|
| MIRROR（镜像） | 多设备显示相同UI | 多屏同步展示 |
| EXTENSION（扩展） | 多设备显示不同UI，功能互补 | 手机控制+TV显示 |
| HANDOFF（流转） | 应用从一个设备流转到另一个设备 | 设备切换 |

#### 使用方法

```typescript
import { CollaborationStateManager, CollaborationMode, DeviceRole } from '../common/bean/CollaborationStateManager';

const collaborationManager = CollaborationStateManager.getInstance();

// 启动协同
await collaborationManager.startCollaboration(CollaborationMode.MIRROR);

// 获取当前角色
const role = collaborationManager.getLocalDeviceRole();
const isMaster = collaborationManager.isMaster();
const isSlave = collaborationManager.isSlave();

// 选举主设备（自动选择性能最好的设备）
collaborationManager.electMaster();

// 添加/移除从设备
collaborationManager.addSlaveDevice(deviceId);
collaborationManager.removeSlaveDevice(deviceId);

// 切换协同模式
collaborationManager.setCollaborationMode(CollaborationMode.EXTENSION);

// 停止协同
collaborationManager.stopCollaboration();

// 设置回调
collaborationManager.setOnStateChangeCallback((state) => {
  console.log('协同状态变化:', state);
});

collaborationManager.setOnRoleChangeCallback((role) => {
  console.log('设备角色变化:', role);
});

collaborationManager.setOnDeviceJoinCallback((device) => {
  console.log('设备加入:', device.deviceName);
});
```

---

### 三、分布式UI组件

实现跨设备UI组件同步，支持多设备显示相同界面。

#### 使用方法

```typescript
import { DistributedUIManager } from '../common/bean/DistributedUIManager';

const distributedUIManager = DistributedUIManager.getInstance();

// 注册组件
distributedUIManager.registerComponent(
  'button1',
  'Button',
  { text: '点击我', color: '#667eea' }
);

// 更新组件属性
distributedUIManager.updateComponentProperty('button1', 'text', '已点击');
distributedUIManager.updateComponentProperties('button1', {
  text: '新文本',
  color: '#10b981'
});

// 设置组件可见性
distributedUIManager.setComponentVisibility('button1', false);

// 获取组件状态
const state = distributedUIManager.getComponentState('button1');

// 注销组件
distributedUIManager.unregisterComponent('button1');

// 设置回调
distributedUIManager.setOnComponentStateChangeCallback((componentId, state) => {
  console.log(`组件 ${componentId} 状态变化:`, state);
});
```

---

### 四、跨设备功能调用

实现跨设备功能调用，如手机控制TV播放视频、平板控制手机拍照等。

#### 内置方法

| 方法名 | 说明 | 返回值 |
|-------|------|--------|
| `ping` | 连通性测试 | `{ pong: true, timestamp: number }` |
| `getDeviceInfo` | 获取设备信息 | `{ deviceId, deviceName, deviceType }` |
| `executeCommand` | 执行命令 | `{ executed: true, command: string }` |

#### 使用方法

```typescript
import { CrossDeviceCallManager } from '../common/bean/CrossDeviceCallManager';

const crossDeviceCallManager = CrossDeviceCallManager.getInstance();

// 调用远程设备方法
const response = await crossDeviceCallManager.callRemoteMethod(
  targetDeviceId,
  'methodName',
  { param1: 'value1', param2: 'value2' }
);

if (response.success) {
  console.log('调用成功:', response.result);
} else {
  console.log('调用失败:', response.error);
}

// 调用主设备
const masterResponse = await crossDeviceCallManager.callMaster('methodName', params);

// 广播到所有从设备
const slaveResponses = await crossDeviceCallManager.broadcastToSlaves('methodName', params);

// 调用所有设备
const allResponses = await crossDeviceCallManager.callAllDevices('methodName', params);

// 注册自定义方法
crossDeviceCallManager.registerMethod({
  name: 'playVideo',
  handler: async (params: Record<string, Object>) => {
    const videoUrl = params['url'] as string;
    // 执行播放逻辑
    return { playing: true, url: videoUrl };
  },
  description: '播放视频'
});
```

---

### 五、多端协同UI组件

提供可视化协同管理界面。

#### 使用方法

```typescript
import { CollaborationPanel } from '../common/components/CollaborationPanel';

@Entry
@Component
struct MyPage {
  build() {
    Column() {
      CollaborationPanel()
        .width('100%')
    }
  }
}
```

#### 功能特性

- 设备列表显示
- 主从设备标识
- 协同模式切换
- 设备角色管理
- 跨设备功能调用按钮

---

## 应用场景示例

### 场景1：手机控制TV播放视频

```typescript
// TV端注册播放方法
crossDeviceCallManager.registerMethod({
  name: 'playVideo',
  handler: async (params) => {
    const videoUrl = params['url'] as string;
    // TV播放视频
    return { playing: true, url: videoUrl };
  }
});

// 手机端调用TV播放
const tvDeviceId = 'tv_device_123';
const response = await crossDeviceCallManager.callRemoteMethod(
  tvDeviceId,
  'playVideo',
  { url: 'https://example.com/video.mp4' }
);
```

### 场景2：多设备协同打卡

```typescript
// 启动协同
await collaborationManager.startCollaboration(CollaborationMode.MIRROR);

// 主设备打卡后，同步到所有从设备
if (collaborationManager.isMaster()) {
  const checkInResult = await CheckInManager.saveCheckIn();
  
  // 广播打卡结果到所有从设备
  await crossDeviceCallManager.broadcastToSlaves('syncCheckIn', {
    count: checkInResult.continuousCount,
    timestamp: Date.now()
  });
}
```

### 场景3：自动流转场景

```typescript
// 用户在手机上查看健康数据，靠近平板时自动流转
autoContinuationManager.setConfig({
  triggers: [AutoContinuationTrigger.DEVICE_DISTANCE],
  deviceDistanceThreshold: 3.0,  // 距离小于3米时触发
  autoSelectDevice: true          // 自动选择最近设备
});

// 流转后在新设备上恢复状态
onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
  if (launchParam.launchReason === AbilityConstant.LaunchReason.CONTINUATION) {
    const restoreData = want.parameters?.['ohos.extra.param.key.continueData'];
    // 恢复应用状态
  }
}
```

---

## 核心文件结构

```
entry/src/main/ets/
├── common/
│   ├── bean/
│   │   ├── AutoContinuationManager.ets      # 自动流转管理器
│   │   ├── CollaborationStateManager.ets    # 协同状态管理器
│   │   ├── DistributedUIManager.ets         # 分布式UI管理器
│   │   ├── CrossDeviceCallManager.ets       # 跨设备功能调用管理器
│   │   ├── ContinuationManager.ets          # 流转管理器（基础）
│   │   └── DistributedDataManager.ets       # 分布式数据管理
│   └── components/
│       └── CollaborationPanel.ets           # 多端协同UI组件
├── entryability/
│   └── EntryAbility.ets                     # Ability入口（已集成多端协同）
└── pages/
    └── MainIndex.ets                        # 主页面（已集成协同面板）
```

---

## 配置说明

### 权限配置

在 `entry/src/main/module.json5` 中已配置：

```json5
{
  "requestPermissions": [
    {
      "name": "ohos.permission.INTERNET",
      "reason": "网络访问"
    },
    {
      "name": "ohos.permission.GET_NETWORK_INFO",
      "reason": "获取网络信息"
    },
    {
      "name": "ohos.permission.DISTRIBUTED_DATASYNC",
      "reason": "分布式数据同步"
    },
    {
      "name": "ohos.permission.ACCESS_SERVICE_DM",
      "reason": "设备管理服务"
    }
  ]
}
```

### 协同配置

```typescript
// 自动流转配置
autoContinuationManager.setConfig({
  enabled: true,
  triggers: [/* 触发条件列表 */],
  deviceDistanceThreshold: 5.0,
  autoSelectDevice: true,
  minInterval: 30000
});

// 协同状态管理配置
collaborationManager.setConfig({
  autoElectMaster: true,
  maxSlaveDevices: 3,
  syncInterval: 5000,
  enableAutoSync: true
});

// 分布式UI配置
distributedUIManager.setConfig({
  enableMirrorMode: true,
  enableExtensionMode: true,
  syncPropertyChanges: true,
  syncVisibilityChanges: true,
  debounceInterval: 100
});

// 跨设备调用配置
crossDeviceCallManager.setConfig({
  defaultTimeout: 10000,
  maxRetryCount: 3,
  enableCallLog: true
});
```

---

## 快速开始

### 1. 初始化

应用启动时，所有管理器已在 `EntryAbility.ets` 中自动初始化：

```typescript
onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
  // 自动初始化所有管理器
  this.continuationManager.init(this.context);
  this.autoContinuationManager.init(this.context);
  this.collaborationStateManager.init(this.context);
  this.distributedUIManager.init(this.context);
  this.crossDeviceCallManager.init(this.context);
}
```

### 2. 启用自动流转

在主页面中，通过Toggle开关启用/禁用自动流转：

```typescript
Toggle({ type: ToggleType.Switch, isOn: this.autoContinuationEnabled })
  .onChange((isOn: boolean) => {
    if (isOn) {
      this.autoContinuationManager.enable();
    } else {
      this.autoContinuationManager.disable();
    }
  })
```

### 3. 启动协同

点击"多端协同"按钮，打开协同面板：

```typescript
CollaborationPanel()
```

在面板中选择协同模式并启动协同。

### 4. 跨设备调用

注册自定义方法并在需要时调用：

```typescript
// 注册方法
crossDeviceCallManager.registerMethod({
  name: 'myMethod',
  handler: async (params) => {
    // 处理逻辑
    return { success: true };
  }
});

// 调用方法
await crossDeviceCallManager.callRemoteMethod(deviceId, 'myMethod', params);
```

---

## 调试指南

### 查看日志

使用hilog查看各管理器的日志：

```typescript
// 日志TAG
- 'AutoContinuationManager'     // 自动流转
- 'CollaborationStateManager'   // 协同状态
- 'DistributedUIManager'        // 分布式UI
- 'CrossDeviceCallManager'      // 跨设备调用
- 'ContinuationManager'         // 流转管理
```

### 调试命令

```typescript
// 查看协同状态
const state = collaborationManager.getCollaborationState();
console.log('协同状态:', JSON.stringify(state, null, 2));

// 查看设备列表
const devices = collaborationManager.getAllDevices();
devices.forEach(d => console.log(`设备: ${d.deviceName}, 角色: ${d.role}`));

// 查看注册的方法
const methods = crossDeviceCallManager.getRegisteredMethods();
console.log('已注册方法:', methods);

// 测试连通性
const response = await crossDeviceCallManager.callRemoteMethod(deviceId, 'ping', {});
console.log('连通性测试:', response);
```

---

## 注意事项

1. **设备距离估算**：当前为模拟值，实际项目中需根据蓝牙/WiFi信号强度计算真实距离
2. **主设备选举**：默认根据设备类型优先级选举（tablet > phone > tv > wearable）
3. **同步间隔**：建议设置合理的同步间隔，避免频繁同步影响性能
4. **超时设置**：跨设备调用建议设置合理的超时时间（默认10秒）
5. **错误处理**：所有异步操作都应做好错误处理
6. **资源释放**：在Ability销毁时自动调用destroy方法释放资源

---

## 后续优化建议

1. **真实距离计算**：集成蓝牙/WiFi信号强度计算真实设备距离
2. **智能设备选择**：基于设备性能、电量、网络质量选择最佳设备
3. **流转预测**：基于用户行为模式预测流转时机
4. **协同场景编排**：定义多端协同的业务流程
5. **冲突解决**：处理多设备同时操作的数据冲突
6. **离线支持**：支持设备离线后的状态恢复
7. **安全认证**：跨设备调用的安全认证机制

---

## 技术支持

- 📖 详细文档：`AUTO_CONTINUATION_GUIDE.md`、`MULTI_DEVICE_COLLABORATION_GUIDE.md`
- 🐛 问题反馈：查看日志输出或联系开发团队

---

## 版本历史

- **v2.0.0** - 实现完整多端协同能力（自动流转、协同状态管理、分布式UI、跨设备调用）
- **v1.0.0** - 基础健康服务应用（手动流转）

---

## 许可证

本项目仅供学习和参考使用。