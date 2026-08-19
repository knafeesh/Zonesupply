import { Body, Controller, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { AuthService } from './auth.service';
import { CreateUserDto } from '../users/dto/create-user.dto';
import { LoginDto } from './dto/login.dto';
import { GoogleAuthDto } from './dto/google-auth.dto';
import { SendOtpDto, VerifyOtpDto } from './dto/otp.dto';
import { MembershipLoginDto } from './dto/membership-login.dto';

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  // ── Email / Password ──────────────────────────────────────────────────────
  @Post('register')
  @ApiOperation({ summary: 'Register a new user with email & password' })
  async register(@Body() dto: CreateUserDto) {
    return this.authService.register(dto);
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Login with email & password' })
  async login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  // ── Google OAuth ──────────────────────────────────────────────────────────
  @Post('google')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Login / register with Google ID token' })
  @ApiResponse({ status: 200, description: 'Returns JWT + user on success' })
  async loginWithGoogle(@Body() dto: GoogleAuthDto) {
    return this.authService.loginWithGoogle(dto);
  }

  // ── Phone OTP ─────────────────────────────────────────────────────────────
  @Post('otp/send')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Send OTP to phone number (stub: logs to console)' })
  async sendOtp(@Body() dto: SendOtpDto) {
    return this.authService.sendOtp(dto);
  }

  @Post('otp/verify')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Verify OTP and get JWT token' })
  async verifyOtp(@Body() dto: VerifyOtpDto) {
    return this.authService.verifyOtp(dto);
  }

  // ── Membership Direct Login ───────────────────────────────────────────────
  @Post('membership-login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Authenticate approved retailer member and issue JWT' })
  async membershipLogin(@Body() dto: MembershipLoginDto) {
    return this.authService.loginWithMembership(dto);
  }
}
