/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */

import { hilog } from '@kit.PerformanceAnalysisKit';

export class AuthManagement {
  public static async auth(): Promise<string> {
    hilog.info(0x0000, 'testTag', 'Local storage mode - no authorization needed');
    return '当前使用本地存储模式\n无需华为账号授权\n可直接使用所有功能';
  }
}
