import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { CheckInManager } from '../common/bean/CheckInManager';
import { ContinuationManager } from '../common/bean/ContinuationManager';
import { AutoContinuationManager, AutoContinuationTrigger } from '../common/bean/AutoContinuationManager';
import { distributedDeviceManager } from '@kit.DistributedServiceKit';
import { CollaborationPanel } from '../common/components/CollaborationPanel';

@Entry
@Component
struct Index {
  @State message: string = 'Hello World';
  @State checkCount: number = 0;
  @State checkMessage: string = '';
  @State isChecking: boolean = false;
  @State availableDevices: distributedDeviceManager.DeviceBasicInfo[] = [];
  @State showDeviceList: boolean = false;
  @State isContinuing: boolean = false;
  @State autoContinuationEnabled: boolean = true;
  @State autoContinuationStatus: string = '自动流转已启用';
  @State showCollaborationPanel: boolean = false;
  private continuationManager: ContinuationManager = ContinuationManager.getInstance();
  private autoContinuationManager: AutoContinuationManager = AutoContinuationManager.getInstance();

  aboutToAppear() {
    CheckInManager.getContinuousCount().then(count => {
      this.checkCount = count;
    });
    
    this.loadAvailableDevices();
    
    this.autoContinuationEnabled = this.autoContinuationManager.isEnabled();
    this.updateAutoContinuationStatus();
    
    this.autoContinuationManager.setAutoContinuationCallback((result) => {
      if (result.success) {
        this.checkMessage = `自动流转成功: ${result.message}`;
      } else {
        this.checkMessage = `自动流转失败: ${result.message}`;
      }
    });
  }

  updateAutoContinuationStatus(): void {
    const config = this.autoContinuationManager.getConfig();
    const triggers = config.triggers.map(t => {
      switch (t) {
        case AutoContinuationTrigger.DEVICE_DISTANCE:
          return '设备距离';
        case AutoContinuationTrigger.NETWORK_CHANGE:
          return '网络变化';
        case AutoContinuationTrigger.USER_ACTION:
          return '用户操作';
        case AutoContinuationTrigger.SCREEN_STATE:
          return '屏幕状态';
        default:
          return '';
      }
    }).join('、');
    
    this.autoContinuationStatus = config.enabled 
      ? `自动流转已启用 (${triggers})`
      : '自动流转已禁用';
  }

  async loadAvailableDevices() {
    try {
      const devices = await this.continuationManager.getAvailableDevices();
      this.availableDevices = devices;
    } catch (error) {
      hilog.error(0x0000, 'MainIndex', `Failed to load devices: ${error}`);
    }
  }

