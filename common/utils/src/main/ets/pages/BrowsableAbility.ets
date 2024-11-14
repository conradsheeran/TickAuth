import { common, Want } from '@kit.AbilityKit';

export function Jump2Browser(context: common.UIAbilityContext, uriContent: string): void {
  let want: Want = {
    action: 'ohos.want.action.viewData',
    entities: ['entity.system.browsable'],
    uri: uriContent
  };
  context.startAbility(want)
}