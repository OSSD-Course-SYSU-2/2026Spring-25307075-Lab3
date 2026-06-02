/*
 * 体重与BMI管理
 */

import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

// 体重记录
interface WeightRecord {
  date: string;
  weight: number;
}

// 自定义弹窗 - 记录体重
@CustomDialog
struct WeightDialog {
  controller: CustomDialogController;
  @State inputWeightStr: string = '';
  onConfirm: (weight: number) => void = () => {};
  
  build() {
    Column() {
      Text('记录体重')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1e293b')
        .margin({ top: 20, bottom: 20 })

      Column() {
        Text('体重 (kg)')
          .fontSize(14)
          .fontColor('#64748b')
          .width('100%')
          .margin({ bottom: 8 })

        TextInput({ placeholder: '请输入体重', text: $$this.inputWeightStr })
          .width('100%')
          .height(45)
          .type(InputType.Number)
          .borderRadius(12)
          .backgroundColor('#f8fafc')
      }
      .width('90%')
      .margin({ bottom: 20 })

      Row({ space: 12 }) {
        Button('取消')
          .layoutWeight(1)
          .height(45)
          .fontSize(16)
          .fontColor('#64748b')
          .backgroundColor('#f1f5f9')
          .borderRadius(12)
          .onClick(() => {
            this.controller.close();
          })

        Button('保存')
          .layoutWeight(1)
          .height(45)
          .fontSize(16)
          .fontColor(Color.White)
          .backgroundColor('#667eea')
          .borderRadius(12)
          .onClick(() => {
            const weight = parseFloat(this.inputWeightStr);
            if (isNaN(weight) || weight <= 0) {
              return;
            }
            this.onConfirm(weight);
            this.controller.close();
          })
      }
      .width('90%')
    }
    .width('100%')
    .padding({ bottom: 20 })
    .alignItems(HorizontalAlign.Center)
  }
}

@Entry
@Component
struct WeightIndex {
  @State currentWeight: number = 65.0; // 当前体重
  @State targetWeight: number = 60.0; // 目标体重
  @State userHeight: number = 0; // 身高(cm) - 0表示未设置
  @State hasSetHeight: boolean = false; // 是否已设置身高
  @State bmi: number = 0; // BMI值
  @State bmiCategory: string = ''; // BMI分类
  @State weightRecords: WeightRecord[] = []; // 体重记录历史
  
  @State showHeightDialog: boolean = false; // 身高设置弹窗
  @State inputWeight: number = 65.0; // 输入的体重
  @State inputHeight: number = 170; // 输入的身高
  
