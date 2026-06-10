import { hilog } from '@kit.PerformanceAnalysisKit';
import { CollaborationStateManager, DeviceRole, CollaborationMode, DeviceCollaborationInfo } from '../bean/CollaborationStateManager';
import { CrossDeviceCallManager } from '../bean/CrossDeviceCallManager';

const TAG = 'CollaborationPanel';
const DOMAIN = 0x0000;

@Component
export struct CollaborationPanel {
  @State collaborationManager: CollaborationStateManager = CollaborationStateManager.getInstance();
  @State crossDeviceCallManager: CrossDeviceCallManager = CrossDeviceCallManager.getInstance();
  @State devices: DeviceCollaborationInfo[] = [];
  @State localRole: DeviceRole = DeviceRole.STANDALONE;
  @State isCollaborating: boolean = false;
  @State collaborationMode: string = 'handoff';
  @State showDeviceList: boolean = false;
  private updateTimer: number = -1;

  aboutToAppear() {
    this.updateState();
    this.startAutoUpdate();
    
    this.collaborationManager.setOnStateChangeCallback(() => {
      this.updateState();
    });
  }

  aboutToDisappear() {
    if (this.updateTimer !== -1) {
      clearInterval(this.updateTimer);
    }
  }

  private startAutoUpdate(): void {
    this.updateTimer = setInterval(() => {
      this.updateState();
    }, 2000);
  }

  private updateState(): void {
    this.devices = this.collaborationManager.getAllDevices();
    this.localRole = this.collaborationManager.getLocalDeviceRole();
    
    const state = this.collaborationManager.getCollaborationState();
    this.isCollaborating = state?.isActive || false;
    this.collaborationMode = state?.mode || CollaborationMode.HANDOFF;
  }

  build() {
    Column() {
      this.HeaderSection()
      
      if (this.isCollaborating) {
        this.CollaborationStatusSection()
        this.DeviceListSection()
        this.ControlSection()
      } else {
        this.StartCollaborationSection()
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 8, color: '#15000000', offsetX: 0, offsetY: 4 })
  }

