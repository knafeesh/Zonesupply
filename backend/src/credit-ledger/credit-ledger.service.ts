import { Injectable, BadRequestException, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource, EntityManager } from 'typeorm';
import { CreditLedger } from './credit-ledger.entity';
import { LedgerTransaction } from './ledger-transaction.entity';
import { LedgerTransactionType } from '../common/enums/ledger-transaction-type.enum';
import { Wholesaler } from '../wholesalers/wholesaler.entity';
import { Retailer } from '../retailers/retailer.entity';
import { UserRole } from '../common/enums/user-role.enum';

@Injectable()
export class CreditLedgerService {
  constructor(
    @InjectRepository(CreditLedger)
    private readonly ledgerRepo: Repository<CreditLedger>,
    @InjectRepository(LedgerTransaction)
    private readonly transactionRepo: Repository<LedgerTransaction>,
    private readonly dataSource: DataSource,
  ) {}

  async getOrCreateLedger(
    retailerId: string,
    wholesalerId: string,
    defaultLimit = 100000.0,
  ): Promise<CreditLedger> {
    let ledger = await this.ledgerRepo.findOne({
      where: { retailerId, wholesalerId },
    });

    if (!ledger) {
      ledger = this.ledgerRepo.create({
        retailerId,
        wholesalerId,
        creditLimit: defaultLimit,
        outstandingBalance: 0,
      });
      ledger = await this.ledgerRepo.save(ledger);
    }

    return ledger;
  }

  async checkCreditLimit(
    retailerId: string,
    wholesalerId: string,
    orderValue: number,
  ): Promise<boolean> {
    const ledger = await this.getOrCreateLedger(retailerId, wholesalerId);
    const potentialBalance = Number(ledger.outstandingBalance) + Number(orderValue);
    return potentialBalance <= Number(ledger.creditLimit);
  }

