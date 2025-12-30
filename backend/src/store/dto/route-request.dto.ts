import { IsBoolean, IsNotEmpty } from 'class-validator';

export class RouteRequestDto {
  @IsBoolean()
  @IsNotEmpty()
  directToSO: boolean; // true = DGS → SO, false = DGS → DDGS → ADGS → SO
}

