import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { CheckInManager } from '../common/bean/CheckInManager';
import { ExerciseSequenceManagement } from '../common/bean/ExerciseSequenceManagement';
import { ContinuationManager } from '../common/bean/ContinuationManager';
import { AutoContinuationManager } from '../common/bean/AutoContinuationManager';
import { CollaborationStateManager, CollaborationMode } from '../common/bean/CollaborationStateManager';
import { DistributedUIManager } from '../common/bean/DistributedUIManager';
import { CrossDeviceCallManager } from '../common/bean/CrossDeviceCallManager';

const TAG = 'EntryAbility';
const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  private continuationManager: ContinuationManager = ContinuationManager.getInstance();
  private autoContinuationManager: AutoContinuationManager = AutoContinuationManager.getInstance();
  private collaborationStateManager: CollaborationStateManager = CollaborationStateManager.getInstance();
  private distributedUIManager: DistributedUIManager = DistributedUIManager.getInstance();
  private crossDeviceCallManager: CrossDeviceCallManager = CrossDeviceCallManager.getInstance();

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    CheckInManager.init(this.context);
    ExerciseSequenceManagement.init(this.context);
    this.continuationManager.init(this.context);
    this.autoContinuationManager.init(this.context);
    this.collaborationStateManager.init(this.context);
    this.distributedUIManager.init(this.context);
    this.crossDeviceCallManager.init(this.context);
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onCreate');

    if (launchParam.launchReason === AbilityConstant.LaunchReason.CONTINUATION) {
      hilog.info(DOMAIN, TAG, 'Ability launched by continuation');
      const restoreData = want.parameters?.['ohos.extra.param.key.continueData'];
      if (restoreData) {
        hilog.info(DOMAIN, TAG, `Restore data received: ${JSON.stringify(restoreData)}`);
      }
    }
    
    this.setupCollaborationCallbacks();
  }

  private setupCollaborationCallbacks(): void {
    this.collaborationStateManager.setOnRoleChangeCallback((role) => {
      hilog.info(DOMAIN, TAG, `Device role changed to: ${role}`);
    });
    
    this.collaborationStateManager.setOnDeviceJoinCallback((device) => {
      hilog.info(DOMAIN, TAG, `Device joined: ${device.deviceName}`);
    });
    
    this.collaborationStateManager.setOnDeviceLeaveCallback((deviceId) => {
      hilog.info(DOMAIN, TAG, `Device left: ${deviceId}`);
    });
    
    this.crossDeviceCallManager.setOnRemoteCallCallback((request) => {
      hilog.info(DOMAIN, TAG, `Remote call received: ${request.methodName}`);
    });
  }

  onDestroy(): void {
    this.crossDeviceCallManager.destroy();
    this.distributedUIManager.destroy();
    this.collaborationStateManager.destroy();
    this.autoContinuationManager.destroy();
    this.continuationManager.destroy();
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/MainIndex', (err, data) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(DOMAIN, TAG, 'Succeeded in loading the content. Data: %{public}s', JSON.stringify(data) ?? '');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onForeground');
    this.autoContinuationManager.notifyScreenStateChange(true);
  }

  onBackground(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onBackground');
    this.autoContinuationManager.notifyScreenStateChange(false);
  }

  onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
    hilog.info(DOMAIN, TAG, 'onContinue called');
    
    const collaborationState = this.collaborationStateManager.getCollaborationState();
    
    const continueData: Record<string, Object> = {
      'timestamp': Date.now(),
      'source': 'continuation',
      'collaborationSessionId': collaborationState?.sessionId || '',
      'deviceRole': this.collaborationStateManager.getLocalDeviceRole(),
      'collaborationMode': collaborationState?.mode || CollaborationMode.HANDOFF
    };
    
    wantParam['ohos.extra.param.key.continueData'] = continueData;
    
    hilog.info(DOMAIN, TAG, `Continue data prepared: ${JSON.stringify(continueData)}`);
    return AbilityConstant.OnContinueResult.AGREE;
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, 'onNewWant called');
    
    if (launchParam.launchReason === AbilityConstant.LaunchReason.CONTINUATION) {
      hilog.info(DOMAIN, TAG, 'Ability continued from another device');
      const restoreData = want.parameters?.['ohos.extra.param.key.continueData'];
      if (restoreData) {
        hilog.info(DOMAIN, TAG, `Restore data: ${JSON.stringify(restoreData)}`);
      }
    }
  }
}
