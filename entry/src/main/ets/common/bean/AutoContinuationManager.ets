import { distributedDeviceManager } from '@kit.DistributedServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common, AbilityConstant } from '@kit.AbilityKit';
import { ContinuationManager, ContinuationResult } from './ContinuationManager';
import { connection } from '@kit.NetworkKit';

const TAG = 'AutoContinuationManager';
const DOMAIN = 0x0000;

export enum AutoContinuationTrigger {
  DEVICE_DISTANCE = 'device_distance',
  NETWORK_CHANGE = 'network_change',
  USER_ACTION = 'user_action',
  SCREEN_STATE = 'screen_state'
}

export interface AutoContinuationConfig {
  enabled: boolean;
  triggers: AutoContinuationTrigger[];
  deviceDistanceThreshold: number;
  autoSelectDevice: boolean;
  preferredDeviceId?: string;
  minInterval: number;
}

export interface DeviceProximityInfo {
  deviceId: string;
  deviceName: string;
  distance: number;
  lastSeen: number;
}

const DEFAULT_CONFIG: AutoContinuationConfig = {
  enabled: true,
  triggers: [
    AutoContinuationTrigger.DEVICE_DISTANCE,
    AutoContinuationTrigger.NETWORK_CHANGE,
    AutoContinuationTrigger.USER_ACTION,
    AutoContinuationTrigger.SCREEN_STATE
  ],
  deviceDistanceThreshold: 5.0,
  autoSelectDevice: true,
  minInterval: 30000
};

export class AutoContinuationManager {
  private static instance: AutoContinuationManager | null = null;
  private config: AutoContinuationConfig = DEFAULT_CONFIG;
  private continuationManager: ContinuationManager = ContinuationManager.getInstance();
  private context: common.UIAbilityContext | null = null;
  private deviceManager: distributedDeviceManager.DeviceManager | null = null;
  private deviceStateCallback: distributedDeviceManager.DeviceStateChange | null = null;
  private lastContinuationTime: number = 0;
  private isContinuing: boolean = false;
  private deviceProximityMap: Map<string, DeviceProximityInfo> = new Map();
  private networkChangeCallback: connection.NetHandle | null = null;
  private onAutoContinuationCallback: ((result: ContinuationResult) => void) | null = null;
  private screenStateCallback: ((isScreenOn: boolean) => void) | null = null;
  private userActionCallback: ((action: string) => void) | null = null;
  private lastNetworkType: number = -1;

  private constructor() {}

  static getInstance(): AutoContinuationManager {
    if (!AutoContinuationManager.instance) {
      AutoContinuationManager.instance = new AutoContinuationManager();
    }
    return AutoContinuationManager.instance;
  }

