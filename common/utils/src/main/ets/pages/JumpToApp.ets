import { Want, common } from '@kit.AbilityKit';

export function JumpToApp(context: common.UIAbilityContext, bundleName: string, abilityName: string, uri?: string): void {
  let want: Want = {
    bundleName: bundleName,
    abilityName: abilityName,
    uri: uri
  };
  context.startAbility(want);
}