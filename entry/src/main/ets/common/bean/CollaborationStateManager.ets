import { distributedDeviceManager } from '@kit.DistributedServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import { distributedDataObject } from '@kit.ArkData';

const TAG = 'CollaborationStateManager';
const DOMAIN = 0x0000;

export enum DeviceRole {
  MASTER = 'master',
  SLAVE = 'slave',
  STANDALONE = 'standalone'
}

export enum CollaborationMode {
  MIRROR = 'mirror',
  EXTENSION = 'extension',
  HANDOFF = 'handoff'
}

export interface DeviceCollaborationInfo {
  deviceId: string;
  deviceName: string;
  deviceType: string;
  role: DeviceRole;
  isOnline: boolean;
  lastSyncTime: number;
  capabilities: string[];
}

export interface CollaborationState {
  sessionId: string;
  mode: CollaborationMode;
  masterDeviceId: string;
  slaveDevices: string[];
  allDevices: DeviceCollaborationInfo[];
  isActive: boolean;
  createTime: number;
}

export interface CollaborationConfig {
  autoElectMaster: boolean;
  maxSlaveDevices: number;
  syncInterval: number;
  enableAutoSync: boolean;
}

const DEFAULT_CONFIG: CollaborationConfig = {
  autoElectMaster: true,
  maxSlaveDevices: 3,
  syncInterval: 5000,
  enableAutoSync: true
};

export class CollaborationStateManager {
  private static instance: CollaborationStateManager | null = null;
  private context: common.UIAbilityContext | null = null;
  private deviceManager: distributedDeviceManager.DeviceManager | null = null;
  private config: CollaborationConfig = DEFAULT_CONFIG;
  private currentState: CollaborationState | null = null;
  private localDeviceId: string = '';
  private localDeviceRole: DeviceRole = DeviceRole.STANDALONE;
  private collaborationDataObject: distributedDataObject.DataObject | null = null;
  private syncTimer: number = -1;
  private onStateChangeCallback: ((state: CollaborationState) => void) | null = null;
  private onRoleChangeCallback: ((role: DeviceRole) => void) | null = null;
  private onDeviceJoinCallback: ((device: DeviceCollaborationInfo) => void) | null = null;
  private onDeviceLeaveCallback: ((deviceId: string) => void) | null = null;

  private constructor() {}

  static getInstance(): CollaborationStateManager {
    if (!CollaborationStateManager.instance) {
      CollaborationStateManager.instance = new CollaborationStateManager();
    }
    return CollaborationStateManager.instance;
  }

