import { IsString, IsNotEmpty, MinLength, MaxLength } from 'class-validator';

export class FirebaseRegisterDto {
  @IsString()
  @IsNotEmpty()
  firebaseToken: string;

  @IsString()
  @IsNotEmpty()
  @MinLength(3)
  @MaxLength(30)
  username: string;

  @IsString()
  @IsNotEmpty()
  @MinLength(1)
  @MaxLength(50)
  displayName: string;
}
