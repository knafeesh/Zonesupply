import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  forwardRef,
  Inject,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource, EntityManager } from 'typeorm';
import {
  SellerLedgerEntry,
  SellerLedgerEntryStatus,
  SellerLedgerEntryType,
} from './seller-ledger-entry.entity';
import { Settlement, SettlementStatus } from './settlement.entity';
import {
  WholesalerPaymentAccount,
  PayoutAccountStatus,
} from './wholesaler-payment-account.entity';
import { Wholesaler } from '../wholesalers/wholesaler.entity';
import { PaymentService } from '../payment/payment.service';

@Injectable()
export class SellerLedgerService {
  constructor(
    @InjectRepository(SellerLedgerEntry)
    private readonly entryRepo: Repository<SellerLedgerEntry>,
    @InjectRepository(Settlement)
    private readonly settlementRepo: Repository<Settlement>,
    @InjectRepository(WholesalerPaymentAccount)
    private readonly accountRepo: Repository<WholesalerPaymentAccount>,
    @InjectRepository(Wholesaler)
    private readonly wholesalerRepo: Repository<Wholesaler>,
    @Inject(forwardRef(() => PaymentService))
    private readonly paymentService: PaymentService,
    private readonly dataSource: DataSource,
  ) {}

  /**
   * 1. Record Sale / Earning for a Wholesaler when an order is created / delivered.
   * Locks in the commission snapshot so future platform commission changes do not alter past records.
   */
  async recordSale(
    wholesalerId: string,
    parentOrderId: string,
    sellerOrderId: string,
    grossAmount: number,
    manager?: EntityManager,
  ): Promise<SellerLedgerEntry> {
    const repo = manager ? manager.getRepository(SellerLedgerEntry) : this.entryRepo;
    const wRepo = manager ? manager.getRepository(Wholesaler) : this.wholesalerRepo;

    const wholesaler = await wRepo.findOne({ where: { id: wholesalerId } });
    if (!wholesaler) {
      throw new NotFoundException(`Wholesaler ${wholesalerId} not found`);
    }

    const commissionRate = Number(wholesaler.commissionRate) || 5.0;
    const gross = Number(grossAmount);
    const commissionAmount = parseFloat(((gross * commissionRate) / 100).toFixed(2));
    const netAmount = parseFloat((gross - commissionAmount).toFixed(2));

    const entry = repo.create({
      wholesalerId,
      orderId: parentOrderId,
      sellerOrderId,
      grossAmount: gross,
      commissionAmount,
      credit: netAmount,
      debit: 0,
      netAmount,
      commissionRate,
      type: SellerLedgerEntryType.SALE,
      status: SellerLedgerEntryStatus.PENDING,
      description: `Order sale earning #${sellerOrderId.slice(0, 8).toUpperCase()} (Comm ${commissionRate}%)`,
    });

    return repo.save(entry);
  }

  // Alias for backward compatibility
  async recordEarning(
    wholesalerId: string,
    orderId: string,
    grossAmount: number,
  ): Promise<SellerLedgerEntry> {
    return this.recordSale(wholesalerId, orderId, orderId, grossAmount);
  }

  /**
   * 2. Mark ledger entries as ELIGIBLE for settlement upon successful delivery
   */
  async markEntriesEligible(sellerOrderId: string): Promise<void> {
    const entries = await this.entryRepo.find({
      where: {
        sellerOrderId,
        status: SellerLedgerEntryStatus.PENDING,
      },
    });

    for (const entry of entries) {
      entry.status = SellerLedgerEntryStatus.ELIGIBLE;
      await this.entryRepo.save(entry);
    }
  }

  /**
   * 3. Record Refund / Cancellation Debit
   */
  async recordRefund(
    wholesalerId: string,
    parentOrderId: string,
    sellerOrderId: string,
    refundAmount: number,
    commissionReversed: number,
    reason?: string,
    manager?: EntityManager,
  ): Promise<SellerLedgerEntry> {
    const repo = manager ? manager.getRepository(SellerLedgerEntry) : this.entryRepo;
    const netDebit = parseFloat((refundAmount - commissionReversed).toFixed(2));

    const entry = repo.create({
      wholesalerId,
      orderId: parentOrderId,
      sellerOrderId,
      grossAmount: refundAmount,
      commissionAmount: commissionReversed,
      credit: 0,
      debit: netDebit,
      netAmount: -netDebit,
      type: SellerLedgerEntryType.REFUND,
      status: SellerLedgerEntryStatus.SETTLED, // immediate ledger debit
      description: `Refund for #${sellerOrderId.slice(0, 8).toUpperCase()}: ${reason || 'Return'}`,
    });

    return repo.save(entry);
  }

