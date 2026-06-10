# 鸿蒙多端协同完整实现指南

## 功能概述

本项目已实现完整的**鸿蒙多端协同**能力，包括：

1. **自动流转** - 基于智能条件自动触发流转
2. **协同状态管理** - 管理主从设备关系和协同状态
3. **分布式UI组件** - 跨设备UI组件同步
4. **跨设备功能调用** - 跨设备调用功能（如手机控制TV）

---

## 一、自动流转

### 触发条件

支持四种自动流转触发条件：

| 触发条件 | 说明 | 实现方式 |
|---------|------|---------|
| 设备距离变近 | 检测到设备距离小于阈值时自动流转 | 监听设备状态变化 |
| 网络状态变化 | 网络连接/断开/切换时自动流转 | NetworkKit监听 |
| 用户操作行为 | 页面跳转、按钮点击等操作时自动流转 | 手动通知 |
| 屏幕状态变化 | 应用前台/后台切换时自动流转 | Ability生命周期 |

### 使用方法

```typescript
// 启用/禁用自动流转
const autoContinuationManager = AutoContinuationManager.getInstance();
autoContinuationManager.enable();  // 启用
autoContinuationManager.disable(); // 禁用

// 配置触发条件
autoContinuationManager.setConfig({
  enabled: true,
  triggers: [
    AutoContinuationTrigger.DEVICE_DISTANCE,
    AutoContinuationTrigger.NETWORK_CHANGE
  ],
  deviceDistanceThreshold: 5.0,  // 距离阈值（米）
  minInterval: 30000              // 最小间隔（毫秒）
});

// 通知用户操作
autoContinuationManager.notifyUserAction('page_change');
autoContinuationManager.notifyUserAction('button_click');
```

---

## 二、协同状态管理

### 核心概念

**设备角色**：
- `MASTER` - 主设备：控制协同流程，管理从设备
- `SLAVE` - 从设备：接收主设备指令，同步状态
- `STANDALONE` - 独立设备：未参与协同

**协同模式**：
- `MIRROR` - 镜像模式：多设备显示相同UI
- `EXTENSION` - 扩展模式：多设备显示不同UI，功能互补
- `HANDOFF` - 流转模式：应用从一个设备流转到另一个设备

### 使用方法

```typescript
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
```

### 回调设置

```typescript
// 状态变化回调
collaborationManager.setOnStateChangeCallback((state) => {
  console.log('协同状态变化:', state);
});

// 角色变化回调
collaborationManager.setOnRoleChangeCallback((role) => {
  console.log('设备角色变化:', role);
});

// 设备加入回调
collaborationManager.setOnDeviceJoinCallback((device) => {
  console.log('设备加入:', device.deviceName);
});

// 设备离开回调
collaborationManager.setOnDeviceLeaveCallback((deviceId) => {
  console.log('设备离开:', deviceId);
});
```

---

## 三、分布式UI组件

### 功能说明

实现跨设备UI组件同步，多设备显示相同界面。

### 使用方法

```typescript
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
```

### 回调设置

```typescript
// 组件状态变化回调
distributedUIManager.setOnComponentStateChangeCallback((componentId, state) => {
  console.log(`组件 ${componentId} 状态变化:`, state);
});

// 镜像UI回调
distributedUIManager.setOnMirrorUICallback((componentStates) => {
  console.log('镜像UI更新:', componentStates);
});
```

---

## 四、跨设备功能调用

### 功能说明

实现跨设备功能调用，如手机控制TV播放、平板控制手机拍照等。

### 内置方法

系统提供以下内置方法：

| 方法名 | 说明 | 返回值 |
|-------|------|--------|
| `ping` | 连通性测试 | `{ pong: true, timestamp: number }` |
| `getDeviceInfo` | 获取设备信息 | `{ deviceId, deviceName, deviceType }` |
| `executeCommand` | 执行命令 | `{ executed: true, command: string }` |

### 使用方法

```typescript
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
```

### 注册自定义方法

```typescript
crossDeviceCallManager.registerMethod({
  name: 'playVideo',
  handler: async (params: Record<string, Object>) => {
    const videoUrl = params['url'] as string;
    // 执行播放逻辑
    return { playing: true, url: videoUrl };
  },
  description: '播放视频'
});

crossDeviceCallManager.registerMethod({
  name: 'takePhoto',
  handler: async (params: Record<string, Object>) => {
    // 执行拍照逻辑
    return { success: true, photoId: 'photo_123' };
  },
  description: '拍照'
});
```