  // 体重弹窗控制器
  weightDialogController: CustomDialogController = new CustomDialogController({
    builder: WeightDialog({
      inputWeightStr: this.currentWeight.toString(),
      onConfirm: (weight: number) => {
        this.handleWeightConfirm(weight);
      }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Bottom,
    customStyle: true
  });

  aboutToAppear() {
    this.loadData();
    this.calculateBMI();
  }

  async loadData() {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const prefs = await preferences.getPreferences(context, 'weight_prefs');
      
      this.currentWeight = await prefs.get('currentWeight', 65.0) as number;
      this.targetWeight = await prefs.get('targetWeight', 60.0) as number;
      
      // 检查是否已设置身高
      const savedHeight = await prefs.get('userHeight', 0) as number;
      if (savedHeight > 0) {
        this.userHeight = savedHeight;
        this.hasSetHeight = true;
      } else {
        this.hasSetHeight = false;
      }
      
      // 加载历史记录（从Preferences）
      const savedRecords = await prefs.get('weightRecords', '[]') as string;
      try {
        this.weightRecords = JSON.parse(savedRecords);
      } catch (e) {
        this.weightRecords = [];
      }
      
      if (this.hasSetHeight) {
        this.calculateBMI();
      }
    } catch (error) {
      console.error('Load weight data failed:', error);
    }
  }

  calculateBMI() {
    // 如果身高未设置，不计算BMI
    if (!this.hasSetHeight || this.userHeight <= 0) {
      this.bmi = 0;
      this.bmiCategory = '请先设置身高';
      return;
    }
    
    // BMI = 体重(kg) / 身高(m)的平方
    const heightInMeters = this.userHeight / 100;
    this.bmi = this.currentWeight / (heightInMeters * heightInMeters);
    
    // BMI分类
    if (this.bmi < 18.5) {
      this.bmiCategory = '偏瘦';
    } else if (this.bmi < 24) {
      this.bmiCategory = '正常';
    } else if (this.bmi < 28) {
      this.bmiCategory = '超重';
    } else {
      this.bmiCategory = '肥胖';
    }
  }

  // 处理体重确认
  async handleWeightConfirm(weight: number) {
    this.currentWeight = weight;
    this.calculateBMI();
    
    // 添加到历史记录
    const today = new Date().toISOString().split('T')[0];
    this.weightRecords.push({
      date: today,
      weight: weight
    });
    
    await this.saveWeight();
  }

  async saveWeight() {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const prefs = await preferences.getPreferences(context, 'weight_prefs');
      
      await prefs.put('currentWeight', this.currentWeight);
      await prefs.put('targetWeight', this.targetWeight);
      await prefs.put('userHeight', this.userHeight);
      await prefs.put('weightRecords', JSON.stringify(this.weightRecords));
      await prefs.flush();
    } catch (error) {
      console.error('Save weight data failed:', error);
    }
  }

  getBMIColor(): string {
    if (this.bmi < 18.5) {
      return '#3b82f6'; // 蓝色 - 偏瘦
    } else if (this.bmi < 24) {
      return '#10b981'; // 绿色 - 正常
    } else if (this.bmi < 28) {
      return '#f59e0b'; // 橙色 - 超重
    } else {
      return '#ef4444'; // 红色 - 肥胖
    }
  }

  build() {
    Column() {
      // 顶部标题
      Row() {
        Text('⚖️')
          .fontSize(24)
        Text('体重管理')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1e293b')
          .margin({ left: 8 })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 20, bottom: 15 })

      Scroll() {
        Column({ space: 16 }) {
          // 身高未设置提示卡片
          if (!this.hasSetHeight) {
            this.HeightSetupCard()
          }

          // BMI卡片
          this.BMICard()

          // 体重信息卡片
          this.WeightInfoCard()

          // 体重趋势图
          this.WeightTrendCard()

          // 历史记录
          this.HistoryCard()
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 20 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f8fafc')
    .bindSheet($$this.showHeightDialog, this.HeightSetupSheet(), {
      height: 280,
      dragBar: true,
      backgroundColor: Color.White
    })
  }

  // BMI卡片
  @Builder
  BMICard() {
    Column() {
      Text('BMI 指数')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1e293b')
        .width('100%')
        .margin({ bottom: 16 })

      Row() {
        Column() {
          Text(`${this.bmi.toFixed(1)}`)
            .fontSize(48)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getBMIColor())

          Text(this.bmiCategory)
            .fontSize(16)
            .fontColor(this.getBMIColor())
            .margin({ top: 4 })
        }
        .layoutWeight(1)

        Column({ space: 8 }) {
          this.BMIScaleItem('偏瘦', '< 18.5', '#3b82f6', this.bmi < 18.5)
          this.BMIScaleItem('正常', '18.5-24', '#10b981', this.bmi >= 18.5 && this.bmi < 24)
          this.BMIScaleItem('超重', '24-28', '#f59e0b', this.bmi >= 24 && this.bmi < 28)
          this.BMIScaleItem('肥胖', '> 28', '#ef4444', this.bmi >= 28)
        }
        .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 8, color: '#10000000', offsetX: 0, offsetY: 2 })
  }

  @Builder
  BMIScaleItem(label: string, range: string, color: string, isActive: boolean) {
    Row() {
      Circle()
        .width(12)
        .height(12)
        .fill(isActive ? color : '#e2e8f0')
      
      Column() {
        Text(label)
          .fontSize(12)
          .fontColor(isActive ? color : '#64748b')
        Text(range)
          .fontSize(10)
          .fontColor('#94a3b8')
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 8 })
    }
    .width('100%')
  }