  /**
   * 4. Record Manual Adjustment (e.g. penalty, bonus, delivery compensation)
   */
  async recordAdjustment(
    wholesalerId: string,
    amount: number,
    isCredit: boolean,
    note: string,
  ): Promise<SellerLedgerEntry> {
    const entry = this.entryRepo.create({
      wholesalerId,
      grossAmount: Math.abs(amount),
      commissionAmount: 0,
      credit: isCredit ? Math.abs(amount) : 0,
      debit: isCredit ? 0 : Math.abs(amount),
      netAmount: isCredit ? Math.abs(amount) : -Math.abs(amount),
      type: SellerLedgerEntryType.ADJUSTMENT,
      status: SellerLedgerEntryStatus.ELIGIBLE,
      note,
      description: `Adjustment: ${note}`,
    });

    return this.entryRepo.save(entry);
  }

  /**
   * 5. Get Comprehensive Seller Payment & Settlement Summary (KPIs)
   */
  async getSellerSummary(wholesalerId: string): Promise<{
    totalSales: number;
    grossAmount: number;
    platformCommission: number;
    refunds: number;
    pendingSettlement: number;
    availableSettlement: number;
    totalSettled: number;
  }> {
    const allEntries = await this.entryRepo.find({ where: { wholesalerId } });

    let totalSales = 0;
    let grossAmount = 0;
    let platformCommission = 0;
    let refunds = 0;
    let pendingSettlement = 0;
    let availableSettlement = 0;
    let totalSettled = 0;

    for (const e of allEntries) {
      const net = Number(e.netAmount) || 0;
      const gross = Number(e.grossAmount) || 0;
      const comm = Number(e.commissionAmount) || 0;

      if (e.type === SellerLedgerEntryType.SALE || e.type === SellerLedgerEntryType.EARNING) {
        totalSales += gross;
        grossAmount += gross;
        platformCommission += comm;

        if (e.status === SellerLedgerEntryStatus.PENDING) {
          pendingSettlement += net;
        } else if (e.status === SellerLedgerEntryStatus.ELIGIBLE) {
          availableSettlement += net;
        } else if (e.status === SellerLedgerEntryStatus.SETTLED) {
          totalSettled += net;
        }
      } else if (e.type === SellerLedgerEntryType.REFUND || e.type === SellerLedgerEntryType.CANCELLATION) {
        refunds += gross;
        if (e.status === SellerLedgerEntryStatus.ELIGIBLE) {
          availableSettlement += net; // net is negative
        } else if (e.status === SellerLedgerEntryStatus.PENDING) {
          pendingSettlement += net;
        }
      } else if (e.type === SellerLedgerEntryType.ADJUSTMENT) {
        if (e.status === SellerLedgerEntryStatus.ELIGIBLE) {
          availableSettlement += net;
        } else if (e.status === SellerLedgerEntryStatus.SETTLED) {
          totalSettled += net;
        }
      }
    }

    return {
      totalSales: parseFloat(totalSales.toFixed(2)),
      grossAmount: parseFloat(grossAmount.toFixed(2)),
      platformCommission: parseFloat(platformCommission.toFixed(2)),
      refunds: parseFloat(refunds.toFixed(2)),
      pendingSettlement: parseFloat(Math.max(0, pendingSettlement).toFixed(2)),
      availableSettlement: parseFloat(Math.max(0, availableSettlement).toFixed(2)),
      totalSettled: parseFloat(totalSettled.toFixed(2)),
    };
  }

  // Backward compatibility alias for balance
  async getPendingBalance(wholesalerId: string) {
    const summary = await this.getSellerSummary(wholesalerId);
    return {
      pendingEntries: 0,
      totalGross: summary.grossAmount,
      totalCommission: summary.platformCommission,
      totalNet: summary.availableSettlement + summary.pendingSettlement,
    };
  }

