/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */

import { hilog } from '@kit.PerformanceAnalysisKit';
import { preferences } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';

// 锻炼记录数据结构
export interface ExerciseRecord {
  id: string;
  startTime: number;
  endTime: number;
  exerciseType: string;
  exerciseName: string;
  duration: number;
  distance: number;
  calories: number;
  avgSpeed: number;
  maxSpeed: number;
  createTime: number;
}

// 保存数据参数
export interface SaveExerciseParams {
  exerciseType: string;
  exerciseName: string;
  duration: number;      // 分钟
  distance: number;      // 米
  calories: number;      // 卡路里
  avgSpeed: number;      // 米/秒
}

export class ExerciseSequenceManagement {
  private static context: Context | null = null;
  private static readonly PREF_NAME = 'exercise_data';
  private static readonly KEY_RECORDS = 'exercise_records';

  static init(context: Context): void {
    ExerciseSequenceManagement.context = context;
    hilog.info(0x0000, 'testTag', 'ExerciseSequenceManagement initialized');
  }

  public static async saveData(params?: SaveExerciseParams): Promise<string> {
    if (!ExerciseSequenceManagement.context) {
      return 'Error: ExerciseSequenceManagement not initialized';
    }

    try {
      const options: preferences.Options = { name: ExerciseSequenceManagement.PREF_NAME };
      const pref = preferences.getPreferencesSync(ExerciseSequenceManagement.context, options);

      // 获取现有记录
      const recordsJson = await pref.get(ExerciseSequenceManagement.KEY_RECORDS, '[]') as string;
      const records: ExerciseRecord[] = JSON.parse(recordsJson);

      // 创建新的锻炼记录
      const now = Date.now();
      let newRecord: ExerciseRecord;

      if (params) {
        const durationMs = params.duration * 60 * 1000;
        newRecord = {
          id: `record_${now}`,
          startTime: now - durationMs,
          endTime: now,
          exerciseType: params.exerciseType,
          exerciseName: params.exerciseName,
          duration: durationMs,
          distance: params.distance,
          calories: params.calories,
          avgSpeed: params.avgSpeed,
          maxSpeed: params.avgSpeed * 1.2,
          createTime: now
        };
      } else {
        // 默认记录（兼容旧调用）
        const startTime = 1698040800000;
        const endTime = 1698042600000;
        newRecord = {
          id: `record_${now}`,
          startTime: startTime,
          endTime: endTime,
          exerciseType: 'running',
          exerciseName: '跑步',
          duration: 1800000,
          distance: 2000,
          calories: 20,
          avgSpeed: 5,
          maxSpeed: 6,
          createTime: now
        };
      }

      records.push(newRecord);

      // 保存
      await pref.put(ExerciseSequenceManagement.KEY_RECORDS, JSON.stringify(records));
      await pref.flush();

      hilog.info(0x0000, 'testTag', 'Succeeded in saving data.');
      return `保存成功！\n` +
        `─────────────────\n` +
        `记录ID: ${newRecord.id}\n` +
        `运动类型: ${newRecord.exerciseName}\n` +
        `运动时长: ${params ? params.duration : 30} 分钟\n` +
        `运动距离: ${newRecord.distance} 米\n` +
        `消耗热量: ${newRecord.calories} 卡路里\n` +
        `平均速度: ${newRecord.avgSpeed.toFixed(2)} 米/秒\n` +
        `─────────────────`;
    } catch (err) {
      const e = err as Error;
      hilog.error(0x0000, 'testTag', `Failed to save data. message: ${e.message}`);
      return `保存失败: ${e.message}`;
    }
  }

  public static async readData(): Promise<string> {
    if (!ExerciseSequenceManagement.context) {
      return 'Error: ExerciseSequenceManagement not initialized';
    }

    try {
      const options: preferences.Options = { name: ExerciseSequenceManagement.PREF_NAME };
      const pref = preferences.getPreferencesSync(ExerciseSequenceManagement.context, options);

      const recordsJson = await pref.get(ExerciseSequenceManagement.KEY_RECORDS, '[]') as string;
      const records: ExerciseRecord[] = JSON.parse(recordsJson);

      if (records.length === 0) {
        return '暂无锻炼记录';
      }

      hilog.info(0x0000, 'testTag', 'Succeeded in reading data.');
      let result: string = `读取成功！共 ${records.length} 条记录\n`;
      result += '═══════════════════════════════\n';

      records.forEach((record, index) => {
        const startDate = new Date(record.startTime);
        const endDate = new Date(record.endTime);
        result += `【记录 ${index + 1}】\n`;
        result += `  运动类型: ${record.exerciseName}\n`;
        result += `  开始时间: ${startDate.toLocaleString()}\n`;
        result += `  结束时间: ${endDate.toLocaleString()}\n`;
        result += `  运动时长: ${(record.duration / 60000).toFixed(0)} 分钟\n`;
        result += `  运动距离: ${record.distance} 米\n`;
        result += `  消耗热量: ${record.calories} 卡路里\n`;
        result += `  平均速度: ${record.avgSpeed.toFixed(2)} 米/秒\n`;
        result += '───────────────────────────────\n';
      });

      return result;
    } catch (err) {
      const e = err as Error;
      hilog.error(0x0000, 'testTag', `Failed to read data. message: ${e.message}`);
      return `读取失败: ${e.message}`;
    }
  }

