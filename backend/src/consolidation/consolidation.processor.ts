import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { Injectable } from '@nestjs/common';
import { ConsolidationService } from './consolidation.service';

@Processor('consolidation')
@Injectable()
export class ConsolidationProcessor extends WorkerHost {
  constructor(private readonly consolidationService: ConsolidationService) {
    super();
  }

  async process(job: Job<any, any, string>): Promise<any> {
    if (job.name === 'pool-order') {
      const { zoneId, wholesalerId } = job.data;
      await this.consolidationService.processOrderPooling(zoneId, wholesalerId);
    }
    return {};
  }
}
