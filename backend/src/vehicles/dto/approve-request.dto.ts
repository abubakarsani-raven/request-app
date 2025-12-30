import { IsString, IsOptional, IsBoolean } from 'class-validator';

export class ApproveRequestDto {
  @IsString()
  @IsOptional()
  comment?: string;

  @IsBoolean()
  @IsOptional()
  isAdminApproval?: boolean; // Flag to indicate admin override approval
}