  public static async deleteByRequest(): Promise<string> {
    if (!ExerciseSequenceManagement.context) {
      return 'Error: ExerciseSequenceManagement not initialized';
    }

    try {
      const options: preferences.Options = { name: ExerciseSequenceManagement.PREF_NAME };
      const pref = preferences.getPreferencesSync(ExerciseSequenceManagement.context, options);

      const recordsJson = await pref.get(ExerciseSequenceManagement.KEY_RECORDS, '[]') as string;
      const records: ExerciseRecord[] = JSON.parse(recordsJson);

      if (records.length === 0) {
        return '暂无数据可删除';
      }

      // 删除指定时间范围内的记录
      const startTime = 1698040800000;
      const endTime = 1698042600000;

      const filteredRecords = records.filter(r =>
        !(r.startTime >= startTime && r.endTime <= endTime)
      );

      const deletedCount = records.length - filteredRecords.length;

      await pref.put(ExerciseSequenceManagement.KEY_RECORDS, JSON.stringify(filteredRecords));
      await pref.flush();

      hilog.info(0x0000, 'testTag', 'Succeeded in deleting data.');
      return `删除成功！共删除 ${deletedCount} 条记录`;
    } catch (err) {
      const e = err as Error;
      hilog.error(0x0000, 'testTag', `Failed to delete data. message: ${e.message}`);
      return `删除失败: ${e.message}`;
    }
  }

  public static async deleteByExerciseSequence(): Promise<string> {
    if (!ExerciseSequenceManagement.context) {
      return 'Error: ExerciseSequenceManagement not initialized';
    }

    try {
      const options: preferences.Options = { name: ExerciseSequenceManagement.PREF_NAME };
      const pref = preferences.getPreferencesSync(ExerciseSequenceManagement.context, options);

      const recordsJson = await pref.get(ExerciseSequenceManagement.KEY_RECORDS, '[]') as string;
      const records: ExerciseRecord[] = JSON.parse(recordsJson);

      if (records.length === 0) {
        return '暂无数据可删除';
      }

      // 删除最后一条记录
      const deletedRecord = records.pop();

      await pref.put(ExerciseSequenceManagement.KEY_RECORDS, JSON.stringify(records));
      await pref.flush();

      hilog.info(0x0000, 'testTag', 'Succeeded in deleting data.');
      return `删除成功！\n已删除记录: ${deletedRecord?.exerciseName} (${deletedRecord?.id})`;
    } catch (err) {
      const e = err as Error;
      hilog.error(0x0000, 'testTag', `Failed to delete data. message: ${e.message}`);
      return `删除失败: ${e.message}`;
    }
  }

  public static async deleteAll(): Promise<string> {
    if (!ExerciseSequenceManagement.context) {
      return 'Error: ExerciseSequenceManagement not initialized';
    }

    try {
      const options: preferences.Options = { name: ExerciseSequenceManagement.PREF_NAME };
      const pref = preferences.getPreferencesSync(ExerciseSequenceManagement.context, options);

      const recordsJson = await pref.get(ExerciseSequenceManagement.KEY_RECORDS, '[]') as string;
      const records: ExerciseRecord[] = JSON.parse(recordsJson);
      const count = records.length;

      await pref.put(ExerciseSequenceManagement.KEY_RECORDS, '[]');
      await pref.flush();

      hilog.info(0x0000, 'testTag', 'Succeeded in deleting all data.');
      return `删除成功！共删除 ${count} 条记录`;
    } catch (err) {
      const e = err as Error;
      hilog.error(0x0000, 'testTag', `Failed to delete all data. message: ${e.message}`);
      return `删除失败: ${e.message}`;
    }
  }
}
