import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import { distributedDataObject } from '@kit.ArkData';
import { CollaborationStateManager, CollaborationMode } from './CollaborationStateManager';

const TAG = 'DistributedUIManager';
const DOMAIN = 0x0000;

export interface UIComponentState {
  componentId: string;
  componentName: string;
  properties: Record<string, Object>;
  visibility: boolean;
  deviceId: string;
  updateTime: number;
}

export interface DistributedUIConfig {
  enableMirrorMode: boolean;
  enableExtensionMode: boolean;
  syncPropertyChanges: boolean;
  syncVisibilityChanges: boolean;
  debounceInterval: number;
}

const DEFAULT_CONFIG: DistributedUIConfig = {
  enableMirrorMode: true,
  enableExtensionMode: true,
  syncPropertyChanges: true,
  syncVisibilityChanges: true,
  debounceInterval: 100
};

export class DistributedUIManager {
  private static instance: DistributedUIManager | null = null;
  private context: common.UIAbilityContext | null = null;
  private config: DistributedUIConfig = DEFAULT_CONFIG;
  private collaborationManager: CollaborationStateManager = CollaborationStateManager.getInstance();
  private uiStateDataObject: distributedDataObject.DataObject | null = null;
  private componentStates: Map<string, UIComponentState> = new Map();
  private propertyUpdateTimers: Map<string, number> = new Map();
  private onComponentStateChangeCallback: ((componentId: string, state: UIComponentState) => void) | null = null;
  private onMirrorUICallback: ((componentStates: Map<string, UIComponentState>) => void) | null = null;

  private constructor() {}

  static getInstance(): DistributedUIManager {
    if (!DistributedUIManager.instance) {
      DistributedUIManager.instance = new DistributedUIManager();
    }
    return DistributedUIManager.instance;
  }

  init(context: common.UIAbilityContext): void {
    this.context = context;
    hilog.info(DOMAIN, TAG, 'DistributedUIManager initialized');
    
    this.collaborationManager.setOnStateChangeCallback((state) => {
      if (state.isActive && state.mode === CollaborationMode.MIRROR) {
        this.enableMirrorMode();
      }
    });
  }

  setConfig(config: Partial<DistributedUIConfig>): void {
    if (config.enableMirrorMode !== undefined) {
      this.config.enableMirrorMode = config.enableMirrorMode;
    }
    if (config.enableExtensionMode !== undefined) {
      this.config.enableExtensionMode = config.enableExtensionMode;
    }
    if (config.syncPropertyChanges !== undefined) {
      this.config.syncPropertyChanges = config.syncPropertyChanges;
    }
    if (config.syncVisibilityChanges !== undefined) {
      this.config.syncVisibilityChanges = config.syncVisibilityChanges;
    }
    if (config.debounceInterval !== undefined) {
      this.config.debounceInterval = config.debounceInterval;
    }
    hilog.info(DOMAIN, TAG, `Config updated: ${JSON.stringify(this.config)}`);
  }

