import { Controller, Get, Header } from '@nestjs/common';
import { register } from 'prom-client';
import { PublicApi } from '../../../../../libs/decorator/auth.decorator';

@Controller({
  path: 'metrics',
})
export class MetricsController {
  @PublicApi()
  @Get()
  @Header('Content-Type', register.contentType)
  async getMetrics(): Promise<string> {
    return register.metrics();
  }
}