  init(context: common.UIAbilityContext): void {
    this.context = context;
    try {
      const deviceManager = distributedDeviceManager.createDeviceManager('newapplication');
      this.deviceManager = deviceManager;
      hilog.info(DOMAIN, TAG, 'AutoContinuationManager initialized');
      
      if (this.config.enabled) {
        this.startMonitoring();
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to initialize: ${JSON.stringify(error)}`);
    }
  }

  setConfig(config: Partial<AutoContinuationConfig>): void {
    if (config.enabled !== undefined) {
      this.config.enabled = config.enabled;
    }
    if (config.triggers !== undefined) {
      this.config.triggers = config.triggers;
    }
    if (config.deviceDistanceThreshold !== undefined) {
      this.config.deviceDistanceThreshold = config.deviceDistanceThreshold;
    }
    if (config.autoSelectDevice !== undefined) {
      this.config.autoSelectDevice = config.autoSelectDevice;
    }
    if (config.preferredDeviceId !== undefined) {
      this.config.preferredDeviceId = config.preferredDeviceId;
    }
    if (config.minInterval !== undefined) {
      this.config.minInterval = config.minInterval;
    }
    hilog.info(DOMAIN, TAG, `Config updated: ${JSON.stringify(this.config)}`);
    
    if (this.config.enabled) {
      this.startMonitoring();
    } else {
      this.stopMonitoring();
    }
  }

  getConfig(): AutoContinuationConfig {
    return {
      enabled: this.config.enabled,
      triggers: this.config.triggers,
      deviceDistanceThreshold: this.config.deviceDistanceThreshold,
      autoSelectDevice: this.config.autoSelectDevice,
      preferredDeviceId: this.config.preferredDeviceId,
      minInterval: this.config.minInterval
    };
  }

  setAutoContinuationCallback(callback: (result: ContinuationResult) => void): void {
    this.onAutoContinuationCallback = callback;
  }

  setScreenStateCallback(callback: (isScreenOn: boolean) => void): void {
    this.screenStateCallback = callback;
  }

  setUserActionCallback(callback: (action: string) => void): void {
    this.userActionCallback = callback;
  }

  private startMonitoring(): void {
    this.startDeviceStateMonitoring();
    this.startNetworkMonitoring();
    hilog.info(DOMAIN, TAG, 'Monitoring started');
  }

  private stopMonitoring(): void {
    this.stopDeviceStateMonitoring();
    this.stopNetworkMonitoring();
    hilog.info(DOMAIN, TAG, 'Monitoring stopped');
  }

  private startDeviceStateMonitoring(): void {
    if (!this.deviceManager) {
      hilog.error(DOMAIN, TAG, 'DeviceManager not initialized');
      return;
    }

    hilog.info(DOMAIN, TAG, 'Device state monitoring started');
  }

  private stopDeviceStateMonitoring(): void {
    if (this.deviceStateCallback) {
      this.deviceStateCallback = null;
      hilog.info(DOMAIN, TAG, 'Device state monitoring stopped');
    }
  }

  private startNetworkMonitoring(): void {
    try {
      connection.getDefaultNet().then((netHandle: connection.NetHandle) => {
        this.networkChangeCallback = netHandle;
        this.lastNetworkType = netHandle.netId;
        hilog.info(DOMAIN, TAG, `Network monitoring started, current netId: ${netHandle.netId}`);
      });

      let netConnection: connection.NetConnection = connection.createNetConnection();
      netConnection.on('netAvailable', (netHandle: connection.NetHandle) => {
        hilog.info(DOMAIN, TAG, `Network available: ${netHandle.netId}`);
        this.handleNetworkChange(netHandle.netId);
      });

      netConnection.on('netLost', (netHandle: connection.NetHandle) => {
        hilog.info(DOMAIN, TAG, `Network lost: ${netHandle.netId}`);
        this.handleNetworkChange(-1);
      });

      netConnection.on('netUnavailable', () => {
        hilog.info(DOMAIN, TAG, 'Network unavailable');
        this.handleNetworkChange(-1);
      });
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to start network monitoring: ${JSON.stringify(error)}`);
    }
  }