---

## 五、多端协同UI组件

### CollaborationPanel组件

提供可视化协同管理界面，包括：

- 设备列表显示
- 主从设备标识
- 协同模式切换
- 设备角色管理
- 跨设备功能调用

### 使用方法

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

---

## 六、完整使用示例

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

### 场景3：流转后恢复状态

```typescript
// EntryAbility中处理流转恢复
onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
  if (launchParam.launchReason === AbilityConstant.LaunchReason.CONTINUATION) {
    const restoreData = want.parameters?.['ohos.extra.param.key.continueData'];
    
    // 恢复协同状态
    const sessionId = restoreData['collaborationSessionId'];
    const role = restoreData['deviceRole'];
    const mode = restoreData['collaborationMode'];
    
    // 根据恢复数据初始化协同
    collaborationManager.startCollaboration(mode);
  }
}
```

---

## 七、核心文件说明

| 文件 | 说明 |
|------|------|
| `AutoContinuationManager.ets` | 自动流转管理器 |
| `CollaborationStateManager.ets` | 协同状态管理器 |
| `DistributedUIManager.ets` | 分布式UI管理器 |
| `CrossDeviceCallManager.ets` | 跨设备功能调用管理器 |
| `CollaborationPanel.ets` | 多端协同UI组件 |
| `ContinuationManager.ets` | 流转管理器（基础） |
| `DistributedDataManager.ets` | 分布式数据管理 |

---

## 八、配置说明

### 权限配置

在 `module.json5` 中已配置以下权限：

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
// 协同状态管理配置
collaborationManager.setConfig({
  autoElectMaster: true,      // 自动选举主设备
  maxSlaveDevices: 3,         // 最大从设备数量
  syncInterval: 5000,         // 同步间隔（毫秒）
  enableAutoSync: true        // 启用自动同步
});

// 分布式UI配置
distributedUIManager.setConfig({
  enableMirrorMode: true,          // 启用镜像模式
  enableExtensionMode: true,       // 启用扩展模式
  syncPropertyChanges: true,       // 同步属性变化
  syncVisibilityChanges: true,     // 同步可见性变化
  debounceInterval: 100            // 防抖间隔（毫秒）
});

// 跨设备调用配置
crossDeviceCallManager.setConfig({
  defaultTimeout: 10000,      // 默认超时（毫秒）
  maxRetryCount: 3,           // 最大重试次数
  enableCallLog: true         // 启用调用日志
});
```

---

## 九、调试建议

### 查看协同状态

```typescript
const state = collaborationManager.getCollaborationState();
console.log('协同状态:', JSON.stringify(state, null, 2));
```

### 查看设备列表

```typescript
const devices = collaborationManager.getAllDevices();
devices.forEach(device => {
  console.log(`设备: ${device.deviceName}, 角色: ${device.role}, 在线: ${device.isOnline}`);
});
```

### 查看注册的方法

```typescript
const methods = crossDeviceCallManager.getRegisteredMethods();
console.log('已注册方法:', methods);
```

---

## 十、注意事项

1. **设备距离估算**：当前为模拟值，实际需根据蓝牙/WiFi信号强度计算
2. **主设备选举**：默认根据设备类型优先级选举（tablet > phone > tv > wearable）
3. **同步间隔**：建议设置合理的同步间隔，避免频繁同步影响性能
4. **超时设置**：跨设备调用建议设置合理的超时时间
5. **错误处理**：所有异步操作都应做好错误处理
6. **资源释放**：在Ability销毁时务必调用destroy方法释放资源

---

## 十一、后续优化建议

1. **真实距离计算**：集成蓝牙/WiFi信号强度计算真实设备距离
2. **智能设备选择**：基于设备性能、电量、网络质量选择最佳设备
3. **流转预测**：基于用户行为模式预测流转时机
4. **协同场景编排**：定义多端协同的业务流程
5. **冲突解决**：处理多设备同时操作的数据冲突
6. **离线支持**：支持设备离线后的状态恢复

---

## 技术支持

如有问题，请查看日志输出或联系开发团队。

日志TAG：
- `AutoContinuationManager` - 自动流转
- `CollaborationStateManager` - 协同状态
- `DistributedUIManager` - 分布式UI
- `CrossDeviceCallManager` - 跨设备调用