  build() {
    Column() {
      // 顶部标题区域
      Column() {
        Text($r('app.string.Kit'))
          .fontWeight(FontWeight.Bold)
          .fontSize(28)
          .fontColor('#FFFFFF')
          .textShadow({ radius: 2, color: '#40000000', offsetX: 0, offsetY: 2 })
        
        Text('健康生活，从打卡开始')
          .fontSize(14)
          .fontColor('#CCFFFFFF')
          .margin({ top: 8 })
      }
      .width('100%')
      .padding({ top: 40, bottom: 30 })
      .linearGradient({
        angle: 135,
        colors: [['#667eea', 0.0], ['#764ba2', 1.0]]
      })

      // 主要内容区域
      Scroll() {
        Column() {
          // 打卡按钮卡片
          Column() {
            // 打卡按钮
            Column() {
              Button(this.isChecking ? '打卡中...' : '打卡')
                .width(120)
                .height(120)
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
                .backgroundColor(this.isChecking ? '#94a3b8' : '#667eea')
                .borderRadius(60)
                .shadow({
                  radius: this.isChecking ? 10 : 20,
                  color: this.isChecking ? '#40000000' : '#40667eea',
                  offsetX: 0,
                  offsetY: this.isChecking ? 5 : 10
                })
                .scale(this.isChecking ? { x: 0.95, y: 0.95 } : { x: 1, y: 1 })
                .onClick(async () => {
                  if (!this.isChecking) {
                    this.isChecking = true;
                    const result = await CheckInManager.saveCheckIn();
                    this.checkCount = result.continuousCount;
                    this.checkMessage = result.message;
                    this.autoContinuationManager.notifyUserAction('button_click');
                    setTimeout(() => {
                      this.isChecking = false;
                    }, 500);
                  }
                })
            }
            .margin({ top: 15, bottom: 15 })

            // 连续打卡统计卡片
            Column() {
              Row() {
                Column() {
                  Text('连续打卡')
                    .fontSize(14)
                    .fontColor('#64748b')
                  Text(`${this.checkCount}`)
                    .fontSize(36)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#667eea')
                    .margin({ top: 4 })
                  Text('天')
                    .fontSize(14)
                    .fontColor('#64748b')
                }
                .layoutWeight(1)

                // 分割线
                Column()
                  .width(1)
                  .height(60)
                  .backgroundColor('#e2e8f0')

                Column() {
                  Text('今日状态')
                    .fontSize(14)
                    .fontColor('#64748b')
                  Text(this.checkCount > 0 ? '已打卡' : '未打卡')
                    .fontSize(20)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.checkCount > 0 ? '#10b981' : '#f59e0b')
                    .margin({ top: 8 })
                }
                .layoutWeight(1)
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceAround)
            }
            .width('85%')
            .padding(20)
            .margin({ top: 10 })
            .backgroundColor(Color.White)
            .borderRadius(16)
            .shadow({ radius: 10, color: '#15000000', offsetX: 0, offsetY: 4 })

            // 打卡消息提示
            if (this.checkMessage) {
              Row() {
                Text('✓')
                  .fontSize(16)
                  .fontColor('#10b981')
                  .margin({ right: 8 })
                Text(this.checkMessage)
                  .fontSize(14)
                  .fontColor('#10b981')
              }
              .width('85%')
              .padding(12)
              .margin({ top: 16 })
              .backgroundColor('#f0fdf4')
              .borderRadius(12)
              .border({ width: 1, color: '#86efac' })
            }

            // 新功能入口区域
            Column() {
              Text('更多功能')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1e293b')
                .width('100%')
                .margin({ bottom: 12 })

              Row({ space: 12 }) {
                // 数据仪表盘
                this.FeatureCard('📊', '数据仪表盘', '#667eea', 'pages/DashboardIndex')

                // 目标成就
                this.FeatureCard('🎯', '目标成就', '#f59e0b', 'pages/GoalsIndex')

                // 体重管理
                this.FeatureCard('⚖️', '体重管理', '#10b981', 'pages/WeightIndex')
              }
              .width('100%')
            }
            .width('85%')
            .margin({ top: 20 })
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(16)
            .shadow({ radius: 10, color: '#15000000', offsetX: 0, offsetY: 4 })

            // 开始运动记录按钮
            Button($r('app.string.ExerciseSequence'))
              .width('85%')
              .height(50)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
              .backgroundColor('#667eea')
              .borderRadius(25)
              .shadow({ radius: 8, color: '#30667eea', offsetX: 0, offsetY: 4 })
              .margin({ top: 20, bottom: 10 })
              .onClick(() => {
                this.autoContinuationManager.notifyUserAction('page_change');
                this.getUIContext().getRouter().pushUrl({
                  url: 'pages/ExerciseSequenceIndex'
                }).catch((err: BusinessError) => {
                  hilog.error(0x0000, 'testTag', `Failed to pushUrl. Code: ${err.code}, message: ${err.message}`);
                });
              })

            Column() {
              Row() {
                Text('自动流转')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#1e293b')
                  .layoutWeight(1)
                
                Toggle({ type: ToggleType.Switch, isOn: this.autoContinuationEnabled })
                  .selectedColor('#667eea')
                  .onChange((isOn: boolean) => {
                    this.autoContinuationEnabled = isOn;
                    if (isOn) {
                      this.autoContinuationManager.enable();
                    } else {
                      this.autoContinuationManager.disable();
                    }
                    this.updateAutoContinuationStatus();
                  })
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)
              
              Text(this.autoContinuationStatus)
                .fontSize(12)
                .fontColor('#64748b')
                .margin({ top: 8 })
            }
            .width('85%')
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(16)
            .shadow({ radius: 8, color: '#15000000', offsetX: 0, offsetY: 4 })
            .margin({ top: 10, bottom: 10 })

            Button(this.isContinuing ? '流转中...' : '手动流转')
              .width('85%')
              .height(50)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
              .backgroundColor(this.isContinuing ? '#94a3b8' : '#10b981')
              .borderRadius(25)
              .shadow({ radius: 8, color: '#3010b981', offsetX: 0, offsetY: 4 })
              .margin({ bottom: 10 })
              .onClick(async () => {
                if (!this.isContinuing) {
                  await this.loadAvailableDevices();
                  if (this.availableDevices.length > 0) {
                    this.showDeviceList = true;
                  } else {
                    this.checkMessage = '未发现可用设备';
                  }
                }
              })

            Button(this.showCollaborationPanel ? '隐藏协同面板' : '多端协同')
              .width('85%')
              .height(50)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
              .backgroundColor('#f59e0b')
              .borderRadius(25)
              .shadow({ radius: 8, color: '#30f59e0b', offsetX: 0, offsetY: 4 })
              .margin({ bottom: 10 })
              .onClick(() => {
                this.showCollaborationPanel = !this.showCollaborationPanel;
              })

            if (this.showCollaborationPanel) {
              CollaborationPanel()
                .width('85%')
                .margin({ bottom: 20 })
            }

            // 设备列表弹窗
            if (this.showDeviceList && this.availableDevices.length > 0) {
              Column() {
                Text('选择目标设备')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#1e293b')
                  .margin({ bottom: 16 })

                ForEach(this.availableDevices, (device: distributedDeviceManager.DeviceBasicInfo) => {
                  Row() {
                    Text('📱')
                      .fontSize(24)
                    Column() {
                      Text(device.deviceName)
                        .fontSize(16)
                        .fontWeight(FontWeight.Medium)
                        .fontColor('#1e293b')
                      Text(device.deviceId.substring(0, 8) + '...')
                        .fontSize(12)
                        .fontColor('#64748b')
                        .margin({ top: 4 })
                    }
                    .alignItems(HorizontalAlign.Start)
                    .margin({ left: 12 })
                    .layoutWeight(1)

                    Button('流转')
                      .fontSize(14)
                      .height(36)
                      .backgroundColor('#667eea')
                      .onClick(async () => {
                        this.isContinuing = true;
                        this.showDeviceList = false;
                        const result = await this.continuationManager.startContinuation(device.deviceId);
                        this.isContinuing = false;
                        if (result.success) {
                          this.checkMessage = `已流转到 ${device.deviceName}`;
                        } else {
                          this.checkMessage = result.message;
                        }
                      })
                  }
                  .width('100%')
                  .padding(12)
                  .backgroundColor('#f8fafc')
                  .borderRadius(12)
                  .margin({ bottom: 8 })
                })

                Button('取消')
                  .width('100%')
                  .height(40)
                  .fontSize(14)
                  .backgroundColor('#f1f5f9')
                  .fontColor('#64748b')
                  .margin({ top: 8 })
                  .onClick(() => {
                    this.showDeviceList = false;
                  })
              }
              .width('85%')
              .padding(20)
              .backgroundColor(Color.White)
              .borderRadius(16)
              .shadow({ radius: 20, color: '#20000000', offsetX: 0, offsetY: 10 })
              .margin({ bottom: 20 })
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
      .backgroundColor('#f8fafc')
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
  }

  // 功能卡片组件
  @Builder
  FeatureCard(icon: string, title: string, color: string, url: string) {
    Column() {
      Text(icon)
        .fontSize(32)
      
      Text(title)
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1e293b')
        .margin({ top: 8 })
    }
    .layoutWeight(1)
    .padding(12)
    .backgroundColor('#f8fafc')
    .borderRadius(12)
    .border({ width: 2, color: color })
    .onClick(() => {
      this.autoContinuationManager.notifyUserAction('page_change');
      this.getUIContext().getRouter().pushUrl({
        url: url
      }).catch((err: BusinessError) => {
        hilog.error(0x0000, 'testTag', `Failed to pushUrl. Code: ${err.code}, message: ${err.message}`);
      });
    })
  }
}
