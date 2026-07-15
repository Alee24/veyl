import { IsString, IsNotEmpty, MinLength, MaxLength } from 'class-validator';

export class RecoverDto {
  @IsString()
  @IsNotEmpty()
  @MinLength(3)
  @MaxLength(30)
  username: string;

  @IsString()
  @IsNotEmpty()
  recoveryKey: string;

  @IsString()
  @IsNotEmpty()
  @MinLength(8)
  @MaxLength(100)
  newPassword: string;
}
