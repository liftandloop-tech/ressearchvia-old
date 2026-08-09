import { Injectable } from '@nestjs/common';
import * as fs from 'fs/promises';
import * as path from 'path';

export interface ReportStorageProvider {
  upload(fileName: string, content: Buffer, mimeType: string): Promise<string>;
}

export const REPORT_STORAGE_PROVIDER = 'ReportStorageProvider';

@Injectable()
export class LocalStorageProvider implements ReportStorageProvider {
  private readonly uploadDir = path.join(process.cwd(), 'uploads', 'reports');

  async upload(fileName: string, content: Buffer, mimeType: string): Promise<string> {
    try {
      await fs.mkdir(this.uploadDir, { recursive: true });
      const filePath = path.join(this.uploadDir, fileName);
      await fs.writeFile(filePath, content);
      // Return local file path or relative URL
      return `/uploads/reports/${fileName}`;
    } catch (error) {
      throw new Error(`Failed to upload file to local storage: ${error.message}`);
    }
  }
}
