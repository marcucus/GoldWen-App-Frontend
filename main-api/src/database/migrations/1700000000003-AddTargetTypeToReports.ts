import { MigrationInterface, QueryRunner, TableColumn } from 'typeorm';

export class AddTargetTypeToReports1700000000003 implements MigrationInterface {
  name = 'AddTargetTypeToReports1700000000003';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // Add targetType column to reports table
    await queryRunner.addColumn(
      'reports',
      new TableColumn({
        name: 'targetType',
        type: 'enum',
        enum: ['user', 'message'],
        default: "'user'",
        isNullable: false,
      }),
    );

    // Update existing reports to have targetType of 'user' for backward compatibility
    await queryRunner.query(
      `UPDATE reports SET "targetType" = 'user' WHERE "targetType" IS NULL`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.dropColumn('reports', 'targetType');
  }
}
