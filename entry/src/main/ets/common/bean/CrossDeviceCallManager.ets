import { hilog } from '@kit.PerformanceAnalysisKit';
import { common, Want, AbilityConstant } from '@kit.AbilityKit';
import { distributedDeviceManager } from '@kit.DistributedServiceKit';
import { distributedDataObject } from '@kit.ArkData';
import { CollaborationStateManager } from './CollaborationStateManager';

const TAG = 'CrossDeviceCallManager';
const DOMAIN = 0x0000;

export interface CrossDeviceCallRequest {
  callId: string;
  methodName: string;
  params: Record<string, Object>;
  targetDeviceId: string;
  sourceDeviceId: string;
  timestamp: number;
  timeout: number;
}

export interface CrossDeviceCallResponse {
  callId: string;
  success: boolean;
  result?: Object;
  error?: string;
  timestamp: number;
}

export interface RemoteMethod {
  name: string;
  handler: (params: Record<string, Object>) => Promise<Object>;
  description?: string;
}

export interface CrossDeviceCallConfig {
  defaultTimeout: number;
  maxRetryCount: number;
  enableCallLog: boolean;
}

const DEFAULT_CONFIG: CrossDeviceCallConfig = {
  defaultTimeout: 10000,
  maxRetryCount: 3,
  enableCallLog: true
};

export interface PendingCallInfo {
  request: CrossDeviceCallRequest;
  resolve: (response: CrossDeviceCallResponse) => void;
  reject: (error: Error) => void;
  timer: number;
}

export class CrossDeviceCallManager {
  private static instance: CrossDeviceCallManager | null = null;
  private context: common.UIAbilityContext | null = null;
  private config: CrossDeviceCallConfig = DEFAULT_CONFIG;
  private deviceManager: distributedDeviceManager.DeviceManager | null = null;
  private collaborationManager: CollaborationStateManager = CollaborationStateManager.getInstance();
  private callDataObject: distributedDataObject.DataObject | null = null;
  private registeredMethods: Map<string, RemoteMethod> = new Map();
  private pendingCalls: Map<string, PendingCallInfo> = new Map();
  private onRemoteCallCallback: ((request: CrossDeviceCallRequest) => void) | null = null;

  private constructor() {}

  static getInstance(): CrossDeviceCallManager {
    if (!CrossDeviceCallManager.instance) {
      CrossDeviceCallManager.instance = new CrossDeviceCallManager();
    }
    return CrossDeviceCallManager.instance;
  }

