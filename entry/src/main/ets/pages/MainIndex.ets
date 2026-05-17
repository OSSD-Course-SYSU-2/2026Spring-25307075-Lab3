import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { CheckInManager } from '../common/bean/CheckInManager';
@Entry
@Component
struct Index {
  @State message: string = 'Hello World';
  @State checkCount: number = 0;
  @State checkMessage: string = '';
  aboutToAppear() {
    // ...已有初始化代码...

    CheckInManager.getContinuousCount().then(count => {
      this.checkCount = count;
    });
  }
  build() {
    Column() {
      Text($r('app.string.Kit')).fontWeight(FontWeight.Bold).fontSize(40);
      
      Column() {
        Button('打卡')
          .width(140)
          .height(140)
          .fontSize(20)
          .fontColor(Color.White)
          .backgroundColor('#409EFF')
          .borderRadius(70)
          .onClick(async () => {
            const result = await CheckInManager.saveCheckIn();
            this.checkCount = result.continuousCount;
            this.checkMessage = result.message;
          })

        Text(`连续打卡: ${this.checkCount}天`)
          .fontSize(18)
          .margin({ top: 16 })

        if (this.checkMessage) {
          Text(this.checkMessage)
            .fontSize(16)
            .fontColor('#FF0000')
            .margin({ top: 8 })
        }
      }
      .margin({ top: 20 })
      .alignItems(HorizontalAlign.Center)

      Button($r('app.string.ExerciseSequence')).width('50%').onClick(() => {
        this.getUIContext().getRouter().pushUrl({
          url: 'pages/ExerciseSequenceIndex'
        }).catch((err: BusinessError) => {
          hilog.error(0x0000, 'testTag', `Failed to pushUrl. Code: ${err.code}, message: ${err.message}`);
        })
      });
      Button($r('app.string.Auth')).width('50%').onClick(() => {
        this.getUIContext().getRouter().pushUrl({
          url: 'pages/AuthIndex'
        }).catch((err: BusinessError) => {
          hilog.error(0x0000, 'testTag', `Failed to pushUrl. Code: ${err.code}, message: ${err.message}`);
        })
      });
    }.alignItems(HorizontalAlign.Center).height('100%').width('100%')
    .justifyContent(FlexAlign.SpaceEvenly)
  }
}