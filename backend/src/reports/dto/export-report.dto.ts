import { IsEnum, IsOptional } from 'class-validator';
import { GenerateReportDto, ReportType } from './generate-report.dto';

export enum ExportFormat {
  EXCEL = 'EXCEL',
  PDF = 'PDF',
}

export class ExportReportDto extends GenerateReportDto {
  @IsEnum(ExportFormat)
  format: ExportFormat;
}