  init(context: common.UIAbilityContext): void {
    this.context = context;
    try {
      const deviceManager = distributedDeviceManager.createDeviceManager('newapplication');
      this.deviceManager = deviceManager;
      
      this.initCallDataObject();
      this.registerBuiltInMethods();
      
      hilog.info(DOMAIN, TAG, 'CrossDeviceCallManager initialized');
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to initialize: ${JSON.stringify(error)}`);
    }
  }

  private async initCallDataObject(): Promise<void> {
    if (!this.context) {
      return;
    }

    try {
      const sessionId = 'cross_device_call_' + Date.now();
      interface CallInitialData {
        sessionId: string;
        requests: string;
        responses: string;
        timestamp: number;
      }
      const initialData: CallInitialData = {
        sessionId: sessionId,
        requests: JSON.stringify([]),
        responses: JSON.stringify([]),
        timestamp: Date.now()
      };
      
      this.callDataObject = distributedDataObject.create(this.context, initialData);
      
      this.callDataObject.on('change', (sessionId: string, fields: Array<string>) => {
        this.handleDataChange(fields);
      });
      
      hilog.info(DOMAIN, TAG, 'Call data object initialized');
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to init call data object: ${JSON.stringify(error)}`);
    }
  }

  private registerBuiltInMethods(): void {
    this.registerMethod({
      name: 'ping',
      handler: async (params: Record<string, Object>): Promise<Object> => {
        interface PingResult {
          pong: boolean;
          timestamp: number;
        }
        const result: PingResult = { pong: true, timestamp: Date.now() };
        return result;
      },
      description: 'Ping method for connectivity test'
    });

    this.registerMethod({
      name: 'getDeviceInfo',
      handler: async (params: Record<string, Object>): Promise<Object> => {
        const localDeviceId = this.deviceManager?.getLocalDeviceId() || '';
        interface DeviceInfoResult {
          deviceId: string;
          deviceName: string;
          deviceType: string;
        }
        const result: DeviceInfoResult = {
          deviceId: localDeviceId,
          deviceName: 'Local Device',
          deviceType: 'phone'
        };
        return result;
      },
      description: 'Get device information'
    });

    this.registerMethod({
      name: 'executeCommand',
      handler: async (params: Record<string, Object>): Promise<Object> => {
        const command = params['command'] as string;
        hilog.info(DOMAIN, TAG, `Executing command: ${command}`);
        interface CommandResult {
          executed: boolean;
          command: string;
        }
        const result: CommandResult = { executed: true, command: command };
        return result;
      },
      description: 'Execute a command on remote device'
    });

    hilog.info(DOMAIN, TAG, 'Built-in methods registered');
  }

  registerMethod(method: RemoteMethod): void {
    this.registeredMethods.set(method.name, method);
    hilog.info(DOMAIN, TAG, `Method registered: ${method.name}`);
  }

  unregisterMethod(methodName: string): void {
    this.registeredMethods.delete(methodName);
    hilog.info(DOMAIN, TAG, `Method unregistered: ${methodName}`);
  }

  async callRemoteMethod(
    targetDeviceId: string,
    methodName: string,
    params: Record<string, Object> = {},
    timeout: number = this.config.defaultTimeout
  ): Promise<CrossDeviceCallResponse> {
    const callId = `call_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const localDeviceId = this.deviceManager?.getLocalDeviceId() || '';
    
    const request: CrossDeviceCallRequest = {
      callId: callId,
      methodName: methodName,
      params: params,
      targetDeviceId: targetDeviceId,
      sourceDeviceId: localDeviceId,
      timestamp: Date.now(),
      timeout: timeout
    };
    
    if (this.config.enableCallLog) {
      hilog.info(DOMAIN, TAG, `Calling remote method: ${methodName} on ${targetDeviceId}`);
    }
    
    return new Promise((resolve, reject) => {
      const timer = setInterval(() => {
        this.handleCallTimeout(callId);
      }, timeout);
      
      this.pendingCalls.set(callId, {
        request: request,
        resolve: resolve,
        reject: reject,
        timer: timer
      });
      
      this.sendCallRequest(request);
    });
  }

  private sendCallRequest(request: CrossDeviceCallRequest): void {
    if (!this.callDataObject) {
      this.handleCallError(request.callId, 'Call data object not initialized');
      return;
    }

    try {
      const requests: CrossDeviceCallRequest[] = JSON.parse(this.callDataObject['requests'] as string || '[]') as CrossDeviceCallRequest[];
      requests.push(request);
      this.callDataObject['requests'] = JSON.stringify(requests);
      this.callDataObject['timestamp'] = Date.now();
      
      hilog.info(DOMAIN, TAG, `Call request sent: ${request.callId}`);
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to send call request: ${JSON.stringify(error)}`);
      this.handleCallError(request.callId, `Failed to send request: ${error}`);
    }
  }

  private handleDataChange(fields: Array<string>): void {
    if (!this.callDataObject) {
      return;
    }

    if (fields.includes('requests')) {
      this.handleIncomingRequests();
    }
    
    if (fields.includes('responses')) {
      this.handleIncomingResponses();
    }
  }

  private handleIncomingRequests(): void {
    if (!this.callDataObject || !this.deviceManager) {
      return;
    }

    try {
      const requests: CrossDeviceCallRequest[] = JSON.parse(this.callDataObject['requests'] as string || '[]') as CrossDeviceCallRequest[];
      const localDeviceId = this.deviceManager.getLocalDeviceId();
      
      for (let i = 0; i < requests.length; i++) {
        const request = requests[i];
        if (request.targetDeviceId === localDeviceId) {
          this.processIncomingRequest(request);
        }
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to handle incoming requests: ${JSON.stringify(error)}`);
    }
  }

  private async processIncomingRequest(request: CrossDeviceCallRequest): Promise<void> {
    if (this.config.enableCallLog) {
      hilog.info(DOMAIN, TAG, `Processing incoming request: ${request.methodName}`);
    }
    
    if (this.onRemoteCallCallback) {
      this.onRemoteCallCallback(request);
    }
    
    const method = this.registeredMethods.get(request.methodName);
    
    const response: CrossDeviceCallResponse = {
      callId: request.callId,
      success: false,
      timestamp: Date.now()
    };
    
    if (!method) {
      response.error = `Method not found: ${request.methodName}`;
      this.sendCallResponse(response);
      return;
    }
    
    try {
      const result = await method.handler(request.params);
      response.success = true;
      response.result = result;
    } catch (error) {
      response.error = `Method execution failed: ${error}`;
    }
    
    this.sendCallResponse(response);
  }

  private sendCallResponse(response: CrossDeviceCallResponse): void {
    if (!this.callDataObject) {
      return;
    }

    try {
      const responses: CrossDeviceCallResponse[] = JSON.parse(this.callDataObject['responses'] as string || '[]') as CrossDeviceCallResponse[];
      responses.push(response);
      this.callDataObject['responses'] = JSON.stringify(responses);
      this.callDataObject['timestamp'] = Date.now();
      
      hilog.info(DOMAIN, TAG, `Call response sent: ${response.callId}`);
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to send call response: ${JSON.stringify(error)}`);
    }
  }

  private handleIncomingResponses(): void {
    if (!this.callDataObject) {
      return;
    }

    try {
      const responses: CrossDeviceCallResponse[] = JSON.parse(this.callDataObject['responses'] as string || '[]') as CrossDeviceCallResponse[];
      
      for (let i = 0; i < responses.length; i++) {
        const response = responses[i];
        const pending = this.pendingCalls.get(response.callId);
        if (pending) {
          clearInterval(pending.timer);
          this.pendingCalls.delete(response.callId);
          pending.resolve(response);
          
          if (this.config.enableCallLog) {
            hilog.info(DOMAIN, TAG, `Call completed: ${response.callId}, success: ${response.success}`);
          }
        }
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to handle incoming responses: ${JSON.stringify(error)}`);
    }
  }

  private handleCallTimeout(callId: string): void {
    const pending = this.pendingCalls.get(callId);
    if (!pending) {
      return;
    }

    clearInterval(pending.timer);
    this.pendingCalls.delete(callId);
    
    const response: CrossDeviceCallResponse = {
      callId: callId,
      success: false,
      error: 'Call timeout',
      timestamp: Date.now()
    };
    
    pending.resolve(response);
    hilog.error(DOMAIN, TAG, `Call timeout: ${callId}`);
  }

  private handleCallError(callId: string, error: string): void {
    const pending = this.pendingCalls.get(callId);
    if (!pending) {
      return;
    }

    clearInterval(pending.timer);
    this.pendingCalls.delete(callId);
    pending.reject(new Error(error));
    hilog.error(DOMAIN, TAG, `Call error: ${callId} - ${error}`);
  }

  async callMaster(methodName: string, params: Record<string, Object> = {}): Promise<CrossDeviceCallResponse> {
    const masterDeviceId = this.collaborationManager.getMasterDeviceId();
    if (!masterDeviceId) {
      return {
        callId: '',
        success: false,
        error: 'No master device found',
        timestamp: Date.now()
      };
    }
    
    return this.callRemoteMethod(masterDeviceId, methodName, params);
  }

  async broadcastToSlaves(methodName: string, params: Record<string, Object> = {}): Promise<CrossDeviceCallResponse[]> {
    const slaveDevices = this.collaborationManager.getSlaveDevices();
    
    const promises = slaveDevices.map(deviceId => 
      this.callRemoteMethod(deviceId, methodName, params)
    );
    
    return Promise.all(promises);
  }

  async callAllDevices(methodName: string, params: Record<string, Object> = {}): Promise<CrossDeviceCallResponse[]> {
    const allDevices = this.collaborationManager.getAllDevices();
    
    const promises = allDevices
      .filter(d => d.isOnline)
      .map(d => this.callRemoteMethod(d.deviceId, methodName, params));
    
    return Promise.all(promises);
  }

  getRegisteredMethods(): string[] {
    return Array.from(this.registeredMethods.keys());
  }

  setOnRemoteCallCallback(callback: (request: CrossDeviceCallRequest) => void): void {
    this.onRemoteCallCallback = callback;
  }

  setConfig(config: Partial<CrossDeviceCallConfig>): void {
    if (config.defaultTimeout !== undefined) {
      this.config.defaultTimeout = config.defaultTimeout;
    }
    if (config.maxRetryCount !== undefined) {
      this.config.maxRetryCount = config.maxRetryCount;
    }
    if (config.enableCallLog !== undefined) {
      this.config.enableCallLog = config.enableCallLog;
    }
    hilog.info(DOMAIN, TAG, `Config updated: ${JSON.stringify(this.config)}`);
  }

  destroy(): void {
    this.pendingCalls.forEach((pending) => {
      clearInterval(pending.timer);
      pending.reject(new Error('Manager destroyed'));
    });
    this.pendingCalls.clear();
    
    if (this.callDataObject) {
      try {
        this.callDataObject.off('change');
        this.callDataObject = null;
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Failed to destroy call data object: ${JSON.stringify(error)}`);
      }
    }
    
    this.registeredMethods.clear();
    this.onRemoteCallCallback = null;
    
    CrossDeviceCallManager.instance = null;
    hilog.info(DOMAIN, TAG, 'CrossDeviceCallManager destroyed');
  }
}