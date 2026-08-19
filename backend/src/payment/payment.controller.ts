import {
  Controller,
  Post,
  Get,
  Body,
  Headers,
  UseGuards,
  Req,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiBody } from '@nestjs/swagger';
import { PaymentService } from './payment.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { PaymentMethodType } from './entities/payment-transaction.entity';

@ApiTags('Payment')
@Controller('payment')
export class PaymentController {
  constructor(private readonly paymentService: PaymentService) {}

  @Post('create-order')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create gateway order for single-checkout cart' })
  async createGatewayOrder(
    @Body()
    body: {
      amount: number;
      currency?: string;
      receipt?: string;
      parentOrderId?: string;
      paymentMethod?: PaymentMethodType;
    },
    @Req() req: any,
  ) {
    return this.paymentService.createGatewayOrder({
      ...body,
      retailerId: req.user?.id,
    });
  }

  @Post('verify')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Cryptographically verify payment signature & capture' })
  async verifyPayment(
    @Body()
    body: {
      providerOrderId: string;
      providerPaymentId: string;
      signature?: string;
      parentOrderId?: string;
      paymentMethod?: string;
    },
  ) {
    return this.paymentService.verifyPayment(body);
  }

  @Post('webhook')
  @ApiOperation({ summary: 'Payment Gateway Webhook (Razorpay / Route)' })
  async handleWebhook(
    @Body() payload: any,
    @Headers('x-razorpay-signature') signature?: string,
  ) {
    return this.paymentService.handleWebhook(payload, signature);
  }

  @Post('refund')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.WHOLESALER)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Process full or partial order refund' })
  async processRefund(
    @Body()
    body: {
      parentOrderId: string;
      sellerOrderId?: string;
      wholesalerId: string;
      amount: number;
      reason?: string;
    },
  ) {
    return this.paymentService.processRefund(body);
  }

  @Get('admin/metrics')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Admin: Get payment and collection metrics' })
  async getPaymentMetrics() {
    return this.paymentService.getPaymentMetrics();
  }

  // ─── Legacy compatibility endpoints ───────────────────────────────────────
  @Post('create-intent')
  @ApiOperation({ summary: 'Legacy create intent stub (backward compatible)' })
  async createPaymentIntent(@Body('amount') amountInPaise: number) {
    const amountInRupees = amountInPaise ? amountInPaise / 100 : 100;
    const res = await this.paymentService.createGatewayOrder({
      amount: amountInRupees,
    });
    return {
      id: res.id,
      amount: amountInPaise,
      currency: res.currency,
      status: 'requires_payment_method',
      clientSecret: `${res.id}_secret`,
    };
  }

  @Post('confirm')
  @ApiOperation({ summary: 'Legacy confirm stub (backward compatible)' })
  async confirmPayment(@Body('paymentIntentId') paymentIntentId: string) {
    return { success: true, status: 'succeeded', paymentIntentId };
  }
}
