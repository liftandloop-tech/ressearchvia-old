export interface ReportStorageProvider {
    upload(fileName: string, content: Buffer, mimeType: string): Promise<string>;
}
export declare const REPORT_STORAGE_PROVIDER = "ReportStorageProvider";
export declare class LocalStorageProvider implements ReportStorageProvider {
    private readonly uploadDir;
    upload(fileName: string, content: Buffer, mimeType: string): Promise<string>;
}
