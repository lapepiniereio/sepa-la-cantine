export interface IElectronAPI {
  processFiles: (paths: string[]) => Promise<'ok'>
}

declare global {
  interface Window {
    api: IElectronAPI
  }
}
