/*
 * 运动目标与成就系统
 */

import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

// 成就定义
interface Achievement {
  id: string;
  name: string;
  icon: string;
  description: string;
  condition: string;
  unlocked: boolean;
  progress: number;
  target: number;
}

// 自定义弹窗 - 设置目标
@CustomDialog
struct GoalDialog {
  controller: CustomDialogController;
  @State dailyGoalStr: string = '';
  @State weeklyGoalStr: string = '';
  @State calorieGoalStr: string = '';
  onConfirm: (daily: number, weekly: number, calorie: number) => void = () => {};
  
  build() {
    Column() {
      Text('设置目标')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1e293b')
        .margin({ top: 20, bottom: 20 })

      // 每日运动目标
      Column() {
        Text('每日运动目标 (分钟)')
          .fontSize(14)
          .fontColor('#64748b')
          .width('100%')
          .margin({ bottom: 8 })

        TextInput({ placeholder: '请输入每日运动目标', text: $$this.dailyGoalStr })
          .width('100%')
          .height(45)
          .type(InputType.Number)
          .borderRadius(12)
          .backgroundColor('#f8fafc')
      }
      .width('90%')
      .margin({ bottom: 16 })

      // 每周运动目标
      Column() {
        Text('每周运动目标 (分钟)')
          .fontSize(14)
          .fontColor('#64748b')
          .width('100%')
          .margin({ bottom: 8 })

        TextInput({ placeholder: '请输入每周运动目标', text: $$this.weeklyGoalStr })
          .width('100%')
          .height(45)
          .type(InputType.Number)
          .borderRadius(12)
          .backgroundColor('#f8fafc')
      }
      .width('90%')
      .margin({ bottom: 16 })

      // 每日卡路里目标
      Column() {
        Text('每日卡路里目标 (卡路里)')
          .fontSize(14)
          .fontColor('#64748b')
          .width('100%')
          .margin({ bottom: 8 })

        TextInput({ placeholder: '请输入每日卡路里目标', text: $$this.calorieGoalStr })
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
            const daily = parseFloat(this.dailyGoalStr) || 30;
            const weekly = parseFloat(this.weeklyGoalStr) || 150;
            const calorie = parseFloat(this.calorieGoalStr) || 200;
            
            this.onConfirm(daily, weekly, calorie);
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
struct GoalsIndex {
  @State dailyGoal: number = 30; // 每日运动目标（分钟）
  @State weeklyGoal: number = 150; // 每周运动目标（分钟）
  @State calorieGoal: number = 200; // 每日卡路里目标
  
  @State todayDuration: number = 0; // 今日已运动时长
  @State weekDuration: number = 0; // 本周已运动时长
  @State todayCalories: number = 0; // 今日已消耗热量
  
  @State userLevel: string = '运动新手'; // 用户等级
  @State totalPoints: number = 0; // 总积分
  
  @State achievements: Achievement[] = [];
  
  // 目标设置弹窗控制器
  goalDialogController: CustomDialogController = new CustomDialogController({
    builder: GoalDialog({
      dailyGoalStr: this.dailyGoal.toString(),
      weeklyGoalStr: this.weeklyGoal.toString(),
      calorieGoalStr: this.calorieGoal.toString(),
      onConfirm: (daily: number, weekly: number, calorie: number) => {
        this.handleGoalConfirm(daily, weekly, calorie);
      }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Bottom,
    customStyle: true
  });

  aboutToAppear() {
    this.initAchievements();
    this.loadGoals();
  }

  initAchievements() {
    this.achievements = [
      {
        id: 'check_7',
        name: '坚持一周',
        icon: '🌟',
        description: '连续打卡7天',
        condition: '连续打卡7天',
        unlocked: false,
        progress: 0,
        target: 7
      },
      {
        id: 'check_30',
        name: '月度冠军',
        icon: '🏆',
        description: '连续打卡30天',
        condition: '连续打卡30天',
        unlocked: false,
        progress: 0,
        target: 30
      },
      {
        id: 'exercise_100',
        name: '运动百次',
        icon: '💯',
        description: '累计运动100次',
        condition: '累计运动100次',
        unlocked: false,
        progress: 0,
        target: 100
      },
      {
        id: 'calorie_10000',
        name: '热量杀手',
        icon: '🔥',
        description: '累计消耗10000卡路里',
        condition: '累计消耗10000卡路里',
        unlocked: false,
        progress: 0,
        target: 10000
      },
      {
        id: 'variety_5',
        name: '全能选手',
        icon: '🎯',
        description: '尝试5种不同运动',
        condition: '尝试5种不同运动',
        unlocked: false,
        progress: 0,
        target: 5
      },
      {
        id: 'early_bird',
        name: '早起鸟儿',
        icon: '🌅',
        description: '早间运动10次',
        condition: '早间运动10次',
        unlocked: false,
        progress: 0,
        target: 10
      }
    ];
  }

  async loadGoals() {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const prefs = await preferences.getPreferences(context, 'goals_prefs');
      
      this.dailyGoal = await prefs.get('dailyGoal', 30) as number;
      this.weeklyGoal = await prefs.get('weeklyGoal', 150) as number;
      this.calorieGoal = await prefs.get('calorieGoal', 200) as number;
    } catch (error) {
      console.error('Load goals failed:', error);
    }
  }

  async saveGoals() {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const prefs = await preferences.getPreferences(context, 'goals_prefs');
      
      await prefs.put('dailyGoal', this.dailyGoal);
      await prefs.put('weeklyGoal', this.weeklyGoal);
      await prefs.put('calorieGoal', this.calorieGoal);
      await prefs.flush();
    } catch (error) {
      console.error('Save goals failed:', error);
    }
  }

  // 处理目标确认
  async handleGoalConfirm(daily: number, weekly: number, calorie: number) {
    this.dailyGoal = daily;
    this.weeklyGoal = weekly;
    this.calorieGoal = calorie;
    await this.saveGoals();
  }

  build() {
    Column() {
      // 顶部标题
      Row() {
        Text('🎯')
          .fontSize(24)
        Text('目标与成就')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1e293b')
          .margin({ left: 8 })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 20, bottom: 15 })

      Scroll() {
        Column({ space: 16 }) {
          // 用户等级卡片
          this.UserLevelCard()

          // 今日目标进度
          this.TodayGoalsCard()

          // 本周目标进度
          this.WeeklyGoalCard()

          // 成就徽章
          this.AchievementsCard()
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
  }

  // 用户等级卡片
  @Builder
  UserLevelCard() {
    Column() {
      Row() {
        Column() {
          Text('当前等级')
            .fontSize(12)
            .fontColor('#94a3b8')
          Text(this.userLevel)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#667eea')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column() {
          Text('总积分')
            .fontSize(12)
            .fontColor('#94a3b8')
          Text(`${this.totalPoints}`)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#f59e0b')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')

      // 等级进度条
      Column() {
        Row() {
          Text('距离下一等级还需')
            .fontSize(12)
            .fontColor('#64748b')
          Text(`${750} 积分`)
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor('#667eea')
            .margin({ left: 4 })
        }
        .width('100%')
        .margin({ bottom: 8 })

        Row() {
          Row()
            .width('62%')
            .height('100%')
            .linearGradient({
              angle: 90,
              colors: [['#667eea', 0.0], ['#764ba2', 1.0]]
            })
            .borderRadius(4)
        }
        .width('100%')
        .height(8)
        .backgroundColor('#e2e8f0')
        .borderRadius(4)
      }
      .width('100%')
      .margin({ top: 16 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 8, color: '#10000000', offsetX: 0, offsetY: 2 })
  }

  // 今日目标进度
  @Builder
  TodayGoalsCard() {
    Column() {
      Row() {
        Text('今日目标')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1e293b')
        Blank()
        Text('设置')
          .fontSize(14)
          .fontColor('#667eea')
          .onClick(() => {
            // 重新创建弹窗控制器，传入当前目标值
            this.goalDialogController = new CustomDialogController({
              builder: GoalDialog({
                dailyGoalStr: this.dailyGoal.toString(),
                weeklyGoalStr: this.weeklyGoal.toString(),
                calorieGoalStr: this.calorieGoal.toString(),
                onConfirm: (daily: number, weekly: number, calorie: number) => {
                  this.handleGoalConfirm(daily, weekly, calorie);
                }
              }),
              autoCancel: true,
              alignment: DialogAlignment.Bottom,
              customStyle: true
            });
            this.goalDialogController.open();
          })
      }
      .width('100%')
      .margin({ bottom: 16 })

      Row({ space: 16 }) {
        // 运动时长目标
        Column() {
          Stack() {
            // 背景圆环
            Circle()
              .width(80)
              .height(80)
              .fill(Color.Transparent)
              .stroke('#e2e8f0')
              .strokeWidth(8)

            // 进度圆环
            Circle()
              .width(80)
              .height(80)
              .fill(Color.Transparent)
              .stroke('#667eea')
              .strokeWidth(8)
              // 简化处理，实际需要计算弧度

            // 中心文字
            Column() {
              Text(`${Math.min(100, Math.round(this.todayDuration / this.dailyGoal * 100))}%`)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#667eea')
            }
          }
          .width(80)
          .height(80)

          Text('运动时长')
            .fontSize(12)
            .fontColor('#64748b')
            .margin({ top: 8 })
          Text(`${this.todayDuration}/${this.dailyGoal}分钟`)
            .fontSize(12)
            .fontColor('#94a3b8')
        }
        .layoutWeight(1)

        // 卡路里目标
        Column() {
          Stack() {
            Circle()
              .width(80)
              .height(80)
              .fill(Color.Transparent)
              .stroke('#e2e8f0')
              .strokeWidth(8)

            Circle()
              .width(80)
              .height(80)
              .fill(Color.Transparent)
              .stroke('#f59e0b')
              .strokeWidth(8)

            Column() {
              Text(`${Math.min(100, Math.round(this.todayCalories / this.calorieGoal * 100))}%`)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#f59e0b')
            }
          }
          .width(80)
          .height(80)

          Text('消耗热量')
            .fontSize(12)
            .fontColor('#64748b')
            .margin({ top: 8 })
          Text(`${this.todayCalories}/${this.calorieGoal}卡`)
            .fontSize(12)
            .fontColor('#94a3b8')
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

  // 本周目标进度
  @Builder
  WeeklyGoalCard() {
    Column() {
      Row() {
        Text('本周目标')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1e293b')
        Blank()
        Text(`${this.weekDuration}/${this.weeklyGoal} 分钟`)
          .fontSize(14)
          .fontColor('#667eea')
      }
      .width('100%')
      .margin({ bottom: 12 })

      // 进度条
      Row() {
        Row()
          .width(`${Math.min(100, this.weekDuration / this.weeklyGoal * 100)}%`)
          .height('100%')
          .linearGradient({
            angle: 90,
            colors: [['#667eea', 0.0], ['#764ba2', 1.0]]
          })
          .borderRadius(8)
      }
      .width('100%')
      .height(12)
      .backgroundColor('#e2e8f0')
      .borderRadius(8)

      Row() {
        Text(`已完成 ${Math.round(this.weekDuration / this.weeklyGoal * 100)}%`)
          .fontSize(12)
          .fontColor('#64748b')
        Blank()
        if (this.weekDuration >= this.weeklyGoal) {
          Text('✅ 已达成')
            .fontSize(12)
            .fontColor('#10b981')
        } else {
          Text(`还需 ${this.weeklyGoal - this.weekDuration} 分钟`)
            .fontSize(12)
            .fontColor('#94a3b8')
        }
      }
      .width('100%')
      .margin({ top: 8 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 8, color: '#10000000', offsetX: 0, offsetY: 2 })
  }

  // 成就徽章
  @Builder
  AchievementsCard() {
    Column() {
      Row() {
        Text('成就徽章')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1e293b')
        Blank()
        Text(`${this.achievements.filter(a => a.unlocked).length}/${this.achievements.length}`)
          .fontSize(14)
          .fontColor('#94a3b8')
      }
      .width('100%')
      .margin({ bottom: 16 })

      Grid() {
        ForEach(this.achievements, (achievement: Achievement) => {
          GridItem() {
            Column() {
              Text(achievement.icon)
                .fontSize(36)
                .opacity(achievement.unlocked ? 1 : 0.3)

              Text(achievement.name)
                .fontSize(12)
                .fontWeight(FontWeight.Medium)
                .fontColor(achievement.unlocked ? '#1e293b' : '#94a3b8')
                .margin({ top: 8 })

              if (!achievement.unlocked) {
                Text(`${achievement.progress}/${achievement.target}`)
                  .fontSize(10)
                  .fontColor('#94a3b8')
                  .margin({ top: 2 })
              }
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .padding(8)
            .backgroundColor(achievement.unlocked ? '#f0fdf4' : '#f8fafc')
            .borderRadius(12)
            .border({
              width: achievement.unlocked ? 2 : 1,
              color: achievement.unlocked ? '#86efac' : '#e2e8f0'
            })
          }
        })
      }
      .columnsTemplate('1fr 1fr 1fr')
      .rowsGap(12)
      .columnsGap(12)
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 8, color: '#10000000', offsetX: 0, offsetY: 2 })
  }
}