  @Builder
  HeaderSection() {
    Row() {
      Text('🔗')
        .fontSize(24)
      
      Column() {
        Text('多端协同')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1e293b')
        
        Text(this.getRoleText())
          .fontSize(12)
          .fontColor('#64748b')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
      .layoutWeight(1)
      
      if (this.isCollaborating) {
        Badge({
          count: this.devices.length,
          position: BadgePosition.RightTop,
          style: { badgeSize: 16, badgeColor: '#10b981' }
        }) {
          Text('协同中')
            .fontSize(12)
            .fontColor('#10b981')
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor('#d1fae5')
            .borderRadius(12)
        }
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .margin({ bottom: 16 })
  }

  @Builder
  CollaborationStatusSection() {
    Column() {
      Row() {
        Text('协同模式')
          .fontSize(14)
          .fontColor('#64748b')
        
        Text(this.getModeText())
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#667eea')
          .margin({ left: 8 })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      
      Row() {
        Text('主设备')
          .fontSize(14)
          .fontColor('#64748b')
        
        Text(this.getMasterDeviceName())
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1e293b')
          .margin({ left: 8 })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ top: 8 })
      
      Row() {
        Text('从设备数量')
          .fontSize(14)
          .fontColor('#64748b')
        
        Text(`${this.collaborationManager.getSlaveDevices().length}`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1e293b')
          .margin({ left: 8 })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ top: 8 })
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#f8fafc')
    .borderRadius(12)
    .margin({ bottom: 16 })
  }

  @Builder
  DeviceListSection() {
    Column() {
      Text('协同设备列表')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1e293b')
        .width('100%')
        .margin({ bottom: 12 })
      
      ForEach(this.devices, (device: DeviceCollaborationInfo) => {
        this.DeviceItem(device)
      })
    }
    .width('100%')
    .margin({ bottom: 16 })
  }

  @Builder
  DeviceItem(device: DeviceCollaborationInfo) {
    Row() {
      Text(this.getDeviceIcon(device.deviceType))
        .fontSize(20)
      
      Column() {
        Text(device.deviceName)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1e293b')
        
        Row() {
          Text(this.getRoleBadge(device.role))
            .fontSize(10)
            .fontColor(this.getRoleColor(device.role))
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .backgroundColor(this.getRoleBgColor(device.role))
            .borderRadius(8)
          
          if (device.isOnline) {
            Text('在线')
              .fontSize(10)
              .fontColor('#10b981')
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .backgroundColor('#d1fae5')
              .borderRadius(8)
              .margin({ left: 4 })
          }
        }
        .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
      .layoutWeight(1)
      
      if (device.role !== DeviceRole.MASTER && this.collaborationManager.isMaster()) {
        Button('移除')
          .fontSize(12)
          .height(28)
          .backgroundColor('#fee2e2')
          .fontColor('#ef4444')
          .onClick(() => {
            this.collaborationManager.removeSlaveDevice(device.deviceId);
          })
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#f8fafc')
    .borderRadius(12)
    .margin({ bottom: 8 })
  }

  @Builder
  ControlSection() {
    Column() {
      Row() {
        Button('切换模式')
          .fontSize(14)
          .layoutWeight(1)
          .backgroundColor('#667eea')
          .onClick(() => {
            this.toggleCollaborationMode();
          })
        
        Button('选举主设备')
          .fontSize(14)
          .layoutWeight(1)
          .backgroundColor('#10b981')
          .margin({ left: 8 })
          .onClick(() => {
            this.collaborationManager.electMaster();
          })
      }
      .width('100%')
      .margin({ bottom: 8 })
      
      if (this.collaborationManager.isMaster()) {
        Button('广播消息到所有从设备')
          .width('100%')
          .fontSize(14)
          .backgroundColor('#f59e0b')
          .onClick(async () => {
            const responses = await this.crossDeviceCallManager.broadcastToSlaves('ping', {});
            hilog.info(DOMAIN, TAG, `Broadcast responses: ${responses.length}`);
          })
          .margin({ bottom: 8 })
      }
      
      Button('停止协同')
        .width('100%')
        .fontSize(14)
        .backgroundColor('#ef4444')
        .onClick(() => {
          this.collaborationManager.stopCollaboration();
        })
    }
    .width('100%')
  }

  @Builder
  StartCollaborationSection() {
    Column() {
      Text('未启动协同')
        .fontSize(16)
        .fontColor('#64748b')
        .margin({ bottom: 16 })
      
      Row() {
        Button('镜像模式')
          .fontSize(14)
          .layoutWeight(1)
          .backgroundColor('#667eea')
          .onClick(() => {
            this.startCollaboration(CollaborationMode.MIRROR);
          })
        
        Button('扩展模式')
          .fontSize(14)
          .layoutWeight(1)
          .backgroundColor('#10b981')
          .margin({ left: 8 })
          .onClick(() => {
            this.startCollaboration(CollaborationMode.EXTENSION);
          })
      }
      .width('100%')
      .margin({ bottom: 8 })
      
      Button('流转模式')
        .width('100%')
        .fontSize(14)
        .backgroundColor('#f59e0b')
        .onClick(() => {
          this.startCollaboration(CollaborationMode.HANDOFF);
        })
    }
    .width('100%')
    .padding(20)
  }

  private getRoleText(): string {
    switch (this.localRole) {
      case DeviceRole.MASTER:
        return '主设备';
      case DeviceRole.SLAVE:
        return '从设备';
      default:
        return '独立设备';
    }
  }

  private getModeText(): string {
    switch (this.collaborationMode) {
      case CollaborationMode.MIRROR:
        return '镜像模式';
      case CollaborationMode.EXTENSION:
        return '扩展模式';
      case CollaborationMode.HANDOFF:
        return '流转模式';
      default:
        return '未知';
    }
  }

  private getMasterDeviceName(): string {
    const masterId = this.collaborationManager.getMasterDeviceId();
    const master = this.devices.find(d => d.deviceId === masterId);
    return master?.deviceName || '未知设备';
  }

  private getDeviceIcon(deviceType: string): string {
    switch (deviceType) {
      case 'phone':
        return '📱';
      case 'tablet':
        return '📟';
      case 'tv':
        return '📺';
      case 'wearable':
        return '⌚';
      default:
        return '📱';
    }
  }

  private getRoleBadge(role: DeviceRole): string {
    switch (role) {
      case DeviceRole.MASTER:
        return '主';
      case DeviceRole.SLAVE:
        return '从';
      default:
        return '独立';
    }
  }

  private getRoleColor(role: DeviceRole): string {
    switch (role) {
      case DeviceRole.MASTER:
        return '#667eea';
      case DeviceRole.SLAVE:
        return '#10b981';
      default:
        return '#64748b';
    }
  }

  private getRoleBgColor(role: DeviceRole): string {
    switch (role) {
      case DeviceRole.MASTER:
        return '#e0e7ff';
      case DeviceRole.SLAVE:
        return '#d1fae5';
      default:
        return '#f1f5f9';
    }
  }

  private startCollaboration(mode: CollaborationMode): void {
    this.collaborationManager.startCollaboration(mode).then((success) => {
      if (success) {
        hilog.info(DOMAIN, TAG, `Collaboration started: ${mode}`);
      }
    });
  }

  private toggleCollaborationMode(): void {
    const newMode = this.collaborationMode === CollaborationMode.MIRROR 
      ? CollaborationMode.EXTENSION 
      : CollaborationMode.MIRROR;
    this.collaborationManager.setCollaborationMode(newMode);
  }
}