  // 体重信息卡片
  @Builder
  WeightInfoCard() {
    Column() {
      Row() {
        Column() {
          Text('当前体重')
            .fontSize(12)
            .fontColor('#94a3b8')
          Row() {
            Text(`${this.currentWeight}`)
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor('#667eea')
            Text(' kg')
              .fontSize(14)
              .fontColor('#64748b')
          }
          .margin({ top: 4 })
          
          // 修改体重按钮
          Text('修改')
            .fontSize(12)
            .fontColor('#667eea')
            .margin({ top: 4 })
            .onClick(() => {
              // 重新创建弹窗控制器，传入当前体重
              this.weightDialogController = new CustomDialogController({
                builder: WeightDialog({
                  inputWeightStr: this.currentWeight.toString(),
                  onConfirm: (weight: number) => {
                    this.handleWeightConfirm(weight);
                  }
                }),
                autoCancel: true,
                alignment: DialogAlignment.Bottom,
                customStyle: true
              });
              this.weightDialogController.open();
            })
        }
        .layoutWeight(1)

        Column() {
          Text('目标体重')
            .fontSize(12)
            .fontColor('#94a3b8')
          Row() {
            Text(`${this.targetWeight}`)
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor('#10b981')
            Text(' kg')
              .fontSize(14)
              .fontColor('#64748b')
          }
          .margin({ top: 4 })
        }
        .layoutWeight(1)

        Column() {
          Text('身高')
            .fontSize(12)
            .fontColor('#94a3b8')
          Row() {
            if (this.hasSetHeight) {
              Text(`${this.userHeight}`)
                .fontSize(28)
                .fontWeight(FontWeight.Bold)
                .fontColor('#f59e0b')
              Text(' cm')
                .fontSize(14)
                .fontColor('#64748b')
            } else {
              Text('未设置')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#94a3b8')
            }
          }
          .margin({ top: 4 })
          
          // 修改身高按钮（仅在已设置时显示）
          if (this.hasSetHeight) {
            Text('修改')
              .fontSize(12)
              .fontColor('#667eea')
              .margin({ top: 4 })
              .onClick(() => {
                this.inputHeight = this.userHeight;
                this.showHeightDialog = true;
              })
          }
        }
        .layoutWeight(1)
      }
      .width('100%')

      // 距离目标的进度
      Row() {
        Text(`距离目标还需减重 ${(this.currentWeight - this.targetWeight).toFixed(1)} kg`)
          .fontSize(12)
          .fontColor('#64748b')
      }
      .width('100%')
      .margin({ top: 16 })
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 8, color: '#10000000', offsetX: 0, offsetY: 2 })
  }

  // 体重趋势图
  @Builder
  WeightTrendCard() {
    Column() {
      Row() {
        Text('体重趋势')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1e293b')
        Blank()
        Text('近6周')
          .fontSize(12)
          .fontColor('#94a3b8')
      }
      .width('100%')
      .margin({ bottom: 16 })

      if (this.weightRecords.length === 0) {
        // 无数据提示
        Column() {
          Text('暂无数据')
            .fontSize(14)
            .fontColor('#94a3b8')
          Text('点击上方"修改"按钮开始记录')
            .fontSize(12)
            .fontColor('#94a3b8')
            .margin({ top: 8 })
        }
        .width('100%')
        .height(100)
        .justifyContent(FlexAlign.Center)
      } else {
        // 简化的折线图（用柱状图代替）
        Row({ space: 8 }) {
          ForEach(this.weightRecords.slice(-6), (record: WeightRecord, index: number) => {
            Column() {
              Text(`${record.weight}`)
                .fontSize(10)
                .fontColor('#64748b')
              
              Column()
                .width(24)
                .height((record.weight - 60) * 10) // 根据体重计算高度
                .backgroundColor(index === this.weightRecords.length - 1 ? '#667eea' : '#c7d2fe')
                .borderRadius(4)
              
              Text(`${index + 1}周`)
                .fontSize(10)
                .fontColor('#94a3b8')
                .margin({ top: 4 })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)
          })
        }
        .width('100%')
        .height(120)
        .justifyContent(FlexAlign.End)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 8, color: '#10000000', offsetX: 0, offsetY: 2 })
  }

  // 历史记录
  @Builder
  HistoryCard() {
    Column() {
      Text('历史记录')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1e293b')
        .width('100%')
        .margin({ bottom: 12 })

      if (this.weightRecords.length === 0) {
        // 无数据提示
        Column() {
          Text('暂无记录')
            .fontSize(14)
            .fontColor('#94a3b8')
        }
        .width('100%')
        .height(60)
        .justifyContent(FlexAlign.Center)
      } else {
        Column({ space: 8 }) {
          ForEach(this.weightRecords.slice().reverse(), (record: WeightRecord) => {
            Row() {
              Text('📅')
                .fontSize(16)
              Text(record.date)
                .fontSize(14)
                .fontColor('#1e293b')
                .margin({ left: 8 })
              Blank()
              Text(`${record.weight} kg`)
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#667eea')
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#f8fafc')
            .borderRadius(8)
          })
        }
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 8, color: '#10000000', offsetX: 0, offsetY: 2 })
  }

  // 身高设置引导卡片
  @Builder
  HeightSetupCard() {
    Column() {
      Row() {
        Text('📏')
          .fontSize(40)
      }
      .margin({ bottom: 16 })

      Text('请先设置您的身高')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1e293b')
        .margin({ bottom: 8 })

      Text('身高信息将用于计算BMI指数')
        .fontSize(14)
        .fontColor('#64748b')
        .margin({ bottom: 20 })

      Button('设置身高')
        .width('60%')
        .height(45)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
        .backgroundColor('#667eea')
        .borderRadius(22)
        .onClick(() => {
          this.showHeightDialog = true;
        })
    }
    .width('100%')
    .padding(24)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 8, color: '#10000000', offsetX: 0, offsetY: 2 })
    .border({ width: 2, color: '#667eea' })
  }

  // 身高设置弹窗
  @Builder
  HeightSetupSheet() {
    Column() {
      Text('设置身高')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1e293b')
        .margin({ top: 20, bottom: 20 })

      Column() {
        Text('身高 (cm)')
          .fontSize(14)
          .fontColor('#64748b')
          .width('100%')
          .margin({ bottom: 8 })

        TextInput({ placeholder: '请输入身高' })
          .width('100%')
          .height(45)
          .type(InputType.Number)
          .borderRadius(12)
          .backgroundColor('#f8fafc')
          .onChange((value: string) => {
            this.inputHeight = parseFloat(value) || 0;
          })
      }
      .width('90%')
      .margin({ bottom: 20 })

      Row({ space: 12 }) {
        Button('取消')
          .layoutWeight(1)
          .height(45)
          .fontSize(16)
          .fontColor('#64748b')
          .backgroundColor('#f1f5f9')
          .borderRadius(12)
          .onClick(() => {
            this.showHeightDialog = false;
          })

        Button('确认')
          .layoutWeight(1)
          .height(45)
          .fontSize(16)
          .fontColor(Color.White)
          .backgroundColor('#667eea')
          .borderRadius(12)
          .onClick(async () => {
            if (this.inputHeight > 0) {
              this.userHeight = this.inputHeight;
              this.hasSetHeight = true;
              this.calculateBMI();
              await this.saveWeight();
              this.showHeightDialog = false;
            }
          })
      }
      .width('90%')

      Blank()
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
  }
}
