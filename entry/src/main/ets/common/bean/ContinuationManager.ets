import { distributedDeviceManager } from '@kit.DistributedServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Want, StartOptions, common } from '@kit.AbilityKit';

const TAG = 'ContinuationManager';
const DOMAIN = 0x0000;

export interface ContinuationResult {
  success: boolean;
  deviceId?: string;
  deviceName?: string;
  message: string;
}

export class ContinuationManager {
  private static instance: ContinuationManager | null = null;
  private deviceManager: distributedDeviceManager.DeviceManager | null = null;
  private context: common.UIAbilityContext | null = null;
  private continuationRegister: string = '';
  private onDeviceStateChangeCallback: ((deviceId: string, deviceName: string) => void) | null = null;

  private constructor() {}

  static getInstance(): ContinuationManager {
    if (!ContinuationManager.instance) {
      ContinuationManager.instance = new ContinuationManager();
    }
    return ContinuationManager.instance;
  }

  init(context: common.UIAbilityContext): void {
    this.context = context;
    try {
      const deviceManager = distributedDeviceManager.createDeviceManager('newapplication');
      this.deviceManager = deviceManager;
      hilog.info(DOMAIN, TAG, 'DeviceManager initialized successfully');
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to create DeviceManager: ${JSON.stringify(error)}`);
    }
  }

  registerContinuation(callback: (deviceId: string, deviceName: string) => void): void {
    if (!this.deviceManager) {
      hilog.error(DOMAIN, TAG, 'DeviceManager not initialized');
      return;
    }

    this.onDeviceStateChangeCallback = callback;
    hilog.info(DOMAIN, TAG, 'Continuation registered successfully');
  }

  unregisterContinuation(): void {
    if (!this.deviceManager) {
      return;
    }

    this.onDeviceStateChangeCallback = null;
    hilog.info(DOMAIN, TAG, 'Continuation unregistered successfully');
  }

  async getAvailableDevices(): Promise<distributedDeviceManager.DeviceBasicInfo[]> {
    if (!this.deviceManager) {
      hilog.error(DOMAIN, TAG, 'DeviceManager not initialized');
      return [];
    }

    try {
      const devices = this.deviceManager.getAvailableDeviceListSync();
      hilog.info(DOMAIN, TAG, `Available devices: ${devices.length}`);
      return devices;
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to get available devices: ${JSON.stringify(error)}`);
      return [];
    }
  }

  async startContinuation(deviceId: string): Promise<ContinuationResult> {
    if (!this.context) {
      const result: ContinuationResult = {
        success: false,
        message: 'Context not initialized'
      };
      return result;
    }

    try {
      const want: Want = {
        deviceId: deviceId,
        bundleName: 'newapplication',
        abilityName: 'EntryAbility',
        moduleName: 'entry'
      };

      const startOptions: StartOptions = {
        windowMode: 0
      };

      await this.context.startAbility(want, startOptions);
      
      const result: ContinuationResult = {
        success: true,
        deviceId: deviceId,
        message: 'Continuation started successfully'
      };
      
      hilog.info(DOMAIN, TAG, `Continuation started to device: ${deviceId}`);
      return result;
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to start continuation: ${JSON.stringify(error)}`);
      const result: ContinuationResult = {
        success: false,
        message: `Failed to start continuation: ${error}`
      };
      return result;
    }
  }

  async startContinuationWithRestore(deviceId: string, restoreData: Record<string, Object>): Promise<ContinuationResult> {
    if (!this.context) {
      const result: ContinuationResult = {
        success: false,
        message: 'Context not initialized'
      };
      return result;
    }

    try {
      const want: Want = {
        deviceId: deviceId,
        bundleName: 'newapplication',
        abilityName: 'EntryAbility',
        moduleName: 'entry',
        parameters: {
          'ohos.extra.param.key.continueData': restoreData
        }
      };

      const startOptions: StartOptions = {
        windowMode: 0
      };

      await this.context.startAbility(want, startOptions);
      
      const result: ContinuationResult = {
        success: true,
        deviceId: deviceId,
        message: 'Continuation with restore started successfully'
      };
      
      hilog.info(DOMAIN, TAG, `Continuation with restore started to device: ${deviceId}`);
      return result;
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to start continuation with restore: ${JSON.stringify(error)}`);
      const result: ContinuationResult = {
        success: false,
        message: `Failed to start continuation with restore: ${error}`
      };
      return result;
    }
  }

  getDeviceManager(): distributedDeviceManager.DeviceManager | null {
    return this.deviceManager;
  }

  onDeviceStateChange(callback: distributedDeviceManager.DeviceStateChange): void {
    if (!this.deviceManager) {
      hilog.error(DOMAIN, TAG, 'DeviceManager not initialized');
      return;
    }

    hilog.info(DOMAIN, TAG, 'Device state change listener registered');
  }

  offDeviceStateChange(callback: distributedDeviceManager.DeviceStateChange): void {
    if (!this.deviceManager) {
      return;
    }

    hilog.info(DOMAIN, TAG, 'Device state change listener unregistered');
  }

  destroy(): void {
    this.unregisterContinuation();
    if (this.deviceManager) {
      try {
        distributedDeviceManager.releaseDeviceManager(this.deviceManager);
        this.deviceManager = null;
        hilog.info(DOMAIN, TAG, 'DeviceManager released successfully');
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Failed to release DeviceManager: ${JSON.stringify(error)}`);
      }
    }
    ContinuationManager.instance = null;
  }
}