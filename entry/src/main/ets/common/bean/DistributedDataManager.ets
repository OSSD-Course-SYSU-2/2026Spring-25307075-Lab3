import { distributedDataObject } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';

const TAG = 'DistributedDataManager';
const DOMAIN = 0x0000;

export interface DistributedCheckInData {
  lastCheckDate: string;
  continuousCount: number;
  deviceId: string;
  updateTime: number;
}

export interface DistributedExerciseData {
  records: string;
  deviceId: string;
  updateTime: number;
}

export class DistributedDataManager {
  private static instance: DistributedDataManager | null = null;
  private context: common.UIAbilityContext | null = null;
  private checkInDataObject: distributedDataObject.DataObject | null = null;
  private exerciseDataObject: distributedDataObject.DataObject | null = null;

  private constructor() {}

  static getInstance(): DistributedDataManager {
    if (!DistributedDataManager.instance) {
      DistributedDataManager.instance = new DistributedDataManager();
    }
    return DistributedDataManager.instance;
  }

  init(context: common.UIAbilityContext): void {
    this.context = context;
    hilog.info(DOMAIN, TAG, 'DistributedDataManager initialized');
  }

  async createDistributedCheckInData(initialData: DistributedCheckInData): Promise<void> {
    try {
      const sessionId = 'checkin_session_' + Date.now();
      this.checkInDataObject = distributedDataObject.create(context, initialData, sessionId);
      
      this.checkInDataObject.on('change', (sessionId: string, fields: Array<string>) => {
        hilog.info(DOMAIN, TAG, `CheckIn data changed, sessionId: ${sessionId}, fields: ${fields.join(',')}`);
      });

      hilog.info(DOMAIN, TAG, 'Distributed check-in data created successfully');
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to create distributed check-in data: ${JSON.stringify(error)}`);
    }
  }

  async updateDistributedCheckInData(data: Partial<DistributedCheckInData>): Promise<void> {
    if (!this.checkInDataObject) {
      hilog.error(DOMAIN, TAG, 'CheckIn data object not initialized');
      return;
    }

    try {
      if (data.lastCheckDate !== undefined) {
        this.checkInDataObject['lastCheckDate'] = data.lastCheckDate;
      }
      if (data.continuousCount !== undefined) {
        this.checkInDataObject['continuousCount'] = data.continuousCount;
      }
      if (data.deviceId !== undefined) {
        this.checkInDataObject['deviceId'] = data.deviceId;
      }
      this.checkInDataObject['updateTime'] = Date.now();

      hilog.info(DOMAIN, TAG, 'Distributed check-in data updated successfully');
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to update distributed check-in data: ${JSON.stringify(error)}`);
    }
  }

  getDistributedCheckInData(): DistributedCheckInData | null {
    if (!this.checkInDataObject) {
      return null;
    }

    return {
      lastCheckDate: this.checkInDataObject['lastCheckDate'] as string,
      continuousCount: this.checkInDataObject['continuousCount'] as number,
      deviceId: this.checkInDataObject['deviceId'] as string,
      updateTime: this.checkInDataObject['updateTime'] as number
    };
  }

  async createDistributedExerciseData(initialData: DistributedExerciseData): Promise<void> {
    try {
      const sessionId = 'exercise_session_' + Date.now();
      this.exerciseDataObject = distributedDataObject.create(context, initialData, sessionId);
      
      this.exerciseDataObject.on('change', (sessionId: string, fields: Array<string>) => {
        hilog.info(DOMAIN, TAG, `Exercise data changed, sessionId: ${sessionId}, fields: ${fields.join(',')}`);
      });

      hilog.info(DOMAIN, TAG, 'Distributed exercise data created successfully');
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to create distributed exercise data: ${JSON.stringify(error)}`);
    }
  }

  async updateDistributedExerciseData(data: Partial<DistributedExerciseData>): Promise<void> {
    if (!this.exerciseDataObject) {
      hilog.error(DOMAIN, TAG, 'Exercise data object not initialized');
      return;
    }

    try {
      if (data.records !== undefined) {
        this.exerciseDataObject['records'] = data.records;
      }
      if (data.deviceId !== undefined) {
        this.exerciseDataObject['deviceId'] = data.deviceId;
      }
      this.exerciseDataObject['updateTime'] = Date.now();

      hilog.info(DOMAIN, TAG, 'Distributed exercise data updated successfully');
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to update distributed exercise data: ${JSON.stringify(error)}`);
    }
  }

  getDistributedExerciseData(): DistributedExerciseData | null {
    if (!this.exerciseDataObject) {
      return null;
    }

    return {
      records: this.exerciseDataObject['records'] as string,
      deviceId: this.exerciseDataObject['deviceId'] as string,
      updateTime: this.exerciseDataObject['updateTime'] as number
    };
  }

  destroy(): void {
    if (this.checkInDataObject) {
      try {
        this.checkInDataObject.off('change');
        distributedDataObject.destroy(this.checkInDataObject);
        this.checkInDataObject = null;
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Failed to destroy check-in data object: ${JSON.stringify(error)}`);
      }
    }

    if (this.exerciseDataObject) {
      try {
        this.exerciseDataObject.off('change');
        distributedDataObject.destroy(this.exerciseDataObject);
        this.exerciseDataObject = null;
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Failed to destroy exercise data object: ${JSON.stringify(error)}`);
      }
    }

    DistributedDataManager.instance = null;
    hilog.info(DOMAIN, TAG, 'DistributedDataManager destroyed');
  }
}