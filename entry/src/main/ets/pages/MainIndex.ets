import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { CheckInManager } from '../common/bean/CheckInManager';

@Entry
@Component
struct Index {
  @State message: string = 'Hello World';
  @State checkCount: number = 0;
  @State checkMessage: string = '';
  @State isChecking: boolean = false; // 打卡动画状态

  aboutToAppear() {
    // ...已有初始化代码...

    CheckInManager.getContinuousCount().then(count => {
      this.checkCount = count;
    });
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
                .width(150)
                .height(150)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
                .backgroundColor(this.isChecking ? '#94a3b8' : '#667eea')
                .borderRadius(75)
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
                    setTimeout(() => {
                      this.isChecking = false;
                    }, 500);
                  }
                })
            }
            .margin({ top: 20, bottom: 20 })

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
              .margin({ top: 20, bottom: 30 })
              .onClick(() => {
                this.getUIContext().getRouter().pushUrl({
                  url: 'pages/ExerciseSequenceIndex'
                }).catch((err: BusinessError) => {
                  hilog.error(0x0000, 'testTag', `Failed to pushUrl. Code: ${err.code}, message: ${err.message}`);
                })
              })
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
      this.getUIContext().getRouter().pushUrl({
        url: url
      }).catch((err: BusinessError) => {
        hilog.error(0x0000, 'testTag', `Failed to pushUrl. Code: ${err.code}, message: ${err.message}`);
      })
    })
  }
}