  async recordDebit(
    retailerId: string,
    wholesalerId: string,
    orderId: string,
    amount: number,
    manager?: EntityManager,
  ): Promise<LedgerTransaction> {
    if (manager) {
      let ledger = await manager.findOne(CreditLedger, {
        where: { retailerId, wholesalerId },
        lock: { mode: 'pessimistic_write' },
      });

      if (!ledger) {
        ledger = manager.create(CreditLedger, {
          retailerId,
          wholesalerId,
          creditLimit: 100000.0,
          outstandingBalance: 0,
        });
        ledger = await manager.save(CreditLedger, ledger);
      }

      const balanceAfter = Number(ledger.outstandingBalance) + Number(amount);
      if (balanceAfter > Number(ledger.creditLimit)) {
        throw new BadRequestException('Credit limit exceeded');
      }

      ledger.outstandingBalance = balanceAfter;
      await manager.save(CreditLedger, ledger);

      const transaction = manager.create(LedgerTransaction, {
        ledgerId: ledger.id,
        orderId,
        type: LedgerTransactionType.DEBIT,
        amount,
        balanceAfter,
      });
      return await manager.save(LedgerTransaction, transaction);
    }

    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      // Locking the ledger for concurrent edits
      let ledger = await queryRunner.manager.findOne(CreditLedger, {
        where: { retailerId, wholesalerId },
        lock: { mode: 'pessimistic_write' },
      });

      if (!ledger) {
        ledger = queryRunner.manager.create(CreditLedger, {
          retailerId,
          wholesalerId,
          creditLimit: 100000.0,
          outstandingBalance: 0,
        });
        ledger = await queryRunner.manager.save(CreditLedger, ledger);
      }

      const balanceAfter = Number(ledger.outstandingBalance) + Number(amount);
      if (balanceAfter > Number(ledger.creditLimit)) {
        throw new BadRequestException('Credit limit exceeded');
      }

      ledger.outstandingBalance = balanceAfter;
      await queryRunner.manager.save(CreditLedger, ledger);

      const transaction = queryRunner.manager.create(LedgerTransaction, {
        ledgerId: ledger.id,
        orderId,
        type: LedgerTransactionType.DEBIT,
        amount,
        balanceAfter,
      });
      const savedTx = await queryRunner.manager.save(LedgerTransaction, transaction);

      await queryRunner.commitTransaction();
      return savedTx;
    } catch (err) {
      await queryRunner.rollbackTransaction();
      throw err;
    } finally {
      await queryRunner.release();
    }
  }

  async recordCreditPayment(
    retailerId: string,
    wholesalerId: string,
    amount: number,
    orderId?: string,
    manager?: EntityManager,
  ): Promise<LedgerTransaction> {
    if (manager) {
      const ledger = await manager.findOne(CreditLedger, {
        where: { retailerId, wholesalerId },
        lock: { mode: 'pessimistic_write' },
      });

      if (!ledger) {
        throw new NotFoundException('Credit ledger relationship not found');
      }

      const balanceAfter = Math.max(0, Number(ledger.outstandingBalance) - Number(amount));
      ledger.outstandingBalance = balanceAfter;
      await manager.save(CreditLedger, ledger);

      const transaction = manager.create(LedgerTransaction, {
        ledgerId: ledger.id,
        orderId,
        type: LedgerTransactionType.PAYMENT,
        amount,
        balanceAfter,
      });
      return await manager.save(LedgerTransaction, transaction);
    }

    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      const ledger = await queryRunner.manager.findOne(CreditLedger, {
        where: { retailerId, wholesalerId },
        lock: { mode: 'pessimistic_write' },
      });

      if (!ledger) {
        throw new NotFoundException('Credit ledger relationship not found');
      }

      const balanceAfter = Math.max(0, Number(ledger.outstandingBalance) - Number(amount));
      ledger.outstandingBalance = balanceAfter;
      await queryRunner.manager.save(CreditLedger, ledger);

      const transaction = queryRunner.manager.create(LedgerTransaction, {
        ledgerId: ledger.id,
        orderId,
        type: LedgerTransactionType.PAYMENT,
        amount,
        balanceAfter,
      });
      const savedTx = await queryRunner.manager.save(LedgerTransaction, transaction);

      await queryRunner.commitTransaction();
      return savedTx;
    } catch (err) {
      await queryRunner.rollbackTransaction();
      throw err;
    } finally {
      await queryRunner.release();
    }
  }

  async recordReversal(
    retailerId: string,
    wholesalerId: string,
    orderId: string,
    amount: number,
    manager?: EntityManager,
  ): Promise<LedgerTransaction> {
    if (manager) {
      const ledger = await manager.findOne(CreditLedger, {
        where: { retailerId, wholesalerId },
        lock: { mode: 'pessimistic_write' },
      });

      if (!ledger) {
        throw new NotFoundException('Credit ledger relationship not found');
      }

      const balanceAfter = Math.max(0, Number(ledger.outstandingBalance) - Number(amount));
      ledger.outstandingBalance = balanceAfter;
      await manager.save(CreditLedger, ledger);

      const transaction = manager.create(LedgerTransaction, {
        ledgerId: ledger.id,
        orderId,
        type: LedgerTransactionType.REVERSAL,
        amount,
        balanceAfter,
      });
      return await manager.save(LedgerTransaction, transaction);
    }

    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      const ledger = await queryRunner.manager.findOne(CreditLedger, {
        where: { retailerId, wholesalerId },
        lock: { mode: 'pessimistic_write' },
      });

      if (!ledger) {
        throw new NotFoundException('Credit ledger relationship not found');
      }

      const balanceAfter = Math.max(0, Number(ledger.outstandingBalance) - Number(amount));
      ledger.outstandingBalance = balanceAfter;
      await queryRunner.manager.save(CreditLedger, ledger);

      const transaction = queryRunner.manager.create(LedgerTransaction, {
        ledgerId: ledger.id,
        orderId,
        type: LedgerTransactionType.REVERSAL,
        amount,
        balanceAfter,
      });
      const savedTx = await queryRunner.manager.save(LedgerTransaction, transaction);

      await queryRunner.commitTransaction();
      return savedTx;
    } catch (err) {
      await queryRunner.rollbackTransaction();
      throw err;
    } finally {
      await queryRunner.release();
    }
  }

  async getRetailerOutstanding(retailerUserId: string): Promise<CreditLedger[]> {
    const retailer = await this.dataSource.getRepository(Retailer).findOne({
      where: { userId: retailerUserId },
    });
    if (!retailer) {
      throw new NotFoundException('Retailer profile not found');
    }
    return this.ledgerRepo.find({
      where: { retailerId: retailer.id },
      relations: { wholesaler: { user: true } },
    });
  }

  async getLedgerTransactions(ledgerId: string): Promise<LedgerTransaction[]> {
    return this.transactionRepo.find({
      where: { ledgerId },
      order: { createdAt: 'DESC' },
    });
  }

  async getLedgerTransactionsSecure(ledgerId: string, user: any): Promise<LedgerTransaction[]> {
    const ledger = await this.ledgerRepo.findOne({ where: { id: ledgerId } });
    if (!ledger) {
      throw new NotFoundException('Ledger not found');
    }

    if (user.role === UserRole.WHOLESALER) {
      const wholesaler = await this.dataSource.getRepository(Wholesaler).findOne({
        where: { userId: user.id },
      });
      if (!wholesaler || ledger.wholesalerId !== wholesaler.id) {
        throw new ForbiddenException('Access denied to this ledger');
      }
    } else if (user.role === UserRole.RETAILER) {
      const retailer = await this.dataSource.getRepository(Retailer).findOne({
        where: { userId: user.id },
      });
      if (!retailer || ledger.retailerId !== retailer.id) {
        throw new ForbiddenException('Access denied to this ledger');
      }
    } else if (user.role !== UserRole.ADMIN) {
      throw new ForbiddenException('Access denied to this ledger');
    }

    return this.getLedgerTransactions(ledgerId);
  }

  async getWholesalerOutstanding(wholesalerUserId: string): Promise<CreditLedger[]> {
    const wholesaler = await this.dataSource.getRepository(Wholesaler).findOne({
      where: { userId: wholesalerUserId },
    });
    if (!wholesaler) {
      throw new NotFoundException('Wholesaler profile not found');
    }
    return this.ledgerRepo.find({
      where: { wholesalerId: wholesaler.id },
      relations: { retailer: { user: true } },
    });
  }

  async getWholesalerTransactions(wholesalerUserId: string): Promise<LedgerTransaction[]> {
    const wholesaler = await this.dataSource.getRepository(Wholesaler).findOne({
      where: { userId: wholesalerUserId },
    });
    if (!wholesaler) {
      throw new NotFoundException('Wholesaler profile not found');
    }
    return this.transactionRepo.find({
      where: { ledger: { wholesalerId: wholesaler.id } },
      relations: { ledger: { retailer: { user: true } } },
      order: { createdAt: 'DESC' },
    });
  }

  async recordManualTransaction(
    wholesalerUserId: string,
    dto: {
      retailerId: string;
      amount: number;
      type: LedgerTransactionType;
      note?: string;
    },
  ): Promise<LedgerTransaction> {
    const wholesaler = await this.dataSource.getRepository(Wholesaler).findOne({
      where: { userId: wholesalerUserId },
    });
    if (!wholesaler) {
      throw new NotFoundException('Wholesaler profile not found');
    }

    const ledger = await this.getOrCreateLedger(dto.retailerId, wholesaler.id);

    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      const lockedLedger = await queryRunner.manager.findOne(CreditLedger, {
        where: { id: ledger.id },
        lock: { mode: 'pessimistic_write' },
      });

      if (!lockedLedger) {
        throw new NotFoundException('Ledger relationship not found');
      }

      let balanceAfter = Number(lockedLedger.outstandingBalance);
      if (dto.type === LedgerTransactionType.DEBIT) {
        balanceAfter += Number(dto.amount);
        if (balanceAfter > Number(lockedLedger.creditLimit)) {
          throw new BadRequestException('Credit limit exceeded');
        }
      } else if (
        dto.type === LedgerTransactionType.PAYMENT ||
        dto.type === LedgerTransactionType.CREDIT ||
        dto.type === LedgerTransactionType.REVERSAL
      ) {
        balanceAfter = Math.max(0, balanceAfter - Number(dto.amount));
      } else {
        throw new BadRequestException('Invalid transaction type');
      }

      lockedLedger.outstandingBalance = balanceAfter;
      await queryRunner.manager.save(CreditLedger, lockedLedger);

      const transaction = queryRunner.manager.create(LedgerTransaction, {
        ledgerId: lockedLedger.id,
        type: dto.type,
        amount: dto.amount,
        balanceAfter,
        note: dto.note || '',
      });
      const savedTx = await queryRunner.manager.save(LedgerTransaction, transaction);

      await queryRunner.commitTransaction();
      return savedTx;
    } catch (err) {
      await queryRunner.rollbackTransaction();
      throw err;
    } finally {
      await queryRunner.release();
    }
  }
}
