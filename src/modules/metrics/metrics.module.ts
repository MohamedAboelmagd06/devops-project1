import { Module, OnModuleInit } from '@nestjs/common';
import { collectDefaultMetrics } from 'prom-client';
import { MetricsController } from './api/rest/controller/metrics.controller';

@Module({
  controllers: [MetricsController],
})
export class MetricsModule implements OnModuleInit {
  onModuleInit() {
    collectDefaultMetrics();
  }
}
