/*
 * 健康数据可视化仪表盘
 */

import { ExerciseSequenceManagement, ExerciseRecord } from '../common/bean/ExerciseSequenceManagement';
import { CheckInManager } from '../common/bean/CheckInManager';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct DashboardIndex {
  @State exerciseRecords: ExerciseRecord[] = [];
  @State checkInDays: number[] = []; // 打卡日期数组
  @State weekData: number[] = [0, 0, 0, 0, 0, 0, 0]; // 本周每天的运动时长
  @State exerciseTypeStats: Map<string, number> = new Map(); // 运动类型统计
  @State totalCalories: number = 0;
  @State totalDuration: number = 0;
  @State exerciseCount: number = 0; // 运动次数

  async aboutToAppear() {
    await this.loadData();
  }

  async loadData() {
    // 加载运动记录
    const records = await this.loadExerciseRecords();
    this.exerciseRecords = records;
    
    // 加载打卡数据
    await this.loadCheckInData();
    
    // 计算统计数据
    this.calculateStats();
  }

  async loadExerciseRecords(): Promise<ExerciseRecord[]> {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const options: preferences.Options = { name: 'exercise_data' };
      const pref = await preferences.getPreferences(context, options);
      
      const recordsJson = await pref.get('exercise_records', '[]') as string;
      const records: ExerciseRecord[] = JSON.parse(recordsJson);
      
      return records;
    } catch (error) {
      console.error('Load exercise records failed:', error);
      return [];
    }
  }

  async loadCheckInData() {
    // 获取最近30天的打卡记录
    const count = await CheckInManager.getContinuousCount();
    // 模拟打卡日期数据
    const today = new Date();
    for (let i = 0; i < count; i++) {
      const date = new Date(today);
      date.setDate(date.getDate() - i);
      this.checkInDays.push(date.getDate());
    }
  }

  calculateStats() {
    // 重置数据
    this.weekData = [0, 0, 0, 0, 0, 0, 0];
    this.exerciseTypeStats.clear();
    this.totalCalories = 0;
    this.totalDuration = 0;
    this.exerciseCount = 0;
    
    if (this.exerciseRecords.length === 0) {
      return;
    }
    
    // 运动次数
    this.exerciseCount = this.exerciseRecords.length;
    
    // 获取本周的开始和结束时间
    const now = new Date();
    const dayOfWeek = now.getDay(); // 0-6, 0是周日
    const weekStart = new Date(now);
    weekStart.setDate(now.getDate() - dayOfWeek);
    weekStart.setHours(0, 0, 0, 0);
    
    // 计算各项统计数据
    this.exerciseRecords.forEach(record => {
      // 计算总数据
      const durationMinutes = record.duration / 60000; // 毫秒转分钟
      this.totalDuration += durationMinutes;
      this.totalCalories += record.calories;
      
      // 计算运动类型分布
      const currentCount = this.exerciseTypeStats.get(record.exerciseName) || 0;
      this.exerciseTypeStats.set(record.exerciseName, currentCount + 1);
      
      // 计算本周运动数据
      const recordDate = new Date(record.startTime);
      if (recordDate >= weekStart) {
        const daysDiff = Math.floor((recordDate.getTime() - weekStart.getTime()) / (1000 * 60 * 60 * 24));
        if (daysDiff >= 0 && daysDiff < 7) {
          this.weekData[daysDiff] += durationMinutes;
        }
      }
    });
  }

  build() {
    Column() {
      // 顶部标题
      Row() {
        Text('📊')
          .fontSize(24)
        Text('健康数据仪表盘')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1e293b')
          .margin({ left: 8 })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 20, bottom: 15 })

      Scroll() {
        Column({ space: 16 }) {
          // 数据概览卡片
          this.StatsOverviewCard()

          // 本周运动趋势图
          this.WeekTrendCard()

          // 打卡日历热力图
          this.CheckInCalendarCard()

          // 运动类型分布
          this.ExerciseTypeDistributionCard()
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

  // 数据概览卡片
  @Builder
  StatsOverviewCard() {
    Column() {
      Text('数据概览')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1e293b')
        .width('100%')
        .margin({ bottom: 12 })

      Row() {
        // 总运动时长
        Column() {
          Text('⏱️')
            .fontSize(28)
          Text(`${this.totalDuration}`)
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#667eea')
            .margin({ top: 4 })
          Text('总时长(分钟)')
            .fontSize(12)
            .fontColor('#64748b')
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .padding(12)
        .backgroundColor('#f1f5f9')
        .borderRadius(12)

        // 总消耗热量
        Column() {
          Text('🔥')
            .fontSize(28)
          Text(`${this.totalCalories}`)
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#f59e0b')
            .margin({ top: 4 })
          Text('总热量(卡路里)')
            .fontSize(12)
            .fontColor('#64748b')
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .padding(12)
        .backgroundColor('#f1f5f9')
        .borderRadius(12)
        .margin({ left: 12 })

        // 运动次数
        Column() {
          Text('🏃')
            .fontSize(28)
          Text(`${this.exerciseCount}`)
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#10b981')
            .margin({ top: 4 })
          Text('运动次数')
            .fontSize(12)
            .fontColor('#64748b')
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .padding(12)
        .backgroundColor('#f1f5f9')
        .borderRadius(12)
        .margin({ left: 12 })
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 8, color: '#10000000', offsetX: 0, offsetY: 2 })
  }

  // 本周运动趋势图
  @Builder
  WeekTrendCard() {
    Column() {
      Row() {
        Text('本周运动趋势')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1e293b')
        Blank()
        Text('单位: 分钟')
          .fontSize(12)
          .fontColor('#94a3b8')
      }
      .width('100%')
      .margin({ bottom: 16 })

      // 简化的柱状图
      Row({ space: 8 }) {
        ForEach(['一', '二', '三', '四', '五', '六', '日'], (day: string, index: number) => {
          Column() {
            // 柱状条
            Column()
              .width(24)
              .height(this.weekData[index] * 1.5) // 根据数据调整高度
              .backgroundColor(index === new Date().getDay() - 1 ? '#667eea' : '#c7d2fe')
              .borderRadius(4)
            
            Text(day)
              .fontSize(12)
              .fontColor('#64748b')
              .margin({ top: 8 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
        })
      }
      .width('100%')
      .height(120)
      .justifyContent(FlexAlign.End)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 8, color: '#10000000', offsetX: 0, offsetY: 2 })
  }

  // 打卡日历热力图
  @Builder
  CheckInCalendarCard() {
    Column() {
      Row() {
        Text('打卡日历')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1e293b')
        Blank()
        Text('最近30天')
          .fontSize(12)
          .fontColor('#94a3b8')
      }
      .width('100%')
      .margin({ bottom: 16 })

      // 日历网格
      Grid() {
        ForEach([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], (item: number) => {
          GridItem() {
            Column() {
              Text(`${item + 1}`)
                .fontSize(10)
                .fontColor(this.checkInDays.includes(item + 1) ? Color.White : '#94a3b8')
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .backgroundColor(this.checkInDays.includes(item + 1) ? '#667eea' : '#f1f5f9')
            .borderRadius(4)
          }
        })
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
      .rowsGap(6)
      .columnsGap(6)
      .height(100)
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 8, color: '#10000000', offsetX: 0, offsetY: 2 })
  }

  // 运动类型分布
  @Builder
  ExerciseTypeDistributionCard() {
    Column() {
      Text('运动类型分布')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1e293b')
        .width('100%')
        .margin({ bottom: 16 })

      Column({ space: 12 }) {
        if (this.exerciseTypeStats.size === 0) {
          // 没有数据时显示默认类型，全为0%
          ForEach([
            ['跑步', 0],
            ['篮球', 0],
            ['骑行', 0],
            ['其他', 0]
          ], (item: [string, number]) => {
            Row() {
              Text(this.getExerciseIcon(item[0]))
                .fontSize(20)
              Text(item[0])
                .fontSize(14)
                .fontColor('#1e293b')
                .margin({ left: 8 })
              Blank()
              // 进度条
              Row() {
                Row()
                  .width(`${item[1]}%`)
                  .height('100%')
                  .backgroundColor(this.getExerciseColor(item[0]))
                  .borderRadius(4)
              }
              .width(100)
              .height(8)
              .backgroundColor('#f1f5f9')
              .borderRadius(4)
              .margin({ left: 12 })

              Text(`${item[1]}%`)
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#64748b')
                .width(40)
                .textAlign(TextAlign.End)
            }
            .width('100%')
          })
        } else {
          // 有数据时显示实际分布
          ForEach(Array.from(this.exerciseTypeStats.entries()), (item: [string, number]) => {
            Row() {
              Text(this.getExerciseIcon(item[0]))
                .fontSize(20)
              Text(item[0])
                .fontSize(14)
                .fontColor('#1e293b')
                .margin({ left: 8 })
              Blank()
              // 进度条
              Row() {
                Row()
                  .width(`${this.getExerciseTypePercentage(item[0])}%`)
                  .height('100%')
                  .backgroundColor(this.getExerciseColor(item[0]))
                  .borderRadius(4)
              }
              .width(100)
              .height(8)
              .backgroundColor('#f1f5f9')
              .borderRadius(4)
              .margin({ left: 12 })

              Text(`${this.getExerciseTypePercentage(item[0])}%`)
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#64748b')
                .width(40)
                .textAlign(TextAlign.End)
            }
            .width('100%')
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

  // 获取运动类型百分比
  getExerciseTypePercentage(type: string): number {
    if (this.exerciseCount === 0) {
      return 0;
    }
    const count = this.exerciseTypeStats.get(type) || 0;
    return Math.round((count / this.exerciseCount) * 100);
  }

  // 获取运动图标
  getExerciseIcon(type: string): string {
    const iconMap: Record<string, string> = {
      '跑步': '🏃',
      '篮球': '🏀',
      '骑行': '🚴',
      '游泳': '🏊',
      '其他': '📝'
    };
    return iconMap[type] || '📝';
  }

  // 获取运动颜色
  getExerciseColor(type: string): string {
    const colorMap: Record<string, string> = {
      '跑步': '#667eea',
      '篮球': '#f59e0b',
      '骑行': '#10b981',
      '游泳': '#3b82f6',
      '其他': '#94a3b8'
    };
    return colorMap[type] || '#94a3b8';
  }
}
