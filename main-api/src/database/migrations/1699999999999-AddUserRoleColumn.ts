import { MigrationInterface, QueryRunner, TableColumn } from 'typeorm';

export class AddUserRoleColumn1699999999999 implements MigrationInterface {
  name = 'AddUserRoleColumn1699999999999';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // Add role column to users table
    await queryRunner.addColumn(
      'users',
      new TableColumn({
        name: 'role',
        type: 'enum',
        enum: ['user', 'moderator', 'admin'],
        default: "'user'",
        isNullable: true,
      }),
    );

    // Update existing users to have default role of 'user'
    await queryRunner.query(
      `UPDATE users SET role = 'user' WHERE role IS NULL`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.dropColumn('users', 'role');
  }
}
