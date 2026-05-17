import { preferences } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { Context } from '@kit.AbilityKit';

interface CheckInResult {
  success: boolean;
  continuousCount: number;
  message: string;
}

export class CheckInManager {
  private static readonly KEY_LAST_DATE = 'lastCheckDate';
  private static readonly KEY_CONTINUOUS_COUNT = 'continuousCount';
  private static context: Context | null = null;

  static init(context: Context): void {
    CheckInManager.context = context;
  }

  private static getTodayStr(): string {
    const now = new Date();
    return `${now.getFullYear()}-${now.getMonth() + 1}-${now.getDate()}`;
  }

  private static getYesterdayStr(): string {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    return `${yesterday.getFullYear()}-${yesterday.getMonth() + 1}-${yesterday.getDate()}`;
  }

  static async saveCheckIn(): Promise<CheckInResult> {
    if (!CheckInManager.context) {
      throw new Error('CheckInManager not initialized!');
    }

    try {
      const options: preferences.Options = { name: 'checkInData' };
      const pref = preferences.getPreferencesSync(CheckInManager.context, options);
      
      const today = CheckInManager.getTodayStr();
      const yesterday = CheckInManager.getYesterdayStr();
      const lastDate = await pref.get(CheckInManager.KEY_LAST_DATE, '') as string;
      let continuousCount = await pref.get(CheckInManager.KEY_CONTINUOUS_COUNT, 0) as number;

      if (lastDate === today) {
        const result: CheckInResult = { success: false, continuousCount, message: '今日已打卡，请明天再来' };
        return result;
      }

      if (lastDate === yesterday) {
        continuousCount = continuousCount + 1;
      } else {
        continuousCount = 1;
      }

      await pref.put(CheckInManager.KEY_LAST_DATE, today);
      await pref.put(CheckInManager.KEY_CONTINUOUS_COUNT, continuousCount);
      await pref.flush();

      const result: CheckInResult = { success: true, continuousCount, message: '打卡成功' };
      return result;
    } catch (err) {
      const e = err as BusinessError;
      console.error(`保存失败: ${e.code} - ${e.message}`);
      const result: CheckInResult = { success: false, continuousCount: 0, message: '打卡失败' };
      return result;
    }
  }

  static async getContinuousCount(): Promise<number> {
    if (!CheckInManager.context) {
      throw new Error('CheckInManager not initialized!');
    }

    try {
      const options: preferences.Options = { name: 'checkInData' };
      const pref = preferences.getPreferencesSync(CheckInManager.context, options);
      return await pref.get(CheckInManager.KEY_CONTINUOUS_COUNT, 0) as number;
    } catch (err) {
      const e = err as BusinessError;
      console.error(`获取失败: ${e.code} - ${e.message}`);
      return 0;
    }
  }

  static async hasCheckedToday(): Promise<boolean> {
    if (!CheckInManager.context) {
      throw new Error('CheckInManager not initialized!');
    }

    try {
      const options: preferences.Options = { name: 'checkInData' };
      const pref = preferences.getPreferencesSync(CheckInManager.context, options);
      const lastDate = await pref.get(CheckInManager.KEY_LAST_DATE, '') as string;
      return lastDate === CheckInManager.getTodayStr();
    } catch (err) {
      const e = err as BusinessError;
      console.error(`获取失败: ${e.code} - ${e.message}`);
      return false;
    }
  }
}
