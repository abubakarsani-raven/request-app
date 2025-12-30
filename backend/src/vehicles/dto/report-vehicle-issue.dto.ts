import { IsString, IsNotEmpty } from 'class-validator';

export class ReportVehicleIssueDto {
  @IsString()
  @IsNotEmpty()
  type: string;

  @IsString()
  @IsNotEmpty()
  description: string;
}







