import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

export enum DeletionStatus {
  PENDING = 'pending',
  PROCESSING = 'processing',
  COMPLETED = 'completed',
  FAILED = 'failed',
}

@Entity('account_deletions')
export class AccountDeletion {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  userId: string; // Stored as reference even after user deletion

  @Column({ nullable: true })
  userEmail?: string; // Email stored for audit trail

  @Column({
    type: 'enum',
    enum: DeletionStatus,
    default: DeletionStatus.PENDING,
  })
  status: DeletionStatus;

  @Column({ type: 'text', nullable: true })
  reason?: string; // Optional reason for deletion

  @Column({ type: 'simple-json', nullable: true })
  metadata?: {
    messagesAnonymized?: number;
    matchesAnonymized?: number;
    reportsAnonymized?: number;
    dataExported?: boolean;
  };

  @Column({ nullable: true })
  requestedAt: Date;

  @Column({ nullable: true })
  completedAt?: Date;

  @Column({ type: 'text', nullable: true })
  errorMessage?: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
