/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */

import { ExerciseSequenceManagement, SaveExerciseParams, ExerciseRecord } from '../common/bean/ExerciseSequenceManagement';

// 运动类型选项
interface ExerciseTypeOption {
  type: string;
  name: string;
  icon: string;
}

@Entry
@Component
struct Index {
  @State log: string = '加载中...';
  @State showSaveDialog: boolean = false;
  @State records: ExerciseRecord[] = [];

  // 表单数据
  @State selectedExerciseIndex: number = 0;
  @State customExerciseName: string = '';
  @State duration: number = 30;
  @State distance: number = 1000;
  @State calories: number = 50;

  // 运动类型列表
  private exerciseTypes: ExerciseTypeOption[] = [
    { type: 'running', name: '跑步', icon: '🏃' },
    { type: 'walking', name: '慢走', icon: '🚶' },
    { type: 'basketball', name: '篮球', icon: '🏀' },
    { type: 'football', name: '足球', icon: '⚽' },
    { type: 'badminton', name: '羽毛球', icon: '🏸' },
    { type: 'table_tennis', name: '乒乓球', icon: '🏓' },
    { type: 'swimming', name: '游泳', icon: '🏊' },
    { type: 'cycling', name: '骑行', icon: '🚴' },
    { type: 'other', name: '其他', icon: '📝' }
  ];

  // 页面加载时自动读取数据
  async aboutToAppear(): Promise<void> {
    await this.loadRecords();
  }

  // 加载记录
  async loadRecords(): Promise<void> {
    this.log = await ExerciseSequenceManagement.readData();
  }

  build() {
    Column() {
      // 标题
      Text($r('app.string.ExerciseSequence'))
        .fontWeight(FontWeight.Bold)
        .fontSize(24)
        .margin({ top: 15, bottom: 10 });

      // 记录列表区域
      Column() {
        Text('运动记录')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .width('90%')
          .margin({ bottom: 8 });

        Scroll() {
          Column() {
            Text(this.log)
              .fontSize(12)
              .textAlign(TextAlign.Start);
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding({ bottom: 20 });
        }
        .width('90%')
        .layoutWeight(1)
        .scrollBar(BarState.Auto);
      }
      .alignItems(HorizontalAlign.Center)
      .layoutWeight(1);

      // 添加记录按钮（放在底部）
      Button('添加记录')
        .width('80%')
        .height(45)
        .fontSize(16)
        .backgroundColor('#4CAF50')
        .margin({ top: 10, bottom: 20 })
        .onClick(() => {
          this.showSaveDialog = true;
        });
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .bindSheet($$this.showSaveDialog, this.saveSheetBuilder(), {
      height: '70%',
      dragBar: true,
      backgroundColor: Color.White,
      onDisappear: () => {
        this.customExerciseName = '';
      }
    })
  }

  @Builder
  saveSheetBuilder() {
    Column() {
      // 标题
      Text('添加运动记录')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 10, bottom: 20 });

      // 运动类型选择
      Column() {
        Text('选择运动类型')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 10 });

        Grid() {
          ForEach(this.exerciseTypes, (item: ExerciseTypeOption, index: number) => {
            GridItem() {
              Column() {
                Text(item.icon)
                  .fontSize(24);
                Text(item.name)
                  .fontSize(12)
                  .margin({ top: 4 });
              }
              .width('100%')
              .height('100%')
              .justifyContent(FlexAlign.Center)
              .borderRadius(8)
              .backgroundColor(this.selectedExerciseIndex === index ? '#E3F2FD' : '#F5F5F5')
              .border({
                width: this.selectedExerciseIndex === index ? 2 : 0,
                color: '#2196F3'
              })
              .onClick(() => {
                this.selectedExerciseIndex = index;
              });
            }
          });
        }
        .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
        .rowsGap(10)
        .columnsGap(10)
        .height(120)
        .width('90%');
      }
      .margin({ bottom: 15 });

      // 其他运动名称输入
      if (this.exerciseTypes[this.selectedExerciseIndex].type === 'other') {
        Column() {
          Text('运动名称')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 8 });
          TextInput({ placeholder: '请输入运动名称', text: $$this.customExerciseName })
            .width('90%')
            .height(40);
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ bottom: 15 });
      }

      // 运动时长
      Column() {
        Row() {
          Text('运动时长')
            .fontSize(16)
            .fontWeight(FontWeight.Medium);
          Blank();
          Text(`${this.duration} 分钟`)
            .fontSize(16)
            .fontColor('#2196F3');
        }
        .width('90%')
        .margin({ bottom: 8 });

        Slider({ value: this.duration, min: 5, max: 180, step: 5 })
          .width('90%')
          .blockColor('#2196F3')
          .trackColor('#E3F2FD')
          .selectedColor('#2196F3')
          .onChange((value: number) => {
            this.duration = Math.round(value);
          });
      }
      .alignItems(HorizontalAlign.Center)
      .margin({ bottom: 15 });

      // 运动距离
      Column() {
        Row() {
          Text('运动距离')
            .fontSize(16)
            .fontWeight(FontWeight.Medium);
          Blank();
          Text(`${this.distance} 米`)
            .fontSize(16)
            .fontColor('#2196F3');
        }
        .width('90%')
        .margin({ bottom: 8 });

        Slider({ value: this.distance, min: 0, max: 10000, step: 100 })
          .width('90%')
          .blockColor('#2196F3')
          .trackColor('#E3F2FD')
          .selectedColor('#2196F3')
          .onChange((value: number) => {
            this.distance = Math.round(value);
          });
      }
      .alignItems(HorizontalAlign.Center)
      .margin({ bottom: 15 });

      // 消耗热量
      Column() {
        Row() {
          Text('消耗热量')
            .fontSize(16)
            .fontWeight(FontWeight.Medium);
          Blank();
          Text(`${this.calories} 卡路里`)
            .fontSize(16)
            .fontColor('#2196F3');
        }
        .width('90%')
        .margin({ bottom: 8 });

        Slider({ value: this.calories, min: 0, max: 1000, step: 10 })
          .width('90%')
          .blockColor('#2196F3')
          .trackColor('#E3F2FD')
          .selectedColor('#2196F3')
          .onChange((value: number) => {
            this.calories = Math.round(value);
          });
      }
      .alignItems(HorizontalAlign.Center)
      .margin({ bottom: 20 });

      // 保存按钮
      Button('保存记录')
        .width('90%')
        .height(50)
        .fontSize(16)
        .backgroundColor('#4CAF50')
        .onClick(async () => {
          const selected = this.exerciseTypes[this.selectedExerciseIndex];
          const exerciseName = selected.type === 'other'
            ? (this.customExerciseName || '自定义运动')
            : selected.name;

          // 计算平均速度 (米/秒)
          const durationSeconds = this.duration * 60;
          const avgSpeed = durationSeconds > 0 ? this.distance / durationSeconds : 0;

          const params: SaveExerciseParams = {
            exerciseType: selected.type,
            exerciseName: exerciseName,
            duration: this.duration,
            distance: this.distance,
            calories: this.calories,
            avgSpeed: avgSpeed
          };

          await ExerciseSequenceManagement.saveData(params);
          this.showSaveDialog = false;
          // 刷新列表
          await this.loadRecords();
        });

      Blank();
    }
    .height('100%')
    .width('100%')
    .alignItems(HorizontalAlign.Center);
  }
}
