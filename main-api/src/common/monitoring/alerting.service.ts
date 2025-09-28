import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { CustomLoggerService } from '../logger';

export interface AlertPayload {
  level: 'critical' | 'warning' | 'info';
  title: string;
  message: string;
  metadata?: Record<string, any>;
  timestamp?: Date;
}

@Injectable()
export class AlertingService {
  private alertsConfig: any;

  constructor(
    private configService: ConfigService,
    private logger: CustomLoggerService,
  ) {
    this.alertsConfig = this.configService.get('monitoring.alerts');
  }

  async sendAlert(alert: AlertPayload) {
    const alertData = {
      ...alert,
      timestamp: alert.timestamp || new Date(),
      service: 'GoldWen-API',
      environment: this.configService.get('app.environment'),
    };

    // Log the alert
    this.logger.error(
      `ALERT [${alert.level.toUpperCase()}]: ${alert.title}`,
      undefined,
      'AlertingService',
    );
    this.logger.info('Alert details', {
      alert: alertData,
    });

    // Send to configured channels
    const promises = [];

    if (this.alertsConfig?.webhookUrl) {
      promises.push(this.sendWebhookAlert(alertData));
    }

    if (this.alertsConfig?.slackWebhookUrl) {
      promises.push(this.sendSlackAlert(alertData));
    }

    if (this.alertsConfig?.emailRecipients?.length > 0) {
      promises.push(this.sendEmailAlert(alertData));
    }

    if (promises.length === 0) {
      this.logger.warn('No alerting channels configured', 'AlertingService');
      return;
    }

    try {
      await Promise.allSettled(promises);
    } catch (error) {
      this.logger.error(
        'Failed to send some alerts',
        error.stack,
        'AlertingService',
      );
    }
  }

  private async sendWebhookAlert(alert: any) {
    try {
      const response = await fetch(this.alertsConfig.webhookUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(alert),
      });

      if (!response.ok) {
        throw new Error(`Webhook alert failed: ${response.status}`);
      }
    } catch (error) {
      this.logger.error(
        'Failed to send webhook alert',
        error.stack,
        'AlertingService',
      );
    }
  }

  private async sendSlackAlert(alert: any) {
    try {
      const color =
        alert.level === 'critical'
          ? 'danger'
          : alert.level === 'warning'
            ? 'warning'
            : 'good';

      const slackPayload = {
        attachments: [
          {
            color,
            title: `🚨 ${alert.title}`,
            text: alert.message,
            fields: [
              {
                title: 'Level',
                value: alert.level.toUpperCase(),
                short: true,
              },
              {
                title: 'Service',
                value: alert.service,
                short: true,
              },
              {
                title: 'Environment',
                value: alert.environment,
                short: true,
              },
              {
                title: 'Timestamp',
                value: alert.timestamp.toISOString(),
                short: true,
              },
            ],
            ...(alert.metadata && {
              fields: [
                ...this.getSlackFields(alert),
                {
                  title: 'Metadata',
                  value: `\`\`\`${JSON.stringify(alert.metadata, null, 2)}\`\`\``,
                  short: false,
                },
              ],
            }),
          },
        ],
      };

      const response = await fetch(this.alertsConfig.slackWebhookUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(slackPayload),
      });

      if (!response.ok) {
        throw new Error(`Slack alert failed: ${response.status}`);
      }
    } catch (error) {
      this.logger.error(
        'Failed to send Slack alert',
        error.stack,
        'AlertingService',
      );
    }
  }

  private getSlackFields(alert: any) {
    return [
      {
        title: 'Level',
        value: alert.level.toUpperCase(),
        short: true,
      },
      {
        title: 'Service',
        value: alert.service,
        short: true,
      },
      {
        title: 'Environment',
        value: alert.environment,
        short: true,
      },
      {
        title: 'Timestamp',
        value: alert.timestamp.toISOString(),
        short: true,
      },
    ];
  }

  private async sendEmailAlert(alert: any) {
    // Email alerting would be implemented here
    // For now, just log that it would be sent
    this.logger.info(
      `Email alert would be sent to: ${this.alertsConfig.emailRecipients.join(', ')}`,
      {
        alert,
      },
    );
  }

  // Helper methods for common alert scenarios
  async sendCriticalAlert(
    title: string,
    message: string,
    metadata?: Record<string, any>,
  ) {
    await this.sendAlert({
      level: 'critical',
      title,
      message,
      metadata,
    });
  }

  async sendWarningAlert(
    title: string,
    message: string,
    metadata?: Record<string, any>,
  ) {
    await this.sendAlert({
      level: 'warning',
      title,
      message,
      metadata,
    });
  }

  async sendInfoAlert(
    title: string,
    message: string,
    metadata?: Record<string, any>,
  ) {
    await this.sendAlert({
      level: 'info',
      title,
      message,
      metadata,
    });
  }
}