  init(context: common.UIAbilityContext): void {
    this.context = context;
    try {
      const deviceManager = distributedDeviceManager.createDeviceManager('newapplication');
      this.deviceManager = deviceManager;
      
      const localDeviceId = deviceManager.getLocalDeviceId();
      this.localDeviceId = localDeviceId;
      
      hilog.info(DOMAIN, TAG, `CollaborationStateManager initialized, local device: ${this.localDeviceId}`);
      
      this.initCollaborationState();
      this.startDeviceMonitoring();
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to initialize: ${JSON.stringify(error)}`);
    }
  }

  private initCollaborationState(): void {
    const sessionId = 'collaboration_' + Date.now();
    
    this.currentState = {
      sessionId: sessionId,
      mode: CollaborationMode.HANDOFF,
      masterDeviceId: this.localDeviceId,
      slaveDevices: [],
      allDevices: [{
        deviceId: this.localDeviceId,
        deviceName: 'Local Device',
        deviceType: 'phone',
        role: DeviceRole.MASTER,
        isOnline: true,
        lastSyncTime: Date.now(),
        capabilities: ['continuation', 'data_sync', 'ui_mirror']
      }],
      isActive: false,
      createTime: Date.now()
    };
    
    this.localDeviceRole = DeviceRole.MASTER;
    hilog.info(DOMAIN, TAG, 'Collaboration state initialized');
  }

  private startDeviceMonitoring(): void {
    if (!this.deviceManager) {
      return;
    }

    hilog.info(DOMAIN, TAG, 'Device monitoring started');
  }

  private handleDeviceStateChange(deviceInfo: distributedDeviceManager.DeviceBasicInfo): void {
    if (!this.currentState) {
      return;
    }

    const existingDevice = this.currentState.allDevices.find(d => d.deviceId === deviceInfo.deviceId);
    
    if (existingDevice) {
      existingDevice.isOnline = true;
      existingDevice.lastSyncTime = Date.now();
      hilog.info(DOMAIN, TAG, `Device updated: ${deviceInfo.deviceName}`);
    } else {
      const newDevice: DeviceCollaborationInfo = {
        deviceId: deviceInfo.deviceId,
        deviceName: deviceInfo.deviceName,
        deviceType: deviceInfo.deviceType || 'phone',
        role: DeviceRole.SLAVE,
        isOnline: true,
        lastSyncTime: Date.now(),
        capabilities: ['continuation', 'data_sync']
      };
      
      this.currentState.allDevices.push(newDevice);
      
      if (this.currentState.slaveDevices.length < this.config.maxSlaveDevices) {
        this.currentState.slaveDevices.push(deviceInfo.deviceId);
      }
      
      hilog.info(DOMAIN, TAG, `New device joined: ${deviceInfo.deviceName}`);
      
      if (this.onDeviceJoinCallback) {
        this.onDeviceJoinCallback(newDevice);
      }
    }
    
    if (this.onStateChangeCallback && this.currentState) {
      this.onStateChangeCallback(this.currentState);
    }
  }

  setConfig(config: Partial<CollaborationConfig>): void {
    if (config.autoElectMaster !== undefined) {
      this.config.autoElectMaster = config.autoElectMaster;
    }
    if (config.maxSlaveDevices !== undefined) {
      this.config.maxSlaveDevices = config.maxSlaveDevices;
    }
    if (config.syncInterval !== undefined) {
      this.config.syncInterval = config.syncInterval;
    }
    if (config.enableAutoSync !== undefined) {
      this.config.enableAutoSync = config.enableAutoSync;
    }
    hilog.info(DOMAIN, TAG, `Config updated: ${JSON.stringify(this.config)}`);
  }

  async startCollaboration(mode: CollaborationMode = CollaborationMode.HANDOFF): Promise<boolean> {
    if (!this.currentState) {
      hilog.error(DOMAIN, TAG, 'Collaboration state not initialized');
      return false;
    }

    if (this.currentState.isActive) {
      hilog.info(DOMAIN, TAG, 'Collaboration already active');
      return true;
    }

    try {
      this.currentState.mode = mode;
      this.currentState.isActive = true;
      
      await this.createCollaborationDataObject();
      
      if (this.config.enableAutoSync) {
        this.startAutoSync();
      }
      
      hilog.info(DOMAIN, TAG, `Collaboration started, mode: ${mode}`);
      
      if (this.onStateChangeCallback && this.currentState) {
        this.onStateChangeCallback(this.currentState);
      }
      
      return true;
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to start collaboration: ${JSON.stringify(error)}`);
      return false;
    }
  }

  stopCollaboration(): void {
    if (!this.currentState || !this.currentState.isActive) {
      return;
    }

    this.currentState.isActive = false;
    this.stopAutoSync();
    this.destroyCollaborationDataObject();
    
    hilog.info(DOMAIN, TAG, 'Collaboration stopped');
    
    if (this.onStateChangeCallback && this.currentState) {
      this.onStateChangeCallback(this.currentState);
    }
  }

  private async createCollaborationDataObject(): Promise<void> {
    if (!this.context || !this.currentState) {
      return;
    }

    try {
      interface CollaborationInitialData {
        sessionId: string;
        masterDeviceId: string;
        slaveDevices: string;
        mode: CollaborationMode;
        timestamp: number;
      }
      const initialData: CollaborationInitialData = {
        sessionId: this.currentState.sessionId,
        masterDeviceId: this.currentState.masterDeviceId,
        slaveDevices: JSON.stringify(this.currentState.slaveDevices),
        mode: this.currentState.mode,
        timestamp: Date.now()
      };
      
      this.collaborationDataObject = distributedDataObject.create(this.context, initialData);
      
      this.collaborationDataObject.on('change', (sessionId: string, fields: Array<string>) => {
        hilog.info(DOMAIN, TAG, `Collaboration data changed: ${fields.join(',')}`);
        this.handleCollaborationDataChange(fields);
      });
      
      hilog.info(DOMAIN, TAG, 'Collaboration data object created');
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to create collaboration data object: ${JSON.stringify(error)}`);
    }
  }

  private handleCollaborationDataChange(fields: Array<string>): void {
    if (!this.collaborationDataObject || !this.currentState) {
      return;
    }

    if (fields.includes('masterDeviceId')) {
      const newMasterId = this.collaborationDataObject['masterDeviceId'] as string;
      if (newMasterId !== this.currentState.masterDeviceId) {
        this.currentState.masterDeviceId = newMasterId;
        
        if (newMasterId === this.localDeviceId) {
          this.updateLocalRole(DeviceRole.MASTER);
        } else if (this.localDeviceRole === DeviceRole.MASTER) {
          this.updateLocalRole(DeviceRole.SLAVE);
        }
        
        hilog.info(DOMAIN, TAG, `Master device changed to: ${newMasterId}`);
      }
    }
    
    if (this.onStateChangeCallback && this.currentState) {
      this.onStateChangeCallback(this.currentState);
    }
  }

  private updateLocalRole(newRole: DeviceRole): void {
    if (this.localDeviceRole === newRole) {
      return;
    }

    const oldRole = this.localDeviceRole;
    this.localDeviceRole = newRole;
    
    const localDevice = this.currentState?.allDevices.find(d => d.deviceId === this.localDeviceId);
    if (localDevice) {
      localDevice.role = newRole;
    }
    
    hilog.info(DOMAIN, TAG, `Local role changed from ${oldRole} to ${newRole}`);
    
    if (this.onRoleChangeCallback) {
      this.onRoleChangeCallback(newRole);
    }
  }

  private startAutoSync(): void {
    if (this.syncTimer !== -1) {
      return;
    }

    this.syncTimer = setInterval(() => {
      this.syncCollaborationState();
    }, this.config.syncInterval);
    
    hilog.info(DOMAIN, TAG, 'Auto sync started');
  }

  private stopAutoSync(): void {
    if (this.syncTimer !== -1) {
      clearInterval(this.syncTimer);
      this.syncTimer = -1;
      hilog.info(DOMAIN, TAG, 'Auto sync stopped');
    }
  }

  private syncCollaborationState(): void {
    if (!this.collaborationDataObject || !this.currentState) {
      return;
    }

    try {
      this.collaborationDataObject['timestamp'] = Date.now();
      hilog.info(DOMAIN, TAG, 'Collaboration state synced');
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to sync state: ${JSON.stringify(error)}`);
    }
  }

  private destroyCollaborationDataObject(): void {
    if (this.collaborationDataObject) {
      try {
        this.collaborationDataObject.off('change');
        this.collaborationDataObject = null;
        hilog.info(DOMAIN, TAG, 'Collaboration data object destroyed');
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Failed to destroy data object: ${JSON.stringify(error)}`);
      }
    }
  }

  electMaster(): string {
    if (!this.currentState || !this.config.autoElectMaster) {
      return this.currentState?.masterDeviceId || '';
    }

    const onlineDevices = this.currentState.allDevices.filter(d => d.isOnline);
    
    if (onlineDevices.length === 0) {
      return this.localDeviceId;
    }

    const devicePriority: Record<string, number> = {
      'tablet': 3,
      'phone': 2,
      'tv': 1,
      'wearable': 0
    };
    
    onlineDevices.sort((a, b) => {
      const priorityA = devicePriority[a.deviceType] || 0;
      const priorityB = devicePriority[b.deviceType] || 0;
      return priorityB - priorityA;
    });
    
    const newMaster = onlineDevices[0];
    
    if (newMaster.deviceId !== this.currentState.masterDeviceId) {
      this.currentState.masterDeviceId = newMaster.deviceId;
      
      if (newMaster.deviceId === this.localDeviceId) {
        this.updateLocalRole(DeviceRole.MASTER);
      } else if (this.localDeviceRole === DeviceRole.MASTER) {
        this.updateLocalRole(DeviceRole.SLAVE);
      }
      
      hilog.info(DOMAIN, TAG, `Master elected: ${newMaster.deviceName}`);
    }
    
    return newMaster.deviceId;
  }

  addSlaveDevice(deviceId: string): boolean {
    if (!this.currentState) {
      return false;
    }

    if (this.currentState.slaveDevices.length >= this.config.maxSlaveDevices) {
      hilog.error(DOMAIN, TAG, 'Max slave devices reached');
      return false;
    }

    if (this.currentState.slaveDevices.includes(deviceId)) {
      return true;
    }

    this.currentState.slaveDevices.push(deviceId);
    
    const device = this.currentState.allDevices.find(d => d.deviceId === deviceId);
    if (device) {
      device.role = DeviceRole.SLAVE;
    }
    
    hilog.info(DOMAIN, TAG, `Slave device added: ${deviceId}`);
    
    if (this.onStateChangeCallback && this.currentState) {
      this.onStateChangeCallback(this.currentState);
    }
    
    return true;
  }

  removeSlaveDevice(deviceId: string): void {
    if (!this.currentState) {
      return;
    }

    const index = this.currentState.slaveDevices.indexOf(deviceId);
    if (index > -1) {
      this.currentState.slaveDevices.splice(index, 1);
      
      const device = this.currentState.allDevices.find(d => d.deviceId === deviceId);
      if (device) {
        device.role = DeviceRole.STANDALONE;
      }
      
      hilog.info(DOMAIN, TAG, `Slave device removed: ${deviceId}`);
      
      if (this.onDeviceLeaveCallback) {
        this.onDeviceLeaveCallback(deviceId);
      }
      
      if (this.onStateChangeCallback && this.currentState) {
        this.onStateChangeCallback(this.currentState);
      }
    }
  }

  setCollaborationMode(mode: CollaborationMode): void {
    if (!this.currentState) {
      return;
    }

    this.currentState.mode = mode;
    hilog.info(DOMAIN, TAG, `Collaboration mode changed to: ${mode}`);
    
    if (this.onStateChangeCallback && this.currentState) {
      this.onStateChangeCallback(this.currentState);
    }
  }

  getCollaborationState(): CollaborationState | null {
    if (!this.currentState) {
      return null;
    }
    return {
      sessionId: this.currentState.sessionId,
      mode: this.currentState.mode,
      masterDeviceId: this.currentState.masterDeviceId,
      slaveDevices: this.currentState.slaveDevices,
      allDevices: this.currentState.allDevices,
      isActive: this.currentState.isActive,
      createTime: this.currentState.createTime
    };
  }

  getLocalDeviceRole(): DeviceRole {
    return this.localDeviceRole;
  }

  isMaster(): boolean {
    return this.localDeviceRole === DeviceRole.MASTER;
  }

  isSlave(): boolean {
    return this.localDeviceRole === DeviceRole.SLAVE;
  }

  getMasterDeviceId(): string {
    return this.currentState?.masterDeviceId || '';
  }

  getSlaveDevices(): string[] {
    return this.currentState?.slaveDevices || [];
  }

  getAllDevices(): DeviceCollaborationInfo[] {
    return this.currentState?.allDevices || [];
  }

  setOnStateChangeCallback(callback: (state: CollaborationState) => void): void {
    this.onStateChangeCallback = callback;
  }

  setOnRoleChangeCallback(callback: (role: DeviceRole) => void): void {
    this.onRoleChangeCallback = callback;
  }

  setOnDeviceJoinCallback(callback: (device: DeviceCollaborationInfo) => void): void {
    this.onDeviceJoinCallback = callback;
  }

  setOnDeviceLeaveCallback(callback: (deviceId: string) => void): void {
    this.onDeviceLeaveCallback = callback;
  }

  destroy(): void {
    this.stopCollaboration();
    
    if (this.deviceManager) {
      try {
        distributedDeviceManager.releaseDeviceManager(this.deviceManager);
        this.deviceManager = null;
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Failed to release device manager: ${JSON.stringify(error)}`);
      }
    }
    
    this.currentState = null;
    this.onStateChangeCallback = null;
    this.onRoleChangeCallback = null;
    this.onDeviceJoinCallback = null;
    this.onDeviceLeaveCallback = null;
    
    CollaborationStateManager.instance = null;
    hilog.info(DOMAIN, TAG, 'CollaborationStateManager destroyed');
  }
}