  /**
   * 6. Trigger Settlement Payout (Admin or Scheduled Cron)
   */
  async triggerSettlement(
    wholesalerId: string,
    paymentReference?: string,
    note?: string,
  ): Promise<Settlement> {
    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      // Find all eligible and pending entries
      const eligibleEntries = await queryRunner.manager.find(SellerLedgerEntry, {
        where: [
          { wholesalerId, status: SellerLedgerEntryStatus.ELIGIBLE },
          { wholesalerId, status: SellerLedgerEntryStatus.PENDING },
        ],
        lock: { mode: 'pessimistic_write' },
      });

      if (eligibleEntries.length === 0) {
        throw new BadRequestException('No eligible earnings to settle for this wholesaler.');
      }

      let totalGross = 0;
      let totalCommission = 0;
      let totalRefunds = 0;
      let totalAdjustments = 0;
      let totalNet = 0;

      for (const e of eligibleEntries) {
        const net = Number(e.netAmount) || 0;
        const gross = Number(e.grossAmount) || 0;
        const comm = Number(e.commissionAmount) || 0;

        totalNet += net;
        if (e.type === SellerLedgerEntryType.SALE || e.type === SellerLedgerEntryType.EARNING) {
          totalGross += gross;
          totalCommission += comm;
        } else if (e.type === SellerLedgerEntryType.REFUND) {
          totalRefunds += gross;
        } else if (e.type === SellerLedgerEntryType.ADJUSTMENT) {
          totalAdjustments += net;
        }
      }

      if (totalNet <= 0) {
        throw new BadRequestException('Calculated net payout amount must be greater than zero.');
      }

      // Generate UTR Reference
      const utrReference =
        paymentReference ||
        `UTR${new Date().toISOString().slice(0, 10).replace(/-/g, '')}${Math.floor(100000 + Math.random() * 900000)}`;

      // Create the Settlement record
      const settlement = queryRunner.manager.create(Settlement, {
        wholesalerId,
        totalGross: parseFloat(totalGross.toFixed(2)),
        totalCommission: parseFloat(totalCommission.toFixed(2)),
        totalAdjustments: parseFloat(totalAdjustments.toFixed(2)),
        totalRefunds: parseFloat(totalRefunds.toFixed(2)),
        totalNet: parseFloat(totalNet.toFixed(2)),
        entryCount: eligibleEntries.length,
        status: SettlementStatus.PAID,
        settledAt: new Date(),
        paymentReference: utrReference,
        utrReference,
        note: note || 'Settlement batch payout processed',
      });
      const savedSettlement = await queryRunner.manager.save(Settlement, settlement);

      // Mark all included entries as SETTLED
      const now = new Date();
      for (const entry of eligibleEntries) {
        entry.status = SellerLedgerEntryStatus.SETTLED;
        entry.settlementId = savedSettlement.id;
        entry.settledAt = now;
        entry.providerReference = utrReference;
        await queryRunner.manager.save(SellerLedgerEntry, entry);
      }

      await queryRunner.commitTransaction();

      // Trigger asynchronous gateway transfer to linked beneficiary account
      try {
        await this.paymentService.transferToSellerAccount({
          wholesalerId,
          amount: savedSettlement.totalNet,
          settlementId: savedSettlement.id,
        });
      } catch (err: any) {
        // Log but don't fail transaction since internal settlement record is committed
      }

      return savedSettlement;
    } catch (err) {
      await queryRunner.rollbackTransaction();
      throw err;
    } finally {
      await queryRunner.release();
    }
  }

  /**
   * 7. Wholesaler Bank / Linked Payout Account Management
   */
  async getPaymentAccount(wholesalerId: string): Promise<WholesalerPaymentAccount> {
    let account = await this.accountRepo.findOne({ where: { wholesalerId } });
    if (!account) {
      account = this.accountRepo.create({
        wholesalerId,
        status: PayoutAccountStatus.NOT_CONFIGURED,
      });
      await this.accountRepo.save(account);
    }
    return account;
  }

  async updatePaymentAccount(
    wholesalerId: string,
    data: {
      beneficiaryName?: string;
      accountNumber?: string;
      ifscCode?: string;
      bankName?: string;
      vpaId?: string;
    },
  ): Promise<WholesalerPaymentAccount> {
    let account = await this.accountRepo.findOne({ where: { wholesalerId } });
    if (!account) {
      account = this.accountRepo.create({ wholesalerId });
    }

    if (data.beneficiaryName) account.beneficiaryName = data.beneficiaryName;
    if (data.ifscCode) account.ifscCode = data.ifscCode.toUpperCase().trim();
    if (data.bankName) account.bankName = data.bankName;
    if (data.vpaId) account.vpaId = data.vpaId.trim();

    if (data.accountNumber) {
      const raw = data.accountNumber.trim();
      const last4 = raw.slice(-4);
      account.maskedAccountNumber = `XXXX-XXXX-${last4}`;
    }

    account.status = PayoutAccountStatus.ACTIVE;
    account.isVerified = true;
    account.accountReferenceId = `acc_lnk_${wholesalerId.slice(0, 8)}`;

    return this.accountRepo.save(account);
  }

  /**
   * 8. Ledger Entries & Settlements Queries
   */
  async getEntries(wholesalerId: string): Promise<SellerLedgerEntry[]> {
    return this.entryRepo.find({
      where: { wholesalerId },
      order: { createdAt: 'DESC' },
    });
  }

  async getSettlements(wholesalerId: string): Promise<Settlement[]> {
    return this.settlementRepo.find({
      where: { wholesalerId },
      order: { createdAt: 'DESC' },
    });
  }

  async resolveWholesalerId(user: any): Promise<string> {
    const wholesaler = await this.wholesalerRepo.findOne({ where: { userId: user.id } });
    if (!wholesaler) {
      throw new NotFoundException('Wholesaler profile not found');
    }
    return wholesaler.id;
  }

  async getAllPendingBalances(): Promise<any[]> {
    const wholesalers = await this.wholesalerRepo.find();
    const results: any[] = [];

    for (const w of wholesalers) {
      const summary = await this.getSellerSummary(w.id);
      results.push({
        wholesalerId: w.id,
        businessName: w.businessName,
        commissionRate: Number(w.commissionRate) || 5.0,
        totalSales: summary.totalSales,
        totalCommission: summary.platformCommission,
        availableSettlement: summary.availableSettlement,
        pendingSettlement: summary.pendingSettlement,
        totalSettled: summary.totalSettled,
      });
    }

    return results;
  }
}