  private async enableMirrorMode(): Promise<void> {
    if (!this.config.enableMirrorMode) {
      return;
    }

    try {
      const sessionId = 'ui_mirror_' + Date.now();
      interface UIInitialData {
        sessionId: string;
        components: string;
        timestamp: number;
      }
      const initialData: UIInitialData = {
        sessionId: sessionId,
        components: JSON.stringify({}),
        timestamp: Date.now()
      };
      
      this.uiStateDataObject = distributedDataObject.create(this.context!, initialData);
      
      this.uiStateDataObject.on('change', (sessionId: string, fields: Array<string>) => {
        hilog.info(DOMAIN, TAG, `UI state changed: ${fields.join(',')}`);
        this.handleUIStateChange(fields);
      });
      
      hilog.info(DOMAIN, TAG, 'Mirror mode enabled');
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to enable mirror mode: ${JSON.stringify(error)}`);
    }
  }

  private disableMirrorMode(): void {
    if (this.uiStateDataObject) {
      try {
        this.uiStateDataObject.off('change');
        this.uiStateDataObject = null;
        hilog.info(DOMAIN, TAG, 'Mirror mode disabled');
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Failed to disable mirror mode: ${JSON.stringify(error)}`);
      }
    }
  }

  registerComponent(componentId: string, componentName: string, initialProperties: Record<string, Object> = {}): void {
    const state: UIComponentState = {
      componentId: componentId,
      componentName: componentName,
      properties: initialProperties,
      visibility: true,
      deviceId: this.getLocalDeviceId(),
      updateTime: Date.now()
    };
    
    this.componentStates.set(componentId, state);
    hilog.info(DOMAIN, TAG, `Component registered: ${componentId} (${componentName})`);
    
    this.syncComponentState(componentId);
  }

  unregisterComponent(componentId: string): void {
    this.componentStates.delete(componentId);
    
    const timer = this.propertyUpdateTimers.get(componentId);
    if (timer !== undefined) {
      clearInterval(timer);
      this.propertyUpdateTimers.delete(componentId);
    }
    
    hilog.info(DOMAIN, TAG, `Component unregistered: ${componentId}`);
    
    this.syncAllComponentStates();
  }

  updateComponentProperty(componentId: string, propertyName: string, value: Object): void {
    const state = this.componentStates.get(componentId);
    if (!state) {
      hilog.error(DOMAIN, TAG, `Component not found: ${componentId}`);
      return;
    }

    state.properties[propertyName] = value;
    state.updateTime = Date.now();
    
    if (this.config.syncPropertyChanges) {
      this.debouncedSync(componentId);
    }
    
    hilog.info(DOMAIN, TAG, `Component property updated: ${componentId}.${propertyName}`);
  }

  updateComponentProperties(componentId: string, properties: Record<string, Object>): void {
    const state = this.componentStates.get(componentId);
    if (!state) {
      hilog.error(DOMAIN, TAG, `Component not found: ${componentId}`);
      return;
    }

    const keys = Object.keys(properties);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      state.properties[key] = properties[key];
    }
    state.updateTime = Date.now();
    
    if (this.config.syncPropertyChanges) {
      this.debouncedSync(componentId);
    }
    
    hilog.info(DOMAIN, TAG, `Component properties updated: ${componentId}`);
  }

  setComponentVisibility(componentId: string, visibility: boolean): void {
    const state = this.componentStates.get(componentId);
    if (!state) {
      hilog.error(DOMAIN, TAG, `Component not found: ${componentId}`);
      return;
    }

    state.visibility = visibility;
    state.updateTime = Date.now();
    
    if (this.config.syncVisibilityChanges) {
      this.syncComponentState(componentId);
    }
    
    hilog.info(DOMAIN, TAG, `Component visibility changed: ${componentId} -> ${visibility}`);
  }

  private debouncedSync(componentId: string): void {
    let timer = this.propertyUpdateTimers.get(componentId);
    if (timer !== undefined) {
      clearInterval(timer);
    }
    
    timer = setInterval(() => {
      this.syncComponentState(componentId);
      const t = this.propertyUpdateTimers.get(componentId);
      if (t !== undefined) {
        clearInterval(t);
        this.propertyUpdateTimers.delete(componentId);
      }
    }, this.config.debounceInterval);
    
    this.propertyUpdateTimers.set(componentId, timer);
  }

  private syncComponentState(componentId: string): void {
    if (!this.uiStateDataObject) {
      return;
    }

    const state = this.componentStates.get(componentId);
    if (!state) {
      return;
    }

    try {
      const componentsData: Record<string, UIComponentState> = JSON.parse(this.uiStateDataObject['components'] as string || '{}') as Record<string, UIComponentState>;
      componentsData[componentId] = state;
      this.uiStateDataObject['components'] = JSON.stringify(componentsData);
      this.uiStateDataObject['timestamp'] = Date.now();
      
      hilog.info(DOMAIN, TAG, `Component state synced: ${componentId}`);
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to sync component state: ${JSON.stringify(error)}`);
    }
  }

  private syncAllComponentStates(): void {
    if (!this.uiStateDataObject) {
      return;
    }

    try {
      const componentsData: Record<string, UIComponentState> = {};
      this.componentStates.forEach((state, componentId) => {
        componentsData[componentId] = state;
      });
      
      this.uiStateDataObject['components'] = JSON.stringify(componentsData);
      this.uiStateDataObject['timestamp'] = Date.now();
      
      hilog.info(DOMAIN, TAG, 'All component states synced');
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to sync all states: ${JSON.stringify(error)}`);
    }
  }

  private handleUIStateChange(fields: Array<string>): void {
    if (!this.uiStateDataObject || !fields.includes('components')) {
      return;
    }

    try {
      const componentsData: Record<string, UIComponentState> = JSON.parse(this.uiStateDataObject['components'] as string || '{}') as Record<string, UIComponentState>;
      
      const componentIds = Object.keys(componentsData);
      for (let i = 0; i < componentIds.length; i++) {
        const componentId = componentIds[i];
        const remoteState = componentsData[componentId] as UIComponentState;
        const localState = this.componentStates.get(componentId);
        
        if (!localState || remoteState.updateTime > localState.updateTime) {
          this.componentStates.set(componentId, remoteState);
          
          if (this.onComponentStateChangeCallback) {
            this.onComponentStateChangeCallback(componentId, remoteState);
          }
        }
      }
      
      if (this.onMirrorUICallback) {
        this.onMirrorUICallback(new Map(this.componentStates));
      }
      
      hilog.info(DOMAIN, TAG, 'UI state synchronized from remote');
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to handle UI state change: ${JSON.stringify(error)}`);
    }
  }

  getComponentState(componentId: string): UIComponentState | null {
    return this.componentStates.get(componentId) || null;
  }

  getAllComponentStates(): Map<string, UIComponentState> {
    return new Map(this.componentStates);
  }

  private getLocalDeviceId(): string {
    return this.collaborationManager.getMasterDeviceId();
  }

  setOnComponentStateChangeCallback(callback: (componentId: string, state: UIComponentState) => void): void {
    this.onComponentStateChangeCallback = callback;
  }

  setOnMirrorUICallback(callback: (componentStates: Map<string, UIComponentState>) => void): void {
    this.onMirrorUICallback = callback;
  }

  enableDistributedUI(): void {
    const state = this.collaborationManager.getCollaborationState();
    if (state && state.mode === CollaborationMode.MIRROR) {
      this.enableMirrorMode();
    }
    hilog.info(DOMAIN, TAG, 'Distributed UI enabled');
  }

  disableDistributedUI(): void {
    this.disableMirrorMode();
    hilog.info(DOMAIN, TAG, 'Distributed UI disabled');
  }

  destroy(): void {
    this.disableMirrorMode();
    
    this.propertyUpdateTimers.forEach((timer) => {
      clearInterval(timer);
    });
    this.propertyUpdateTimers.clear();
    
    this.componentStates.clear();
    this.onComponentStateChangeCallback = null;
    this.onMirrorUICallback = null;
    
    DistributedUIManager.instance = null;
    hilog.info(DOMAIN, TAG, 'DistributedUIManager destroyed');
  }
}