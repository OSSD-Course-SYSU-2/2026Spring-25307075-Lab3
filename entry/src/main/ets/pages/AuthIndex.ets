/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */

import { AuthManagement } from '../common/bean/AuthManagement';

@Entry
@Component
struct Index {
  @State log: string = '';

  build() {
    Column() {
      Text($r('app.string.Auth'))
        .fontWeight(FontWeight.Bold)
        .fontSize(28)
        .height('15%')
        .margin({ top: 10 });

      Row() {
        Button($r('app.string.RequestAuthorizations'))
          .width('80%')
          .height(45)
          .onClick(async () => {
            this.log = await AuthManagement.auth();
          });
      }
      .height('10%')
      .alignItems(VerticalAlign.Center);

      Column() {
        Column() {
          Text($r('app.string.Print_log'))
            .fontSize(14)
            .textAlign(TextAlign.Start)
            .fontWeight(FontWeight.Bold);
        }
        .alignItems(HorizontalAlign.Start)
        .width('90%');

        Scroll() {
          Column() {
            Text(this.log)
              .fontSize(12)
              .textAlign(TextAlign.Start);
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding({ bottom: 10 });
        }
        .width('90%')
        .layoutWeight(1)
        .scrollBar(BarState.Auto);
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1);
    }
    .alignItems(HorizontalAlign.Center)
    .height('100%')
    .width('100%')
    .justifyContent(FlexAlign.Start);
  }
}