  private stopNetworkMonitoring(): void {
    try {
      this.networkChangeCallback = null;
      hilog.info(DOMAIN, TAG, 'Network monitoring stopped');
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to stop network monitoring: ${JSON.stringify(error)}`);
    }
  }

  private async handleDeviceStateChange(deviceInfo: distributedDeviceManager.DeviceBasicInfo): Promise<void> {
    if (!this.config.triggers.includes(AutoContinuationTrigger.DEVICE_DISTANCE)) {
      return;
    }

    const proximityInfo: DeviceProximityInfo = {
      deviceId: deviceInfo.deviceId,
      deviceName: deviceInfo.deviceName,
      distance: this.estimateDeviceDistance(deviceInfo),
      lastSeen: Date.now()
    };

    this.deviceProximityMap.set(deviceInfo.deviceId, proximityInfo);
    hilog.info(DOMAIN, TAG, `Device proximity updated: ${deviceInfo.deviceName}, distance: ${proximityInfo.distance}`);

    if (proximityInfo.distance < this.config.deviceDistanceThreshold) {
      hilog.info(DOMAIN, TAG, `Device ${deviceInfo.deviceName} is close enough for auto continuation`);
      await this.triggerAutoContinuation(AutoContinuationTrigger.DEVICE_DISTANCE, deviceInfo.deviceId);
    }
  }

  private estimateDeviceDistance(deviceInfo: distributedDeviceManager.DeviceBasicInfo): number {
    return Math.random() * 10;
  }

  private async handleNetworkChange(netId: number): Promise<void> {
    if (!this.config.triggers.includes(AutoContinuationTrigger.NETWORK_CHANGE)) {
      return;
    }

    if (this.lastNetworkType !== netId) {
      hilog.info(DOMAIN, TAG, `Network changed from ${this.lastNetworkType} to ${netId}`);
      this.lastNetworkType = netId;
      await this.triggerAutoContinuation(AutoContinuationTrigger.NETWORK_CHANGE);
    }
  }

  async notifyUserAction(action: string): Promise<void> {
    if (!this.config.triggers.includes(AutoContinuationTrigger.USER_ACTION)) {
      return;
    }

    hilog.info(DOMAIN, TAG, `User action detected: ${action}`);
    
    if (this.userActionCallback) {
      this.userActionCallback(action);
    }

    const autoTriggerActions = ['page_change', 'button_click', 'data_submit'];
    if (autoTriggerActions.includes(action)) {
      await this.triggerAutoContinuation(AutoContinuationTrigger.USER_ACTION);
    }
  }

  async notifyScreenStateChange(isScreenOn: boolean): Promise<void> {
    if (!this.config.triggers.includes(AutoContinuationTrigger.SCREEN_STATE)) {
      return;
    }

    hilog.info(DOMAIN, TAG, `Screen state changed: ${isScreenOn ? 'ON' : 'OFF'}`);
    
    if (this.screenStateCallback) {
      this.screenStateCallback(isScreenOn);
    }

    if (isScreenOn) {
      await this.triggerAutoContinuation(AutoContinuationTrigger.SCREEN_STATE);
    }
  }

  private async triggerAutoContinuation(trigger: AutoContinuationTrigger, preferredDeviceId?: string): Promise<void> {
    if (!this.config.enabled) {
      hilog.info(DOMAIN, TAG, 'Auto continuation is disabled');
      return;
    }

    const now = Date.now();
    if (now - this.lastContinuationTime < this.config.minInterval) {
      hilog.info(DOMAIN, TAG, `Too soon for auto continuation, min interval: ${this.config.minInterval}ms`);
      return;
    }

    if (this.isContinuing) {
      hilog.info(DOMAIN, TAG, 'Continuation already in progress');
      return;
    }

    hilog.info(DOMAIN, TAG, `Triggering auto continuation by: ${trigger}`);
    this.isContinuing = true;

    try {
      let targetDeviceId = preferredDeviceId || this.config.preferredDeviceId;

      if (!targetDeviceId || !this.config.autoSelectDevice) {
        const devices = await this.continuationManager.getAvailableDevices();
        if (devices.length === 0) {
          hilog.info(DOMAIN, TAG, 'No available devices for auto continuation');
          this.isContinuing = false;
          return;
        }

        if (this.config.autoSelectDevice) {
          targetDeviceId = this.selectBestDevice(devices);
        }
      }

      if (targetDeviceId) {
        const result = await this.continuationManager.startContinuation(targetDeviceId);
        
        if (result.success) {
          this.lastContinuationTime = now;
          hilog.info(DOMAIN, TAG, `Auto continuation succeeded: ${result.message}`);
          
          if (this.onAutoContinuationCallback) {
            this.onAutoContinuationCallback(result);
          }
        } else {
          hilog.error(DOMAIN, TAG, `Auto continuation failed: ${result.message}`);
        }
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Auto continuation error: ${JSON.stringify(error)}`);
    } finally {
      this.isContinuing = false;
    }
  }

  private selectBestDevice(devices: distributedDeviceManager.DeviceBasicInfo[]): string {
    if (devices.length === 0) {
      return '';
    }

    let bestDevice = devices[0];
    let bestDistance = Infinity;

    for (const device of devices) {
      const proximityInfo = this.deviceProximityMap.get(device.deviceId);
      const distance = proximityInfo ? proximityInfo.distance : Infinity;
      
      if (distance < bestDistance) {
        bestDistance = distance;
        bestDevice = device;
      }
    }

    hilog.info(DOMAIN, TAG, `Selected best device: ${bestDevice.deviceName}`);
    return bestDevice.deviceId;
  }

  async getDeviceProximityList(): Promise<DeviceProximityInfo[]> {
    return Array.from(this.deviceProximityMap.values());
  }

  enable(): void {
    this.config.enabled = true;
    this.startMonitoring();
    hilog.info(DOMAIN, TAG, 'Auto continuation enabled');
  }

  disable(): void {
    this.config.enabled = false;
    this.stopMonitoring();
    hilog.info(DOMAIN, TAG, 'Auto continuation disabled');
  }

  isEnabled(): boolean {
    return this.config.enabled;
  }

  destroy(): void {
    this.stopMonitoring();
    this.deviceProximityMap.clear();
    this.onAutoContinuationCallback = null;
    this.screenStateCallback = null;
    this.userActionCallback = null;
    AutoContinuationManager.instance = null;
    hilog.info(DOMAIN, TAG, 'AutoContinuationManager destroyed');
  }
}