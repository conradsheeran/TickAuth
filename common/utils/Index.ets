/*
 * Copyright (c) 2024 Yang He
 *
 * TickAuth is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */

export { bufferToString } from './src/main/ets/pages/BufferUtil'

export { JumpToApp } from './src/main/ets/pages/JumpToApp'

export { Base32 } from './src/main/ets/pages/Base32'

export {
  ProcessSecret,
  SecretParamsToUint8Array,
  Uint8ArrayToSecretParams,
  ISecretParams } from './src/main/ets/pages/ProcessSecret'

export { WriteToJson, ISecretItem } from './src/main/ets/pages/WriteToJSON'

export { Logger } from './src/main/ets/pages/Logger'

export { Preference } from './src/main/ets/pages/Preference'

export { CatchSecretByScan } from './src/main/ets/pages/CatchSecretByScan'